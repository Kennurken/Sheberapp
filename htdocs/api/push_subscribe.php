<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

$user = require_login($pdo);
$uid  = (int)$user['id'];
$method = strtoupper((string)($_SERVER['REQUEST_METHOD'] ?? 'GET'));

// Ensure push_subscriptions table
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS push_subscriptions (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            user_id    INT NOT NULL,
            endpoint   TEXT NOT NULL,
            p256dh     VARCHAR(512) NOT NULL DEFAULT '',
            auth       VARCHAR(256) NOT NULL DEFAULT '',
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uq_endpoint (user_id, endpoint(200))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
} catch (Throwable) {}

if ($method === 'POST') {
    $tok = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ($_POST['csrf_token'] ?? ''));
    if (!csrf_check($tok)) json_out(['ok' => false, 'error' => 'csrf'], 419);

    $raw = file_get_contents('php://input');
    $sub = json_decode($raw ?: '{}', true);
    $endpoint = trim((string)($sub['endpoint'] ?? ''));
    $p256dh   = trim((string)($sub['keys']['p256dh'] ?? ''));
    $auth     = trim((string)($sub['keys']['auth'] ?? ''));

    if (!$endpoint) json_out(['ok' => false, 'error' => 'no_endpoint'], 400);

    try {
        $st = $pdo->prepare("
            INSERT INTO push_subscriptions (user_id, endpoint, p256dh, auth)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE p256dh = VALUES(p256dh), auth = VALUES(auth)
        ");
        $st->execute([$uid, $endpoint, $p256dh, $auth]);
        json_out(['ok' => true]);
    } catch (Throwable $e) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }
}

if ($method === 'DELETE') {
    $tok = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    if (!csrf_check($tok)) json_out(['ok' => false, 'error' => 'csrf'], 419);
    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    $endpoint = trim((string)($body['endpoint'] ?? ''));
    if ($endpoint) {
        $pdo->prepare("DELETE FROM push_subscriptions WHERE user_id = ? AND endpoint = ?")->execute([$uid, $endpoint]);
    }
    json_out(['ok' => true]);
}

if ($method === 'GET') {
    // Check if user has active subscription
    $st = $pdo->prepare("SELECT COUNT(*) FROM push_subscriptions WHERE user_id = ?");
    $st->execute([$uid]);
    json_out(['ok' => true, 'data' => ['subscribed' => (int)$st->fetchColumn() > 0]]);
}

json_out(['ok' => false, 'error' => 'method_not_allowed'], 405);