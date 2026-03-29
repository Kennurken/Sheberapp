<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

// Ensure column exists
try {
    $pdo->exec("ALTER TABLE users ADD COLUMN is_online TINYINT(1) NOT NULL DEFAULT 0");
} catch (Throwable) { /* already exists */ }

try {
    $st = $pdo->prepare('SELECT COALESCE(is_online, 0) AS is_online FROM users WHERE id = ? LIMIT 1');
    $st->execute([$uid]);
    $row  = $st->fetch(PDO::FETCH_ASSOC);
    $cur  = (int)($row['is_online'] ?? 0);
    $next = $cur === 1 ? 0 : 1;

    $pdo->prepare('UPDATE users SET is_online = ? WHERE id = ?')->execute([$next, $uid]);

    json_out(['ok' => true, 'data' => ['is_online' => $next]]);
} catch (Throwable $e) {
    error_log('[STATUS TOGGLE] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}