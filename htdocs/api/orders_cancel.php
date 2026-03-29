<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}

require_method('POST');
rate_limit('orders_cancel', 10, 60);

$user    = require_login($pdo);
$uid     = (int)$user['id'];
$orderId = get_int('order_id', 0);

if ($orderId <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Fetch order
$st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
$st->execute([$orderId]);
$order = $st->fetch();

if (!$order) {
    json_out(['ok' => false, 'error' => 'not_found'], 404);
}

$clientId = (int)$order['client_id'];
$masterId = (int)($order['master_id'] ?? 0);
$status   = (string)($order['status'] ?? '');

// Only client or assigned master can cancel
if ($clientId !== $uid && $masterId !== $uid) {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

// Can only cancel 'new' or 'in_progress' orders
if (!in_array($status, ['new', 'in_progress'], true)) {
    json_out(['ok' => false, 'error' => 'bad_state'], 409);
}

try {
    $pdo->prepare(
        "UPDATE orders SET status = 'cancelled', updated_at = NOW() WHERE id = ? AND status IN ('new','in_progress')"
    )->execute([$orderId]);

    // Add system message about cancellation
    $cancellerName = (string)($user['name'] ?? 'Пользователь');
    $sysMsg = ($uid === $clientId)
        ? "Клиент $cancellerName тапсырысты болдырмады"
        : "Шебер $cancellerName тапсырысты болдырмады";

    try {
        $pdo->prepare(
            "INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, ?, ?, 1, NOW())"
        )->execute([$orderId, $uid, $sysMsg]);
    } catch (Throwable $e) {}

    // Reject all pending bids for this order
    try {
        $pdo->prepare(
            "UPDATE order_bids SET status = 'rejected' WHERE order_id = ? AND status = 'pending'"
        )->execute([$orderId]);
    } catch (Throwable $e) {}

    // Push notification to the other party
    $otherId = ($uid === $clientId) ? $masterId : $clientId;
    if ($otherId > 0) {
        try {
            if (function_exists('push_notify_user')) {
                push_notify_user($pdo, $otherId, 'Тапсырыс болдырылмады', $sysMsg, [
                    'type'     => 'order_cancelled',
                    'order_id' => (string)$orderId,
                ]);
            }
        } catch (Throwable $e) {}
    }

    json_out(['ok' => true]);
} catch (Throwable $e) {
    error_log('[orders_cancel] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
