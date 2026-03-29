<?php
declare(strict_types=1);
/**
 * GET — есть ли у текущего пользователя пароль для входа по email.
 */
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid  = (int)$user['id'];

$hasPassword = false;
try {
    $st = $pdo->prepare('SELECT password_hash FROM users WHERE id = ? LIMIT 1');
    $st->execute([$uid]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    $h   = (string)($row['password_hash'] ?? '');
    $hasPassword = $h !== '';
} catch (Throwable $e) {
    try {
        $pdo->exec('ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NULL DEFAULT NULL');
    } catch (Throwable $e2) {
        // ignore
    }
    $hasPassword = false;
}

json_out(['ok' => true, 'has_password' => $hasPassword]);
