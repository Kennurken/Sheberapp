<?php
declare(strict_types=1);

require __DIR__ . '/../init.php';

header('Content-Type: application/json; charset=utf-8');

// ── Global CORS ──────────────────────────────────────────────────────────────
$_origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$_allowedOrigins = [
    'http://kmaruk4u.beget.tech',
    'https://kmaruk4u.beget.tech',
    'http://sheberkz.duckdns.org',
    'https://sheberkz.duckdns.org',
    'https://sheber.kz',
    'http://sheber.kz',
    'http://localhost',
    'http://localhost:8000',
    'http://localhost:8080',
    'http://127.0.0.1',
    'http://127.0.0.1:8000',
    'http://127.0.0.1:8080',
];
if (in_array($_origin, $_allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: $_origin");
    header('Access-Control-Allow-Credentials: true');
    header('Vary: Origin');
}
header('Access-Control-Allow-Headers: Content-Type, X-CSRF-TOKEN');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}
unset($_origin, $_allowedOrigins);

header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// ── JSON body → $_POST merge ────────────────────────────────────────────────
// Dio (Flutter) sends data as application/json by default.
// PHP only populates $_POST for form-encoded/multipart — parse JSON manually.
$_contentType = strtolower((string)($_SERVER['CONTENT_TYPE'] ?? ''));
if (str_contains($_contentType, 'application/json')) {
  $_jsonBody = (string)file_get_contents('php://input');
  if ($_jsonBody !== '') {
    $_parsed = json_decode($_jsonBody, true);
    if (is_array($_parsed)) {
      $_POST = array_merge($_POST, $_parsed);
    }
  }
}
unset($_contentType, $_jsonBody, $_parsed);
header('X-Content-Type-Options: nosniff');

// Global API rate limit: 300 requests / 5 minutes per session+IP
rate_limit('api', 300, 300);

// Чтобы предупреждения/notice не ломали JSON-ответ.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);

// Единый обработчик ошибок/исключений для API.
set_error_handler(function (int $severity, string $message, string $file, int $line): bool {
  // Превращаем ошибки PHP в исключения (так проще ловить и отдавать server_error).
  if (!(error_reporting() & $severity)) return true;
  throw new ErrorException($message, 0, $severity, $file, $line);
});

set_exception_handler(function (Throwable $e): void {
  // Логируем деталь, пользователю отдаём общий код.
  error_log('[API] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
  http_response_code(500);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode(['ok' => false, 'error' => 'server_error'], JSON_UNESCAPED_UNICODE);
  exit;
});

function json_out(array $payload, int $code = 200): never {
  http_response_code($code);
  echo json_encode($payload, JSON_UNESCAPED_UNICODE);
  exit;
}

function require_method(string $method): void {
  $m = strtoupper((string)($_SERVER['REQUEST_METHOD'] ?? 'GET'));
  if ($m !== strtoupper($method)) {
    json_out(['ok' => false, 'error' => 'method_not_allowed'], 405);
  }

  // CSRF for state-changing requests
  if ($m !== 'GET') {
    $tok = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ($_POST['csrf_token'] ?? ''));
    if (!csrf_check($tok)) {
      json_out(['ok' => false, 'error' => 'csrf'], 419);
    }
  }
}

function require_login(PDO $pdo): array {
  $u = current_user($pdo);
  if (!$u) json_out(['ok' => false, 'error' => 'unauthorized'], 401);

  // Touch last_seen not more often than once per 30 seconds
  try {
    $now = time();
    $last = (int)($_SESSION['_last_seen_touch'] ?? 0);
    if ($now - $last >= 30) {
      $_SESSION['_last_seen_touch'] = $now;
      $st = $pdo->prepare('UPDATE users SET last_seen = NOW() WHERE id = ?');
      $st->execute([(int)$u['id']]);
    }
  } catch (Throwable $e) {}

  // ОПТИМИЗАЦИЯ: Закрываем файл сессии, чтобы разрешить параллельные API-запросы от этого же юзера.
  // Это критично для WebRTC, пушей и чата.
  session_write_close();

  return $u;
}

function require_role(array $user, string $role): void {
  if (($user['role'] ?? '') !== $role) {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
  }
}

function str_clip(string $s, int $max): string {
  $s = trim($s);
  if (mb_strlen($s) > $max) $s = mb_substr($s, 0, $max);
  return $s;
}

function get_int(string $key, int $default = 0): int {
  $v = $_POST[$key] ?? $_GET[$key] ?? $default;
  if (is_int($v)) return $v;
  if (ctype_digit((string)$v)) return (int)$v;
  return $default;
}

function get_str(string $key, int $maxLen, string $default = ''): string {
  $v = (string)($_POST[$key] ?? $_GET[$key] ?? $default);
  $v = trim($v);
  if ($maxLen > 0 && mb_strlen($v) > $maxLen) $v = mb_substr($v, 0, $maxLen);
  return $v;
}

/**
 * Very basic rate limit (per session+IP) with fixed window.
 * For free hosting without Redis.
 */
function rate_limit(string $bucket, int $max, int $windowSec): void {
  $ip = (string)($_SERVER['REMOTE_ADDR'] ?? '');
  $key = 'rl:' . $bucket . ':' . md5($ip . '|' . session_id());
  $now = time();
  $win = (int)floor($now / max(1, $windowSec));

  if (!isset($_SESSION['_rl'])) $_SESSION['_rl'] = [];
  $store = &$_SESSION['_rl'];
  $k = $key . ':' . $win;
  $cnt = (int)($store[$k] ?? 0);
  $cnt++;
  $store[$k] = $cnt;

  // cleanup (best-effort)
  if (count($store) > 200) {
    foreach ($store as $kk => $vv) {
      if (!str_contains($kk, ':' . $win)) unset($store[$kk]);
    }
  }

  if ($cnt > $max) {
    json_out(['ok' => false, 'error' => 'rate_limited'], 429);
  }
}

