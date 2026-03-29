<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');

$user    = require_login($pdo);
$uid     = (int)$user['id'];
$orderId = get_int('order_id', 0);

if ($orderId <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Ensure table exists (created by orders_bid.php but guard here too)
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS order_bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        master_id INT NOT NULL,
        amount INT NOT NULL,
        status ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_order_master (order_id, master_id),
        KEY idx_order (order_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

// Verify the user is the client of this order
$st = $pdo->prepare("SELECT client_id, master_id FROM orders WHERE id = ? LIMIT 1");
$st->execute([$orderId]);
$order = $st->fetch();
if (!$order) {
    json_out(['ok' => false, 'error' => 'not_found'], 404);
}

// Both client and master can see bids
$clientId = (int)$order['client_id'];
$masterId = (int)($order['master_id'] ?? 0);
if ($clientId !== $uid && $masterId !== $uid) {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

// Ensure is_verified column exists
try { $pdo->exec("ALTER TABLE users ADD COLUMN is_verified TINYINT(1) NOT NULL DEFAULT 0"); } catch (Throwable $e) {}

try {
    $st = $pdo->prepare("
        SELECT
            ob.id,
            ob.order_id,
            ob.master_id,
            ob.amount,
            ob.status,
            ob.created_at,
            COALESCE(u.name, 'Шебер') AS master_name,
            COALESCE(u.avatar_url, '') AS master_avatar_url,
            COALESCE(u.avatar_color, '#1cb7ff') AS master_avatar_color,
            COALESCE(u.profession, '') AS master_profession,
            COALESCE(u.experience, 0) AS master_experience,
            COALESCE(u.is_verified, 0) AS is_verified,
            COALESCE(
                (SELECT AVG(r.rating) FROM reviews r WHERE r.master_id = ob.master_id),
                5.0
            ) AS master_rating
        FROM order_bids ob
        LEFT JOIN users u ON u.id = ob.master_id
        WHERE ob.order_id = ? AND ob.status = 'pending'
        ORDER BY ob.amount ASC
    ");
    $st->execute([$orderId]);
    $rows = $st->fetchAll() ?: [];
} catch (Throwable $e) {
    error_log('[orders_bids_list] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

$bids = array_map(fn($r) => [
    'id'                  => (int)$r['id'],
    'order_id'            => (int)$r['order_id'],
    'master_id'           => (int)$r['master_id'],
    'amount'              => (int)$r['amount'],
    'status'              => $r['status'],
    'created_at'          => $r['created_at'],
    'master_name'         => $r['master_name'],
    'master_avatar_url'   => $r['master_avatar_url'],
    'master_avatar_color' => $r['master_avatar_color'],
    'master_profession'   => $r['master_profession'],
    'master_experience'   => (int)$r['master_experience'],
    'master_rating'       => round((float)$r['master_rating'], 1),
    'is_verified'         => (int)($r['is_verified'] ?? 0),
], $rows);

json_out(['ok' => true, 'data' => $bids]);
