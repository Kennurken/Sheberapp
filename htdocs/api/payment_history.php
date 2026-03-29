<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid  = (int)$user['id'];

// Ensure balance_transactions table exists
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS balance_transactions (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            user_id     INT NOT NULL,
            amount      DECIMAL(12,2) NOT NULL,
            description VARCHAR(255) NOT NULL DEFAULT '',
            type        VARCHAR(32) NOT NULL DEFAULT 'topup',
            ref_id      INT NULL,
            created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
} catch (Throwable) {}

try {
    $limit = min((int)($_GET['limit'] ?? 30), 100);
    $st = $pdo->prepare("
        SELECT id, amount, description, type, created_at
        FROM balance_transactions
        WHERE user_id = ?
        ORDER BY id DESC
        LIMIT ?
    ");
    $st->execute([$uid, $limit]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

    // Also include subscription purchases as negative transactions
    try {
        $st2 = $pdo->prepare("
            SELECT ms.id, sp.price AS amount, CONCAT('Подписка: ', sp.title) AS description,
                   'subscription' AS type, ms.starts_at AS created_at
            FROM master_subscriptions ms
            JOIN subscription_plans sp ON sp.id = ms.plan_id
            WHERE ms.master_id = ?
            ORDER BY ms.starts_at DESC
            LIMIT 20
        ");
        $st2->execute([$uid]);
        $subs = $st2->fetchAll(PDO::FETCH_ASSOC) ?: [];
        foreach ($subs as &$s) $s['amount'] = -abs((float)$s['amount']);
        $rows = array_merge($rows, $subs);
        usort($rows, fn($a, $b) => strcmp((string)$b['created_at'], (string)$a['created_at']));
        $rows = array_slice($rows, 0, $limit);
    } catch (Throwable) {}

    json_out(['ok' => true, 'data' => $rows]);
} catch (Throwable $e) {
    json_out(['ok' => true, 'data' => []]);
}