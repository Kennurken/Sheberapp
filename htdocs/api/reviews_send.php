<?php
declare(strict_types=1);
/**
 * Create a new review after order completion.
 * POST /api/reviews_send.php
 *   order_id  — required
 *   master_id — required
 *   rating    — 1..5 (default 5)
 *   comment   — optional text (max 1000 chars)
 *
 * Sets editable_until = NOW() + 3 DAYS so client can change rating within that window.
 * Called by Flutter after order completion dialog.
 */

require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('reviews_send', 5, 300);
$user = require_login($pdo);
require_role($user, 'client');
$uid = (int)$user['id'];

// Auto-add columns if DB was created before this feature
try {
    $pdo->exec("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS editable_until DATETIME NULL");
    $pdo->exec("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS updated_at DATETIME NULL");
} catch (Throwable $e) {}

$masterId = get_int('master_id', 0);
$orderId  = get_int('order_id', 0);
$rating   = max(1, min(5, get_int('rating', 5)));
$comment  = get_str('comment', 1000);

if ($masterId <= 0) json_out(['ok' => false, 'error' => 'master_id_required'], 400);
if ($orderId  <= 0) json_out(['ok' => false, 'error' => 'order_id_required'],  400);

try {
    // Verify order is completed and belongs to this client
    $st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
    $st->execute([$orderId]);
    $order = $st->fetch();

    if (!$order) json_out(['ok' => false, 'error' => 'order_not_found'], 404);
    if ((int)$order['client_id'] !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);
    if ((string)$order['status'] !== 'completed') json_out(['ok' => false, 'error' => 'order_not_completed'], 409);
    // Prevent self-review: client cannot review themselves as the master
    if ((int)$order['master_id'] === $uid) json_out(['ok' => false, 'error' => 'self_review_forbidden'], 403);

    // Prevent duplicate review for this order
    $st = $pdo->prepare("SELECT id FROM reviews WHERE order_id = ? AND client_id = ? LIMIT 1");
    $st->execute([$orderId, $uid]);
    if ($st->fetch()) json_out(['ok' => false, 'error' => 'already_reviewed'], 409);

    // 5★ — отзыв окончательный; <5 — 3 күндік өңдеу терезесі
    if ($rating >= 5) {
        $st = $pdo->prepare("
            INSERT INTO reviews (master_id, client_id, order_id, rating, comment, created_at, editable_until)
            VALUES (?, ?, ?, ?, ?, NOW(), NULL)
        ");
    } else {
        $st = $pdo->prepare("
            INSERT INTO reviews (master_id, client_id, order_id, rating, comment, created_at, editable_until)
            VALUES (?, ?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY))
        ");
    }
    $st->execute([$masterId, $uid, $orderId, $rating, $comment]);
    $reviewId = (int)$pdo->lastInsertId();

    // Fetch editable_until to return to client
    $st = $pdo->prepare("SELECT editable_until FROM reviews WHERE id = ? LIMIT 1");
    $st->execute([$reviewId]);
    $row = $st->fetch();

    json_out([
        'ok'   => true,
        'data' => [
            'review_id'      => $reviewId,
            'editable_until' => $row['editable_until'] ?? null,
        ],
    ]);
} catch (Throwable $e) {
    error_log('[reviews_send] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
