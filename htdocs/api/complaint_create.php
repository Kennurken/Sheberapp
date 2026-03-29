<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('complaint_create', 5, 300);
$user = require_login($pdo);
$uid = (int)$user['id'];

$orderId = get_int('order_id', 0);
$reason = str_clip(get_str('reason', 120, ''), 120);
$body = str_clip(get_str('body', 2000, ''), 2000);
if ($orderId <= 0 || $reason === '' || $body === '') {
  json_out(['ok'=>false,'error'=>'validation'], 422);
}

try {
  $st = $pdo->prepare('SELECT id, client_id, master_id FROM orders WHERE id = ? LIMIT 1');
  $st->execute([$orderId]);
  $o = $st->fetch(PDO::FETCH_ASSOC);
  if (!$o) json_out(['ok'=>false,'error'=>'not_found'], 404);

  $clientId = (int)$o['client_id'];
  $masterId = (int)($o['master_id'] ?? 0);
  $isClient = $clientId === $uid;
  $isMaster = $masterId === $uid;
  if (!$isClient && !$isMaster) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  $against = $isClient ? $masterId : $clientId;
  if ($against <= 0) json_out(['ok'=>false,'error'=>'no_target'], 409);

  $st = $pdo->prepare('INSERT INTO complaints (order_id, from_user_id, against_user_id, reason, body, status, created_at) VALUES (?,?,?,?,?,\'open\',NOW())');
  $st->execute([$orderId, $uid, $against, $reason, $body]);

  json_out(['ok'=>true, 'data'=>['saved'=>true]]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'db_error'], 500);
}
