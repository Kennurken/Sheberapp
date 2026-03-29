<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$meId = (int)$user['id'];

$orderId = get_int('order_id', 0);
if ($orderId <= 0) json_out(['ok'=>false,'error'=>'validation'], 422);

try {
  $st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
  $st->execute([$orderId]);
  $o = $st->fetch(PDO::FETCH_ASSOC);
  if (!$o) json_out(['ok'=>false,'error'=>'order_not_found'], 404);

  $clientId = (int)$o['client_id'];
  $masterId = (int)($o['master_id'] ?? 0);
  $isClient = ($clientId === $meId);
  $isMaster = ($masterId > 0 && $masterId === $meId);
  if (!$isClient && !$isMaster) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  $st = $pdo->prepare("\n    SELECT id, initiator_id, status, created_at\n    FROM webrtc_calls\n    WHERE order_id = ? AND ended_at IS NULL\n      AND created_at >= (NOW() - INTERVAL 2 HOUR)\n    ORDER BY id DESC\n    LIMIT 1\n  ");
  $st->execute([$orderId]);
  $c = $st->fetch(PDO::FETCH_ASSOC);
  if (!$c) json_out(['ok'=>true,'data'=>['call'=>null]]);

  json_out(['ok'=>true,'data'=>['call'=>[
    'id'=>(int)$c['id'],
    'initiator_id'=>(int)$c['initiator_id'],
    'status'=>(string)$c['status'],
    'created_at'=>(string)$c['created_at'],
  ]]]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'db_error'], 500);
}
