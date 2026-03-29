<?php
declare(strict_types=1);

// Совместимый endpoint (если где-то остался вызов /api/reviews_list.php).
// Возвращает { ok:true, avg_rating, count, reviews:[...] } как раньше.

require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);

$masterId = get_int('master_id', 0);
if ($masterId <= 0) {
  // если не передали — считаем что мастер смотрит свои
  $masterId = (int)$user['id'];
}

$limit = get_int('limit', 50);
if ($limit < 1) $limit = 50;
if ($limit > 200) $limit = 200;

try {
  $st = $pdo->prepare(
    'SELECT id, order_id, client_id, rating, comment AS body, created_at '
    . 'FROM reviews WHERE master_id = ? ORDER BY created_at DESC LIMIT ' . (int)$limit
  );
  $st->execute([$masterId]);
  $rows = $st->fetchAll();

  $st2 = $pdo->prepare('SELECT AVG(rating) avg_rating, COUNT(*) cnt FROM reviews WHERE master_id = ?');
  $st2->execute([$masterId]);
  $agg = $st2->fetch() ?: ['avg_rating'=>null,'cnt'=>0];

  json_out([
    'ok' => true,
    'avg_rating' => ($agg['avg_rating'] !== null ? round((float)$agg['avg_rating'], 2) : null),
    'count' => (int)$agg['cnt'],
    'reviews' => $rows,
  ]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'server_error'], 500);
}
