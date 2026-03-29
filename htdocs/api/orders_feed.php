<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid  = (int)$user['id'];

$city  = get_str('city', 120);
$limit = get_int('limit', 30);
if ($limit < 1) $limit = 30;
if ($limit > 100) $limit = 100;

// Ensure profession_category_id column exists (best-effort, silent)
try { $pdo->exec("ALTER TABLE users ADD COLUMN profession_category_id INT DEFAULT NULL"); } catch (Throwable $e) {}

// Get master's profession category filter (isolated — missing column must not break feed)
$catFilter = null;
if ((string)($user['role'] ?? '') === 'master') {
    try {
        $st = $pdo->prepare("SELECT profession_category_id FROM users WHERE id = ? LIMIT 1");
        $st->execute([$uid]);
        $row = $st->fetch(PDO::FETCH_ASSOC);
        if ($row && !empty($row['profession_category_id'])) {
            $catFilter = (int)$row['profession_category_id'];
        }
    } catch (Throwable $e) {
        // column may not exist yet — show all new orders without category filter
    }
}

// Ensure order_bids table exists before querying it in subqueries below
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS order_bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL, master_id INT NOT NULL, amount INT NOT NULL,
        status ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_order_master (order_id, master_id), KEY idx_order (order_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

try {
    $pdo->exec("ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_lat DECIMAL(9,6) NULL");
    $pdo->exec("ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_lng DECIMAL(9,6) NULL");
} catch (Throwable $e) {}

try {

    $params = [$uid, $uid]; // first for my_bid subquery, second for client_id filter
    $sql = "
        SELECT
            o.id, o.client_id, o.category_id,
            o.description, o.address,
            o.client_lat, o.client_lng,
            COALESCE(o.city, c.city, '') AS city,
            o.price, o.status, o.created_at,
            COALESCE(c.name, o.guest_name, 'Клиент') AS client_name,
            COALESCE(mc.name, 'Тапсырыс') AS service_title,
            (SELECT COUNT(*) FROM order_bids ob
             WHERE ob.order_id = o.id AND ob.status = 'pending') AS bid_count,
            (SELECT ob2.amount FROM order_bids ob2
             WHERE ob2.order_id = o.id AND ob2.master_id = ?
               AND ob2.status IN ('pending','accepted')
             LIMIT 1) AS my_bid
        FROM orders o
        LEFT JOIN users c ON c.id = o.client_id
        LEFT JOIN master_categories mc ON mc.id = o.category_id
        WHERE o.status = 'new' AND o.master_id IS NULL AND o.client_id != ?
    ";

    // City filter must match how we *resolve* city for display (COALESCE in SELECT).
    // orders_create.php stores placeholder "Не указан" when client city was empty, while
    // the real city may only exist on users.city — strict `o.city = ?` then hid all such orders.
    if ($city !== '') {
        $sql .= "
          AND (
            (
              CASE
                WHEN TRIM(COALESCE(o.city, '')) IN ('', 'Не указан')
                  THEN NULLIF(TRIM(COALESCE(c.city, '')), '')
                ELSE NULLIF(TRIM(COALESCE(o.city, '')), '')
              END
            ) = ?
            OR (
              CASE
                WHEN TRIM(COALESCE(o.city, '')) IN ('', 'Не указан')
                  THEN NULLIF(TRIM(COALESCE(c.city, '')), '')
                ELSE NULLIF(TRIM(COALESCE(o.city, '')), '')
              END
            ) IS NULL
          )
        ";
        $params[] = $city;
    }
    if ($catFilter !== null) {
        $sql .= " AND o.category_id = ?";
        $params[] = $catFilter;
    }
    $sql .= " ORDER BY o.created_at DESC LIMIT ?";
    $params[] = $limit;

    $st = $pdo->prepare($sql);
    $st->execute($params);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

    // Attach photos
    try {
        $ids = array_values(array_filter(array_map(fn($r) => (int)($r['id'] ?? 0), $rows)));
        if (!empty($ids)) {
            $in = implode(',', array_fill(0, count($ids), '?'));
            $stp = $pdo->prepare("SELECT order_id, file_path FROM order_photos WHERE order_id IN ($in) ORDER BY id ASC");
            $stp->execute($ids);
            $map = [];
            foreach (($stp->fetchAll(PDO::FETCH_ASSOC) ?: []) as $p) {
                $oid = (int)($p['order_id'] ?? 0);
                $fp = (string)($p['file_path'] ?? '');
                if ($oid > 0 && $fp !== '') $map[$oid][] = '/' . ltrim($fp, '/');
            }
            foreach ($rows as &$r) {
                $r['photos'] = $map[(int)($r['id'] ?? 0)] ?? [];
            }
            unset($r);
        }
    } catch (Throwable $e) {}

    json_out(['ok' => true, 'data' => $rows]);
} catch (Throwable $e) {
    error_log('[orders_feed] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
