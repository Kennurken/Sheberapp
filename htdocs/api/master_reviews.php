<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$masterId = get_int('master_id', 0);
if ($masterId <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

try {
    // Last 30 reviews for this master, newest first
    $st = $pdo->prepare("
        SELECT
            r.id,
            r.rating,
            COALESCE(r.comment, '')               AS comment,
            COALESCE(c.name, 'Клиент')            AS client_name,
            COALESCE(mc.name, r.order_title, '')  AS order_title,
            r.created_at
        FROM reviews r
        LEFT JOIN users c  ON c.id  = r.client_id
        LEFT JOIN orders o ON o.id  = r.order_id
        LEFT JOIN master_categories mc ON mc.id = o.category_id
        WHERE r.master_id = ?
        ORDER BY r.created_at DESC
        LIMIT 30
    ");
    $st->execute([$masterId]);
    $rows = $st->fetchAll() ?: [];
} catch (Throwable $e) {
    // Fallback without order join if schema differs
    try {
        $st = $pdo->prepare("
            SELECT
                r.id,
                r.rating,
                COALESCE(r.comment, '') AS comment,
                COALESCE(c.name, 'Клиент') AS client_name,
                '' AS order_title,
                r.created_at
            FROM reviews r
            LEFT JOIN users c ON c.id = r.client_id
            WHERE r.master_id = ?
            ORDER BY r.created_at DESC
            LIMIT 30
        ");
        $st->execute([$masterId]);
        $rows = $st->fetchAll() ?: [];
    } catch (Throwable $e2) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }
}

$reviews = array_map(fn($r) => [
    'id'          => (int)$r['id'],
    'rating'      => (int)$r['rating'],
    'comment'     => $r['comment'],
    'client_name' => $r['client_name'],
    'order_title' => $r['order_title'],
    'created_at'  => $r['created_at'],
], $rows);

json_out(['ok' => true, 'data' => $reviews]);
