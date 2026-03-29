<?php
declare(strict_types=1);

// Совместимый endpoint (если где-то остался вызов /api/reviews_create.php).
// По сути дублирует /api/review_add.php, но возвращает те же поля, которые ждёт старый фронт.

require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
require_role($user, 'client');

$raw = file_get_contents('php://input');
$in = json_decode($raw ?: '[]', true);
if (!is_array($in)) $in = [];

$orderId = (int)($in['order_id'] ?? 0);
$rating  = (int)($in['rating'] ?? 0);
$body    = trim((string)($in['body'] ?? $in['comment'] ?? ''));

if ($orderId <= 0) json_out(['ok'=>false,'error'=>'bad_order_id'], 400);
if ($rating < 1 || $rating > 5) json_out(['ok'=>false,'error'=>'bad_rating'], 400);
if (mb_strlen($body) > 2000) json_out(['ok'=>false,'error'=>'body_too_long'], 400);

$meId = (int)$user['id'];

try {
  $st = $pdo->prepare('SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1');
  $st->execute([$orderId]);
  $o = $st->fetch();
  if (!$o) json_out(['ok'=>false,'error'=>'order_not_found'], 404);

  if ((int)$o['client_id'] !== $meId) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  $masterId = (int)($o['master_id'] ?? 0);
  if ($masterId <= 0) json_out(['ok'=>false,'error'=>'no_master_in_order'], 409);

  if ((string)$o['status'] !== 'completed') json_out(['ok'=>false,'error'=>'order_not_completed'], 409);

  $st = $pdo->prepare('SELECT id FROM reviews WHERE order_id = ? LIMIT 1');
  $st->execute([$orderId]);
  if ($st->fetch()) json_out(['ok'=>false,'error'=>'review_already_exists'], 409);

  $st = $pdo->prepare('INSERT INTO reviews (order_id, client_id, master_id, rating, comment) VALUES (?,?,?,?,?)');
  $st->execute([$orderId, $meId, $masterId, $rating, ($body === '' ? null : $body)]);

  json_out(['ok'=>true, 'id'=>(int)$pdo->lastInsertId()]);

} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'server_error'], 500);
}
