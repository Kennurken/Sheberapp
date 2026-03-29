<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}

require_method('POST');
rate_limit('order_finish', 10, 60);
$user = require_login($pdo);
$uid = (int)$user['id'];
$role = (string)($user['role'] ?? '');

$orderId = get_int('order_id', 0);
if ($orderId <= 0) json_out(['ok' => false, 'error' => 'validation'], 422);
if ($role !== 'client' && $role !== 'master') json_out(['ok' => false, 'error' => 'forbidden'], 403);

// Ensure order_done table exists with UNIQUE constraint
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS order_done (
        id         INT AUTO_INCREMENT PRIMARY KEY,
        order_id   INT NOT NULL,
        done_by    ENUM('client','master') NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_order_done (order_id, done_by),
        KEY idx_order (order_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

// db_mobile_init.sql создаёт order_done с обязательным user_id — INSERT без него даёт 500
$orderDoneHasUserId = false;
try {
    $dc = $pdo->query('SHOW COLUMNS FROM order_done')->fetchAll(PDO::FETCH_ASSOC) ?: [];
    foreach ($dc as $row) {
        if (strtolower((string)($row['Field'] ?? '')) === 'user_id') {
            $orderDoneHasUserId = true;
            break;
        }
    }
} catch (Throwable $e) {
    $orderDoneHasUserId = false;
}

try {
    $st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
    $st->execute([$orderId]);
    $o = $st->fetch();
    if (!$o) json_out(['ok' => false, 'error' => 'not_found'], 404);

    $clientId = (int)$o['client_id'];
    $masterId = (int)($o['master_id'] ?? 0);
    if ($role === 'client' && $clientId !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);
    if ($role === 'master' && $masterId !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);

    $status = (string)($o['status'] ?? 'new');

    // Already completed — return immediately
    if ($status === 'completed') {
        json_out(['ok' => true, 'data' => ['both_done' => true, 'already_done' => true]]);
    }
    if ($status === 'cancelled') json_out(['ok' => false, 'error' => 'bad_state'], 409);
    if ($status !== 'in_progress') json_out(['ok' => false, 'error' => 'bad_state'], 409);

    $doneBy = ($role === 'client') ? 'client' : 'master';

    // Check if THIS side already confirmed — prevent duplicate
    $stCheck = $pdo->prepare("SELECT id FROM order_done WHERE order_id = ? AND done_by = ? LIMIT 1");
    $stCheck->execute([$orderId, $doneBy]);
    if ($stCheck->fetch()) {
        // Already confirmed by this side — check if both done
        $stBoth = $pdo->prepare("SELECT COUNT(DISTINCT done_by) AS cnt FROM order_done WHERE order_id = ?");
        $stBoth->execute([$orderId]);
        $cnt = (int)$stBoth->fetchColumn();
        json_out(['ok' => true, 'data' => ['both_done' => $cnt >= 2, 'already_done' => true]]);
    }

    // Insert confirmation (совместимость со схемой из db_mobile_init.sql)
    if ($orderDoneHasUserId) {
        $pdo->prepare("INSERT INTO order_done (order_id, done_by, user_id) VALUES (?, ?, ?)")->execute([$orderId, $doneBy, $uid]);
    } else {
        $pdo->prepare("INSERT INTO order_done (order_id, done_by) VALUES (?, ?)")->execute([$orderId, $doneBy]);
    }

    // Check if BOTH sides confirmed now
    $stBoth = $pdo->prepare("SELECT COUNT(DISTINCT done_by) AS cnt FROM order_done WHERE order_id = ?");
    $stBoth->execute([$orderId]);
    $bothDone = ((int)$stBoth->fetchColumn()) >= 2;

    if ($bothDone) {
        try {
            $stU = $pdo->prepare("UPDATE orders SET status='completed', completed_at = NOW(), updated_at = NOW() WHERE id = ? AND status='in_progress'");
            $stU->execute([$orderId]);
        } catch (Throwable $e) {
            try {
                $stU = $pdo->prepare("UPDATE orders SET status='completed', completed_at = NOW() WHERE id = ? AND status='in_progress'");
                $stU->execute([$orderId]);
            } catch (Throwable $e2) {
                $stU = $pdo->prepare("UPDATE orders SET status='completed' WHERE id = ? AND status='in_progress'");
                $stU->execute([$orderId]);
            }
        }

        // Push both parties — order fully completed
        try {
            if (function_exists('push_notify_user')) {
                $title = 'Тапсырыс #' . $orderId . ' аяқталды';
                $body  = 'Екі жақ та орындалғанын растады / Заказ завершён';
                $data  = [
                    'type'     => 'order_completed',
                    'order_id' => (string)$orderId,
                ];
                push_notify_user($pdo, $clientId, $title, $body, $data);
                if ($masterId > 0) {
                    push_notify_user($pdo, $masterId, $title, $body, $data);
                }
            }
        } catch (Throwable $e) {}
    }

    // System message — only ONE per side
    $txt = ($role === 'client')
        ? 'Клиент завершил заказ / Клиент тапсырысты аяқтады'
        : 'Мастер завершил заказ / Шебер тапсырысты аяқтады';
    try {
        $pdo->prepare("INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, ?, ?, 1, NOW())")
            ->execute([$orderId, $uid, $txt]);
    } catch (Throwable $e) {}

    json_out(['ok' => true, 'data' => ['both_done' => $bothDone]]);
} catch (Throwable $e) {
    error_log('[order_finish] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
