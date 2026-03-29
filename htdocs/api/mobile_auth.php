<?php
declare(strict_types=1);
/**
 * Mobile OTP authentication endpoint.
 * Used by the Flutter app for phone-based login / registration.
 *
 * Actions (POST):
 *   action=send_code   — generate OTP, store in mobile_otp table
 *   action=verify_code — verify OTP, create session, return user + csrf
 *   action=me          — return current logged-in user (GET or POST)
 *
 * SMS delivery is intentionally disabled — codes are stored in DB only.
 * To enable SMS: uncomment the _send_sms() block below and plug in a provider.
 */

require __DIR__ . '/_boot.php';

// CORS handled globally in _boot.php

// Ensure OTP table exists (auto-create on first use)
try {
  $pdo->exec("
    CREATE TABLE IF NOT EXISTS mobile_otp (
      id         INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
      phone      VARCHAR(32) NOT NULL,
      code       CHAR(6)     NOT NULL,
      attempts   TINYINT     NOT NULL DEFAULT 0,
      verified   TINYINT(1)  NOT NULL DEFAULT 0,
      created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at DATETIME    NOT NULL,
      KEY idx_phone_code (phone, code),
      KEY idx_expires    (expires_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  ");
} catch (Throwable $e) {
  error_log('[mobile_auth] otp table create: ' . $e->getMessage());
}

$action = (string)($_GET['action'] ?? $_POST['action'] ?? '');

// ─────────────────────────────────────────────────────────────
// Helper: normalise phone to E.164-ish format (+7XXXXXXXXXX)
// ─────────────────────────────────────────────────────────────
function normalise_phone(string $raw): string {
  $d = preg_replace('/[^0-9]/', '', $raw);
  if (str_starts_with($d, '8') && strlen($d) === 11) $d = '7' . substr($d, 1);
  if (!str_starts_with($d, '+')) $d = '+' . $d;
  // Ensure starts with +7 for Kazakh numbers
  if (preg_match('/^\+7\d{10}$/', $d)) return $d;
  // Accept any +XYZ…
  if (strlen($d) >= 8) return $d;
  return '';
}

// ─────────────────────────────────────────────────────────────
// Helper: send SMS (disabled — plug in your provider here)
// ─────────────────────────────────────────────────────────────
function _send_sms(string $phone, string $code): bool {
  // TODO: integrate SMS provider (SMSC, Twilio, etc.)
  // Example stub — always returns true (for dev / testing).
  // OTP code intentionally NOT logged for security
  // error_log("[mobile_auth] OTP sent to {$phone}");
  return true;
}

// ─────────────────────────────────────────────────────────────
// 1. SEND CODE
// ─────────────────────────────────────────────────────────────
if ($action === 'send_code') {
  $raw   = (string)($_POST['phone'] ?? '');
  $phone = normalise_phone($raw);

  if ($phone === '') {
    json_out(['ok' => false, 'error' => 'invalid_phone'], 400);
  }

  // Rate limit: max 5 OTPs per phone per 10 minutes
  try {
    $st = $pdo->prepare(
      "SELECT COUNT(*) FROM mobile_otp WHERE phone = ? AND created_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)"
    );
    $st->execute([$phone]);
    if ((int)$st->fetchColumn() >= 5) {
      json_out(['ok' => false, 'error' => 'too_many_requests'], 429);
    }
  } catch (Throwable $e) {}

  // Expire old codes for this phone
  try {
    $pdo->prepare("UPDATE mobile_otp SET expires_at = NOW() WHERE phone = ? AND verified = 0")
        ->execute([$phone]);
  } catch (Throwable $e) {}

  // Generate new 6-digit code
  $code    = str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
  $expires = date('Y-m-d H:i:s', time() + 600); // 10 min

  try {
    $pdo->prepare(
      "INSERT INTO mobile_otp (phone, code, expires_at) VALUES (?, ?, ?)"
    )->execute([$phone, $code, $expires]);
  } catch (Throwable $e) {
    error_log('[mobile_auth:send_code] db: ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
  }

  _send_sms($phone, $code);

  json_out(['ok' => true, 'message' => 'code_sent']);
}

// ─────────────────────────────────────────────────────────────
// 2. VERIFY CODE
// ─────────────────────────────────────────────────────────────
if ($action === 'verify_code') {
  $raw   = (string)($_POST['phone'] ?? '');
  $phone = normalise_phone($raw);
  $code  = trim((string)($_POST['code'] ?? ''));

  if ($phone === '' || $code === '') {
    json_out(['ok' => false, 'error' => 'missing_fields'], 400);
  }

  try {
    // Find latest valid OTP for this phone
    $st = $pdo->prepare(
      "SELECT id, attempts FROM mobile_otp
       WHERE phone = ? AND verified = 0 AND expires_at > NOW()
       ORDER BY id DESC LIMIT 1"
    );
    $st->execute([$phone]);
    $otp = $st->fetch();

    if (!$otp) {
      json_out(['ok' => false, 'error' => 'code_expired'], 400);
    }

    $otpId    = (int)$otp['id'];
    $attempts = (int)$otp['attempts'] + 1;

    // Increment attempts counter
    $pdo->prepare("UPDATE mobile_otp SET attempts = ? WHERE id = ?")
        ->execute([$attempts, $otpId]);

    if ($attempts > 5) {
      // Expire this OTP after too many failed attempts
      $pdo->prepare("UPDATE mobile_otp SET expires_at = NOW() WHERE id = ?")
          ->execute([$otpId]);
      json_out(['ok' => false, 'error' => 'too_many_attempts'], 400);
    }

    // Verify code (constant-time compare against DB value)
    $st2 = $pdo->prepare("SELECT code FROM mobile_otp WHERE id = ? LIMIT 1");
    $st2->execute([$otpId]);
    $dbRow = $st2->fetch();
    if (!$dbRow || !hash_equals((string)$dbRow['code'], $code)) {
      json_out(['ok' => false, 'error' => 'wrong_code'], 400);
    }

    // Mark OTP as verified
    $pdo->prepare("UPDATE mobile_otp SET verified = 1, expires_at = NOW() WHERE id = ?")
        ->execute([$otpId]);

    // Find or create user by phone
    $isNew = false;
    $st = $pdo->prepare(
      "SELECT id, name, role, phone, city, avatar_url,
         COALESCE(avatar_color,'#1cb7ff') AS avatar_color,
         COALESCE(profession,'')          AS profession,
         COALESCE(is_blocked,0)           AS is_blocked
       FROM users WHERE phone = ? LIMIT 1"
    );
    $st->execute([$phone]);
    $user = $st->fetch();

    if (!$user) {
      // New user: create with empty name, role=client
      $isNew = true;
      $pdo->prepare(
        "INSERT INTO users (name, phone, role, created_at) VALUES ('', ?, 'client', NOW())"
      )->execute([$phone]);
      $newId = (int)$pdo->lastInsertId();

      $st = $pdo->prepare(
        "SELECT id, name, role, phone, city, avatar_url,
           COALESCE(avatar_color,'#1cb7ff') AS avatar_color,
           COALESCE(profession,'')          AS profession,
           COALESCE(is_blocked,0)           AS is_blocked
         FROM users WHERE id = ? LIMIT 1"
      );
      $st->execute([$newId]);
      $user = $st->fetch();
    }

    if (!$user || (int)($user['is_blocked'] ?? 0) === 1) {
      json_out(['ok' => false, 'error' => 'account_blocked'], 403);
    }

    // Start authenticated session
    session_regenerate_id(true);
    $_SESSION['user_id'] = (int)$user['id'];

    $csrf = csrf_token();

    json_out([
      'ok'   => true,
      'data' => [
        'user' => [
          'id'           => (int)$user['id'],
          'name'         => (string)($user['name'] ?? ''),
          'role'         => (string)($user['role'] ?? 'client'),
          'phone'        => (string)($user['phone'] ?? ''),
          'city'         => (string)($user['city'] ?? ''),
          'avatar_url'   => $user['avatar_url'] ?? null,
          'avatar_color' => (string)($user['avatar_color'] ?? '#1cb7ff'),
          'profession'   => (string)($user['profession'] ?? ''),
          'is_new'       => $isNew,
        ],
        'csrf_token' => $csrf,
      ],
    ]);
  } catch (Throwable $e) {
    error_log('[mobile_auth:verify_code] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
  }
}

// ─────────────────────────────────────────────────────────────
// 3. ME — return current user
// ─────────────────────────────────────────────────────────────
if ($action === 'me') {
  $u = current_user($pdo);
  if (!$u) {
    json_out(['ok' => false, 'error' => 'unauthorized'], 401);
  }

  $csrf = csrf_token();

  // Fetch subscription info for masters
  $subscription    = 'free';
  $subExpiresAt    = null;
  $subIsTrial      = false;
  if ((string)($u['role'] ?? '') === 'master') {
    try {
      $st = $pdo->prepare("
        SELECT ends_at, auto_renew
        FROM master_subscriptions
        WHERE master_id = ? AND status = 'active' AND ends_at > NOW()
        ORDER BY ends_at DESC
        LIMIT 1
      ");
      $st->execute([(int)$u['id']]);
      $sub = $st->fetch(PDO::FETCH_ASSOC);
      if ($sub) {
        $subscription = 'premium';
        $subExpiresAt = (string)$sub['ends_at'];
        $subIsTrial   = (int)($sub['auto_renew'] ?? 1) === 0;
      }
    } catch (Throwable $e) {
      // Non-fatal: subscription fields stay at defaults
    }
  }

  json_out([
    'ok'   => true,
    'data' => [
      'user' => [
        'id'                     => (int)$u['id'],
        'name'                   => (string)($u['name'] ?? ''),
        'role'                   => (string)($u['role'] ?? 'client'),
        'phone'                  => (string)($u['phone'] ?? ''),
        'city'                   => (string)($u['city'] ?? ''),
        'avatar_url'             => $u['avatar_url'] ?? null,
        'avatar_color'           => (string)($u['avatar_color'] ?? '#1cb7ff'),
        'profession'             => (string)($u['profession'] ?? ''),
        'is_new'                 => false,
        'subscription'           => $subscription,
        'subscription_expires_at'=> $subExpiresAt,
        'subscription_is_trial'  => $subIsTrial,
      ],
      'csrf_token' => $csrf,
    ],
  ]);
}

json_out(['ok' => false, 'error' => 'unknown_action'], 400);
