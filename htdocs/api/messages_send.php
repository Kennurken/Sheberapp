<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

// push_send.php is optional — guard so a missing file never breaks messaging
try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}

require_method('POST');
rate_limit('messages_send', 60, 60);   // 60 messages per minute per session
$user = require_login($pdo);
$uid  = (int)$user['id'];

$orderId = get_int('order_id', 0);
$text    = trim(get_str('message', 2000));

if ($orderId <= 0 || $text === '') {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

try {
    // Verify the user is a participant in this order
    $st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
    $st->execute([$orderId]);
    $order = $st->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        json_out(['ok' => false, 'error' => 'not_found'], 404);
    }

    $clientId = (int)($order['client_id'] ?? 0);
    $masterId = (int)($order['master_id'] ?? 0);

    if ($clientId !== $uid && $masterId !== $uid) {
        json_out(['ok' => false, 'error' => 'forbidden'], 403);
    }

    $status = (string)($order['status'] ?? '');
    // Клиент не пишет в чат, пока заказ «ждёт мастера» (нет назначенного шебера)
    if ($uid === $clientId && $status === 'new' && $masterId <= 0) {
        json_out(['ok' => false, 'error' => 'chat_locked'], 409);
    }

    require_once __DIR__ . '/order_chat_gate.php';
    if (order_chat_closed_perfect_review($pdo, $orderId, $status)) {
        json_out(['ok' => false, 'error' => 'chat_closed_perfect'], 409);
    }

    // Determine the recipient for push notification
    $recipientId = ($uid === $clientId) ? $masterId : $clientId;

    // Insert message (try with is_read column first, fallback without)
    $msgId = 0;
    $inserted = false;

    $variants = [
        [
            "INSERT INTO order_messages (order_id, sender_id, message, is_system, is_read, created_at) VALUES (?, ?, ?, 0, 0, NOW())",
            [$orderId, $uid, $text]
        ],
        [
            "INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, ?, ?, 0, NOW())",
            [$orderId, $uid, $text]
        ],
        [
            "INSERT INTO order_messages (order_id, sender_id, message, created_at) VALUES (?, ?, ?, NOW())",
            [$orderId, $uid, $text]
        ],
    ];

    foreach ($variants as [$sql, $params]) {
        try {
            $st = $pdo->prepare($sql);
            $st->execute($params);
            $msgId = (int)$pdo->lastInsertId();
            if ($msgId > 0) {
                $inserted = true;
                break;
            }
        } catch (Throwable $e) {
            error_log('[messages_send] variant failed: ' . $e->getMessage());
        }
    }

    if (!$inserted) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }

    // Update order's updated_at so the order list refreshes
    try {
        $pdo->prepare("UPDATE orders SET updated_at = NOW() WHERE id = ?")->execute([$orderId]);
    } catch (Throwable $e) {}

    // Send push notification to the other participant
    if ($recipientId > 0) {
        $senderName = (string)($user['name'] ?? 'Пользователь');
        $pushTitle = $senderName;
        $pushBody  = mb_strlen($text) > 80 ? mb_substr($text, 0, 77) . '...' : $text;
        try {
            if (function_exists('push_notify_user')) {
                push_notify_user($pdo, $recipientId, $pushTitle, $pushBody, [
                    'type'     => 'new_message',
                    'order_id' => (string)$orderId,
                ]);
            }
        } catch (Throwable $e) {
            error_log('[messages_send] push error: ' . $e->getMessage());
        }
    }

    json_out(['ok' => true, 'data' => ['id' => $msgId]]);

} catch (Throwable $e) {
    error_log('[messages_send] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
