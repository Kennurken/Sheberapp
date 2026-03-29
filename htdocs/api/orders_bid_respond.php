<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}

require_method('POST');
rate_limit('bid_respond', 30, 60);

$user   = require_login($pdo);
$uid    = (int)$user['id'];
$bidId  = get_int('bid_id', 0);
$action = trim(get_str('action', 10)); // 'accept' | 'reject'

if ($bidId <= 0 || !in_array($action, ['accept', 'reject'], true)) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Fetch bid + order info
$st = $pdo->prepare("
    SELECT ob.id, ob.order_id, ob.master_id, ob.amount, ob.status,
           o.client_id, o.status AS order_status
    FROM order_bids ob
    JOIN orders o ON o.id = ob.order_id
    WHERE ob.id = ? LIMIT 1
");
$st->execute([$bidId]);
$bid = $st->fetch();

if (!$bid) {
    json_out(['ok' => false, 'error' => 'not_found'], 404);
}

// Only the client of the order can respond
if ((int)$bid['client_id'] !== $uid) {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

if ((string)($bid['status'] ?? '') !== 'pending') {
    json_out(['ok' => false, 'error' => 'already_responded'], 409);
}

if ((string)($bid['order_status'] ?? '') !== 'new') {
    json_out(['ok' => false, 'error' => 'bad_state'], 409);
}

$masterId = (int)$bid['master_id'];
$orderId  = (int)$bid['order_id'];
$amount   = (int)$bid['amount'];

if ($action === 'accept') {
    // Atomic accept: update order and bid in one transaction
    $pdo->beginTransaction();
    try {
        // Update order: assign master + update price + set in_progress
        $pdo->prepare(
            "UPDATE orders SET master_id = ?, price = ?, status = 'in_progress', accepted_at = NOW(), updated_at = NOW()
             WHERE id = ? AND status = 'new'"
        )->execute([$masterId, $amount, $orderId]);

        // Update this bid to accepted
        $pdo->prepare(
            "UPDATE order_bids SET status = 'accepted' WHERE id = ?"
        )->execute([$bidId]);

        // Reject all other bids for this order
        $pdo->prepare(
            "UPDATE order_bids SET status = 'rejected'
             WHERE order_id = ? AND id != ? AND status = 'pending'"
        )->execute([$orderId, $bidId]);

        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        error_log('[bid_respond] accept error: ' . $e->getMessage());
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    // Push to master: bid accepted
    try {
        if (function_exists('push_notify_user')) {
            push_notify_user($pdo, $masterId, 'Ұсынысыңыз қабылданды ✅', "Тапсырыс {$orderId} сіздікі!", [
                'type'     => 'bid_accepted',
                'order_id' => (string)$orderId,
            ]);
        }
    } catch (Throwable $e) {}

    json_out(['ok' => true, 'data' => ['action' => 'accepted', 'order_id' => $orderId]]);

} else {
    // Reject this bid
    try {
        $pdo->prepare("UPDATE order_bids SET status = 'rejected' WHERE id = ?")->execute([$bidId]);
    } catch (Throwable $e) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    // Push to master: bid rejected
    try {
        if (function_exists('push_notify_user')) {
            push_notify_user($pdo, $masterId, 'Ұсынысыңыз қабылданбады', "Клиент басқа баға таңдады.", [
                'type'     => 'bid_rejected',
                'order_id' => (string)$orderId,
            ]);
        }
    } catch (Throwable $e) {}

    json_out(['ok' => true, 'data' => ['action' => 'rejected']]);
}
