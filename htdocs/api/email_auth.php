<?php
declare(strict_types=1);
/**
 * Email/password authentication endpoint.
 * Used by the Flutter app for email-based login / registration.
 *
 * Actions (POST):
 *   action=register — create new account with name, email, password
 *   action=login    — authenticate with email + password
 */

require __DIR__ . '/_boot.php';

// CORS handled globally in _boot.php

$action = (string)($_GET['action'] ?? $_POST['action'] ?? '');

// ─────────────────────────────────────────────────────────────
// Helper: return user row with subscription info
// ─────────────────────────────────────────────────────────────
function fetch_user_row(PDO $pdo, int $userId): ?array
{
    $st = $pdo->prepare(
        "SELECT id, name, role, phone, email, city, avatar_url,
           COALESCE(avatar_color,'#1cb7ff') AS avatar_color,
           COALESCE(profession,'')          AS profession,
           COALESCE(is_blocked,0)           AS is_blocked
         FROM users WHERE id = ? LIMIT 1"
    );
    $st->execute([$userId]);
    return $st->fetch(PDO::FETCH_ASSOC) ?: null;
}

// ─────────────────────────────────────────────────────────────
// Helper: build public user array
// ─────────────────────────────────────────────────────────────
function build_user_response(PDO $pdo, array $user): array
{
    $uid = (int)$user['id'];

    // Subscription info
    $subscription  = 'free';
    $subExpiresAt  = null;
    $subIsTrial    = false;
    if ((string)($user['role'] ?? '') === 'master') {
        try {
            $st = $pdo->prepare(
                "SELECT ends_at, auto_renew FROM master_subscriptions
                  WHERE master_id = ? AND status = 'active' AND ends_at > NOW()
                  ORDER BY ends_at DESC LIMIT 1"
            );
            $st->execute([$uid]);
            $sub = $st->fetch(PDO::FETCH_ASSOC);
            if ($sub) {
                $subscription = 'premium';
                $subExpiresAt = (string)$sub['ends_at'];
                $subIsTrial   = (int)($sub['auto_renew'] ?? 1) === 0;
            }
        } catch (Throwable $e) {}
    }

    return [
        'id'                    => $uid,
        'name'                  => (string)($user['name'] ?? ''),
        'role'                  => (string)($user['role'] ?? 'client'),
        'phone'                 => (string)($user['phone'] ?? ''),
        'email'                 => (string)($user['email'] ?? ''),
        'city'                  => (string)($user['city'] ?? ''),
        'avatar_url'            => $user['avatar_url'] ?? null,
        'avatar_color'          => (string)($user['avatar_color'] ?? '#1cb7ff'),
        'profession'            => (string)($user['profession'] ?? ''),
        'subscription'          => $subscription,
        'subscription_expires_at' => $subExpiresAt,
        'subscription_is_trial' => $subIsTrial,
    ];
}

// ─────────────────────────────────────────────────────────────
// 1. REGISTER
// ─────────────────────────────────────────────────────────────
if ($action === 'register') {
    rate_limit('email_register', 5, 3600); // 5 registrations per hour per session
    $name     = trim((string)($_POST['name']     ?? ''));
    $email    = strtolower(trim((string)($_POST['email']    ?? '')));
    $password = (string)($_POST['password'] ?? '');
    $role     = in_array((string)($_POST['role'] ?? ''), ['client', 'master'], true)
                  ? (string)$_POST['role'] : 'client';

    if ($name === '' || $email === '' || $password === '') {
        json_out(['ok' => false, 'error' => 'missing_fields'], 400);
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_out(['ok' => false, 'error' => 'invalid_email'], 400);
    }

    if (strlen($password) < 6) {
        json_out(['ok' => false, 'error' => 'password_too_short'], 400);
    }

    // Check if email already taken
    try {
        $st = $pdo->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
        $st->execute([$email]);
        if ($st->fetch()) {
            json_out(['ok' => false, 'error' => 'email_taken'], 409);
        }
    } catch (Throwable $e) {
        error_log('[email_auth:register] check email: ' . $e->getMessage());
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    // Create user
    $hash = password_hash($password, PASSWORD_BCRYPT);
    try {
        $pdo->prepare(
            "INSERT INTO users (name, email, password_hash, role, created_at)
             VALUES (?, ?, ?, ?, NOW())"
        )->execute([$name, $email, $hash, $role]);
        $newId = (int)$pdo->lastInsertId();
    } catch (Throwable $e) {
        error_log('[email_auth:register] insert: ' . $e->getMessage());
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    $user = fetch_user_row($pdo, $newId);
    if (!$user) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    session_regenerate_id(true);
    $_SESSION['user_id'] = $newId;
    $csrf = csrf_token();

    json_out([
        'ok'         => true,
        'user'       => build_user_response($pdo, $user),
        'csrf_token' => $csrf,
        'is_new'     => true,
    ]);
}

// ─────────────────────────────────────────────────────────────
// 2. LOGIN
// ─────────────────────────────────────────────────────────────
if ($action === 'login') {
    rate_limit('email_login', 10, 300); // 10 login attempts per 5 min per session
    $email    = strtolower(trim((string)($_POST['email']    ?? '')));
    $password = (string)($_POST['password'] ?? '');

    if ($email === '' || $password === '') {
        json_out(['ok' => false, 'error' => 'missing_fields'], 400);
    }

    try {
        $st = $pdo->prepare(
            "SELECT id, password_hash, is_blocked FROM users WHERE email = ? LIMIT 1"
        );
        $st->execute([$email]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
    } catch (Throwable $e) {
        error_log('[email_auth:login] ' . $e->getMessage());
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    if (!$row || !password_verify($password, (string)($row['password_hash'] ?? ''))) {
        json_out(['ok' => false, 'error' => 'wrong_credentials'], 401);
    }

    if ((int)($row['is_blocked'] ?? 0) === 1) {
        json_out(['ok' => false, 'error' => 'account_blocked'], 403);
    }

    $user = fetch_user_row($pdo, (int)$row['id']);
    if (!$user) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    session_regenerate_id(true);
    $_SESSION['user_id'] = (int)$row['id'];
    $csrf = csrf_token();

    json_out([
        'ok'         => true,
        'user'       => build_user_response($pdo, $user),
        'csrf_token' => $csrf,
        'is_new'     => false,
    ]);
}

json_out(['ok' => false, 'error' => 'unknown_action'], 400);
