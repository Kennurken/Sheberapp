<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

try {
  $st = $pdo->prepare(
    "SELECT
        0 AS earnings_total,
        COALESCE(SUM(CASE WHEN o.status = 'completed' THEN 1 ELSE 0 END), 0) AS completed_orders,
        COALESCE(SUM(CASE WHEN o.status IN ('new','in_progress') THEN 1 ELSE 0 END), 0) AS active_orders
     FROM orders o
     WHERE o.master_id = ?"
  );
  $st->execute([$uid]);
  $row = $st->fetch() ?: ['earnings_total' => 0, 'completed_orders' => 0, 'active_orders' => 0];

  $st = $pdo->prepare(
    "SELECT
        COALESCE(AVG(r.rating), 0) AS avg_rating,
        COUNT(*) AS reviews_count
     FROM reviews r
     WHERE r.master_id = ?"
  );
  $st->execute([$uid]);
  $rev = $st->fetch() ?: ['avg_rating' => 0, 'reviews_count' => 0];

  json_out([
    'ok' => true,
    'data' => [
      'earnings_total' => (int)$row['earnings_total'],
      'completed_orders' => (int)$row['completed_orders'],
      'active_orders' => (int)$row['active_orders'],
      'avg_rating' => (float)$rev['avg_rating'],
      'reviews_count' => (int)$rev['reviews_count'],
    ]
  ]);
} catch (Throwable $e) {
  // если таблицы ещё не созданы
  json_out([
    'ok' => true,
    'data' => [
      'earnings_total' => 0,
      'completed_orders' => 0,
      'active_orders' => 0,
      'avg_rating' => 0,
      'reviews_count' => 0,
    ]
  ]);
}
