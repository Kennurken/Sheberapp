<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid  = (int)$user['id'];

// Ensure table exists
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS push_notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        type VARCHAR(50) NOT NULL DEFAULT 'general',
        title VARCHAR(255) NOT NULL DEFAULT '',
        body TEXT,
        data_json TEXT,
        is_read TINYINT(1) NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_user_read (user_id, is_read),
        KEY idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

try {
    // Unread count
    $st = $pdo->prepare("SELECT COUNT(*) FROM push_notifications WHERE user_id = ? AND is_read = 0");
    $st->execute([$uid]);
    $unread = (int)$st->fetchColumn();

    // Recent notifications (last 50)
    $st2 = $pdo->prepare("
        SELECT id, type, title, body, data_json, is_read, created_at
        FROM push_notifications
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 50
    ");
    $st2->execute([$uid]);
    $rows = $st2->fetchAll(PDO::FETCH_ASSOC) ?: [];

    // Mark as read
    if ($unread > 0) {
        try {
            $pdo->prepare("UPDATE push_notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0")->execute([$uid]);
        } catch (Throwable $e) {}
    }

    json_out(['ok' => true, 'unread' => $unread, 'data' => $rows]);
} catch (Throwable $e) {
    error_log('[notifications_list] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
