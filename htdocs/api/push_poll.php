<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid  = (int)$user['id'];

try {
    $st = $pdo->prepare("
        SELECT id, title, body, url, created_at
        FROM push_notifications
        WHERE user_id = ? AND is_sent = 0
        ORDER BY id ASC
        LIMIT 10
    ");
    $st->execute([$uid]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

    if (count($rows) > 0) {
        $ids = implode(',', array_map(fn($r) => (int)$r['id'], $rows));
        $pdo->exec("UPDATE push_notifications SET is_sent = 1 WHERE id IN ($ids)");
    }

    json_out(['ok' => true, 'data' => $rows]);
} catch (Throwable) {
    json_out(['ok' => true, 'data' => []]);
}