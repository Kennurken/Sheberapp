<?php
declare(strict_types=1);
/**
 * Update an existing review within the 3-day edit window.
 * POST /api/review_update.php
 *   review_id — required
 *   rating    — 1..5
 *   comment   — optional text (max 1000 chars)
 *
 * Returns {ok: false, error: 'edit_window_closed'} after 3 days.
 * Adds a system message to the order chat when review is updated.
 */

require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
require_role($user, 'client');
$uid = (int)$user['id'];

$reviewId = get_int('review_id', 0);
$rating   = max(1, min(5, get_int('rating', 5)));
$comment  = get_str('comment', 1000);

if ($reviewId <= 0) json_out(['ok' => false, 'error' => 'review_id_required'], 400);

try {
    // Fetch review and check ownership + edit window
    $st = $pdo->prepare("
        SELECT id, client_id, order_id, editable_until, rating
        FROM reviews
        WHERE id = ? LIMIT 1
    ");
    $st->execute([$reviewId]);
    $review = $st->fetch();

    if (!$review) json_out(['ok' => false, 'error' => 'not_found'], 404);
    if ((int)$review['client_id'] !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);

    if ((int)($review['rating'] ?? 0) >= 5) {
        json_out(['ok' => false, 'error' => 'review_finalized'], 403);
    }

    // Check edit window
    $editableUntil = $review['editable_until'] ?? '';
    if (empty($editableUntil)) {
        json_out(['ok' => false, 'error' => 'edit_window_closed'], 403);
    }
    try {
        $deadline = new DateTimeImmutable($editableUntil);
        $now      = new DateTimeImmutable('now');
        if ($deadline <= $now) {
            json_out(['ok' => false, 'error' => 'edit_window_closed'], 403);
        }
    } catch (Throwable $e) {
        json_out(['ok' => false, 'error' => 'edit_window_closed'], 403);
    }

    // Update the review; 5★ отзыв больше нельзя менять — снимаем окно редактирования
    if ($rating >= 5) {
        $pdo->prepare("
            UPDATE reviews SET rating = ?, comment = ?, updated_at = NOW(), editable_until = NULL
            WHERE id = ?
        ")->execute([$rating, $comment, $reviewId]);
    } else {
        $pdo->prepare("
            UPDATE reviews SET rating = ?, comment = ?, updated_at = NOW()
            WHERE id = ?
        ")->execute([$rating, $comment, $reviewId]);
    }

    // Add system message to order chat (nice-to-have, best-effort)
    $orderId = (int)($review['order_id'] ?? 0);
    if ($orderId > 0) {
        $stars = str_repeat('⭐', $rating);
        $sysText = "Клиент обновил отзыв {$stars}";
        try {
            $pdo->prepare("
                INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at)
                VALUES (?, ?, ?, 1, NOW())
            ")->execute([$orderId, $uid, $sysText]);
        } catch (Throwable $e) {}
    }

    json_out(['ok' => true]);
} catch (Throwable $e) {
    error_log('[review_update] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