/**
 * Lazy subscription sync (Spotify-like):
 * - if active ended -> either renew (auto_renew=1 and not canceled) or expire
 * - supports scheduled plan change via next_plan_id
 *
 * Called from endpoints that need up-to-date subscription state.
 */
function subscription_sync(PDO $pdo, int $masterId): void {
  $ownTx = false;
  if (!$pdo->inTransaction()) {
    $pdo->beginTransaction();
    $ownTx = true;
  }

  try {
    // lock latest subscription row (if any)
    $st = $pdo->prepare("\n      SELECT id, plan_id, starts_at, ends_at, status,\n             COALESCE(auto_renew, 1) AS auto_renew,\n             COALESCE(cancel_at_period_end, 0) AS cancel_at_period_end,\n             next_plan_id\n      FROM master_subscriptions\n      WHERE master_id = ?\n      ORDER BY ends_at DESC\n      LIMIT 1\n      FOR UPDATE\n    ");
    $st->execute([$masterId]);
    $sub = $st->fetch(PDO::FETCH_ASSOC);

    if (!$sub) {
      $st = $pdo->prepare("UPDATE users SET is_subscribed = 0 WHERE id = ?");
      $st->execute([$masterId]);
      if ($ownTx) $pdo->commit();
      return;
    }

    $now = new DateTimeImmutable('now');
    $endsAt = !empty($sub['ends_at']) ? new DateTimeImmutable((string)$sub['ends_at']) : null;
    $isActive = ((string)($sub['status'] ?? '') === 'active') && $endsAt && ($endsAt > $now);

    if ($isActive) {
      $st = $pdo->prepare("UPDATE users SET is_subscribed = 1 WHERE id = ?");
      $st->execute([$masterId]);
      if ($ownTx) $pdo->commit();
      return;
    }

    $ended = $endsAt ? ($endsAt <= $now) : true;
    if (!$ended) {
      $st = $pdo->prepare("UPDATE users SET is_subscribed = 0 WHERE id = ?");
      $st->execute([$masterId]);
      if ($ownTx) $pdo->commit();
      return;
    }

    $autoRenew = (int)($sub['auto_renew'] ?? 1);
    $cancelAtEnd = (int)($sub['cancel_at_period_end'] ?? 0);

    if ($autoRenew !== 1 || $cancelAtEnd === 1) {
      $st = $pdo->prepare("UPDATE master_subscriptions SET status='expired' WHERE id = ?");
      $st->execute([(int)$sub['id']]);
      $st = $pdo->prepare("UPDATE users SET is_subscribed = 0 WHERE id = ?");
      $st->execute([$masterId]);
      if ($ownTx) $pdo->commit();
      return;
    }

    $renewPlanId = (int)($sub['next_plan_id'] ?? 0);
    if ($renewPlanId <= 0) $renewPlanId = (int)$sub['plan_id'];

    $st = $pdo->prepare("SELECT id, price, period_days FROM subscription_plans WHERE id = ? LIMIT 1");
    $st->execute([$renewPlanId]);
    $plan = $st->fetch(PDO::FETCH_ASSOC);
    if (!$plan) {
      $st = $pdo->prepare("UPDATE master_subscriptions SET status='expired' WHERE id = ?");
      $st->execute([(int)$sub['id']]);
      $st = $pdo->prepare("UPDATE users SET is_subscribed = 0 WHERE id = ?");
      $st->execute([$masterId]);
      if ($ownTx) $pdo->commit();
      return;
    }

    $price = (float)$plan['price'];
    $periodDays = (int)$plan['period_days'];

    $st = $pdo->prepare("SELECT balance FROM users WHERE id = ? FOR UPDATE");
    $st->execute([$masterId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    $bal = $row ? (float)$row['balance'] : 0.0;

    if ($bal + 0.00001 < $price) {
      $st = $pdo->prepare("UPDATE master_subscriptions SET status='expired' WHERE id = ?");
      $st->execute([(int)$sub['id']]);
      $st = $pdo->prepare("UPDATE users SET is_subscribed = 0 WHERE id = ?");
      $st->execute([$masterId]);
      if ($ownTx) $pdo->commit();
      return;
    }

    $st = $pdo->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
    $st->execute([$price, $masterId]);

    $st = $pdo->prepare("UPDATE master_subscriptions SET status='expired' WHERE id = ?");
    $st->execute([(int)$sub['id']]);

    $startsAt = $now;
    $newEnds = $now->modify('+' . $periodDays . ' days');

    $st = $pdo->prepare("\n      INSERT INTO master_subscriptions\n        (master_id, plan_id, starts_at, ends_at, status, auto_renew, cancel_at_period_end, canceled_at, next_plan_id, next_renew_at)\n      VALUES\n        (?, ?, ?, ?, 'active', 1, 0, NULL, NULL, NULL)\n    ");
    $st->execute([$masterId, $renewPlanId, $startsAt->format('Y-m-d H:i:s'), $newEnds->format('Y-m-d H:i:s')]);

    $st = $pdo->prepare("UPDATE users SET is_subscribed = 1 WHERE id = ?");
    $st->execute([$masterId]);

    if ($ownTx) $pdo->commit();
  } catch (Throwable $e) {
    if ($ownTx && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('[SUB SYNC] ' . $e->getMessage());

    // ОПТИМИЗАЦИЯ: Если транзакция внешняя, обязательно пробрасываем ошибку наверх!
    // Иначе FOR UPDATE зависнет и положит базу.
    if (!$ownTx) {
        throw $e; 
    }
  }
}