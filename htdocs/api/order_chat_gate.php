<?php
declare(strict_types=1);

/**
 * Чат по завершённому заказу с отзывом 5★ закрыт для обеих сторон.
 */
function order_chat_closed_perfect_review(PDO $pdo, int $orderId, string $orderStatus): bool
{
    if ($orderId <= 0 || $orderStatus !== 'completed') {
        return false;
    }
    $st = $pdo->prepare('SELECT rating FROM reviews WHERE order_id = ? AND rating >= 5 LIMIT 1');
    $st->execute([$orderId]);
    return (bool) $st->fetch(PDO::FETCH_ASSOC);
}
