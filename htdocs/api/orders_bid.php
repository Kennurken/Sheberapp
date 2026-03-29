<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}

require_method('POST');
rate_limit('orders_bid', 30, 60);

$user    = require_login($pdo);
$uid     = (int)$user['id'];
$role    = (string)($user['role'] ?? '');
$orderId = get_int('order_id', 0);
$amount  = get_int('amount', 0);

if ($role !== 'master') {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}
if ($orderId <= 0 || $amount <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Ensure order_bids table exists
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS order_bids (
        id         INT AUTO_INCREMENT PRIMARY KEY,
        order_id   INT NOT NULL,
        master_id  INT NOT NULL,
        amount     INT NOT NULL,
        status     ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_order_master (order_id, master_id),
        KEY idx_order (order_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

// Validate order exists, is new, and this master is not the client
$st = $pdo->prepare("SELECT id, client_id, status, price FROM orders WHERE id = ? LIMIT 1");
$st->execute([$orderId]);
$order = $st->fetch();
if (!$order) {
    json_out(['ok' => false, 'error' => 'not_found'], 404);
}
if ((string)($order['status'] ?? '') !== 'new') {
    json_out(['ok' => false, 'error' => 'bad_state'], 409);
}
if ((int)$order['client_id'] === $uid) {
    json_out(['ok' => false, 'error' => 'own_order'], 403);
}

// Minimum bid: 50% of order price (ceil — same as Flutter master_bid_screen)
$orderPrice = (int)$order['price'];
$minAmount = (int) max(1, (int) ceil($orderPrice * 0.5));
if ($amount < $minAmount) {
    json_out(['ok' => false, 'error' => 'amount_too_low', 'min' => $minAmount], 422);
}
// Maximum bid: 10x order price or 5M₸
$maxAmount = max($orderPrice * 10, 50000);
if ($amount > 5000000 || ($orderPrice > 0 && $amount > $maxAmount)) {
    json_out(['ok' => false, 'error' => 'amount_too_high', 'max' => min($maxAmount, 5000000)], 422);
}

// Insert or update bid (one bid per master per order)
try {
    $pdo->prepare(
        "INSERT INTO order_bids (order_id, master_id, amount, status)
         VALUES (?, ?, ?, 'pending')
         ON DUPLICATE KEY UPDATE amount = VALUES(amount), status = 'pending'"
    )->execute([$orderId, $uid, $amount]);
} catch (Throwable $e) {
    error_log('[orders_bid] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

// Push notification to client
$clientId = (int)$order['client_id'];
try {
    if ($clientId > 0 && function_exists('push_notify_user')) {
        $masterName = (string)($user['name'] ?? 'Шебер');
        push_notify_user($pdo, $clientId, $masterName, "Шебер {$amount}₸ бағасын ұсынды", [
            'type'     => 'bid_received',
            'order_id' => (string)$orderId,
        ]);
    }
} catch (Throwable $e) {}

json_out(['ok' => true]);
