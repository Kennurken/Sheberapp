<?php
declare(strict_types=1);
/**
 * POST — смена или первичная установка пароля (сессия уже есть).
 * Поля: current_password (если пароль уже задан), new_password, csrf_token
 */
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('password_change', 10, 3600);

$user = require_login($pdo);
$uid  = (int)$user['id'];

$current = (string)($_POST['current_password'] ?? '');
$new     = (string)($_POST['new_password'] ?? '');

if (strlen($new) < 6) {
    json_out(['ok' => false, 'error' => 'password_too_short'], 400);
}

try {
    $pdo->query('SELECT password_hash FROM users LIMIT 1');
} catch (Throwable $e) {
    try {
        $pdo->exec('ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NULL DEFAULT NULL');
    } catch (Throwable $e2) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }
}

$hash = '';
try {
    $st = $pdo->prepare('SELECT password_hash FROM users WHERE id = ? LIMIT 1');
    $st->execute([$uid]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    $hash = (string)($row['password_hash'] ?? '');
} catch (Throwable $e) {
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

if ($hash !== '') {
    if ($current === '' || !password_verify($current, $hash)) {
        json_out(['ok' => false, 'error' => 'wrong_current'], 403);
    }
}

$newHash = password_hash($new, PASSWORD_BCRYPT);
try {
    $st = $pdo->prepare('UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?');
    $st->execute([$newHash, $uid]);
} catch (Throwable $e) {
    error_log('[password_change] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

json_out(['ok' => true]);
