<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

$user = require_login($pdo);
$uid  = (int)$user['id'];

// Ensure table exists
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS support_messages (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        user_id     INT NOT NULL,
        direction   ENUM('in','out') NOT NULL,
        message     TEXT NOT NULL,
        created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_user_id (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

$since = get_int('since', 0); // last message id client has

try {
    $st = $pdo->prepare(
        "SELECT id, direction, message, created_at
         FROM support_messages
         WHERE user_id = ? AND id > ?
         ORDER BY id ASC
         LIMIT 50"
    );
    $st->execute([$uid, $since]);
    $rows = $st->fetchAll();
} catch (Throwable $e) {
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

$messages = array_map(fn($r) => [
    'id'         => (int)$r['id'],
    'direction'  => $r['direction'],
    'message'    => $r['message'],
    'created_at' => $r['created_at'],
], $rows);

json_out(['ok' => true, 'data' => $messages]);
