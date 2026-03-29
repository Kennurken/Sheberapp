<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('POST');
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
  $status = (string)($o['status'] ?? 'new');

  $isClient = ($clientId === $meId);
  $isMaster = ($masterId > 0 && $masterId === $meId);
  if (!$isClient && !$isMaster) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  // Звонки только когда мастер уже назначен и заказ не закрыт
  if ($masterId <= 0) json_out(['ok'=>false,'error'=>'no_master'], 409);
  if ($status === 'completed' || $status === 'cancelled') json_out(['ok'=>false,'error'=>'order_closed'], 409);

  // Если уже есть активный звонок по этому заказу — переиспользуем
  $st = $pdo->prepare("\n    SELECT id\n    FROM webrtc_calls\n    WHERE order_id = ? AND ended_at IS NULL\n      AND created_at >= (NOW() - INTERVAL 2 HOUR)\n    ORDER BY id DESC\n    LIMIT 1\n  ");
  $st->execute([$orderId]);
  $row = $st->fetch(PDO::FETCH_ASSOC);
  if ($row) {
    json_out(['ok'=>true,'data'=>['call_id'=>(int)$row['id'], 'reused'=>true]]);
  }

  $st = $pdo->prepare("\n    INSERT INTO webrtc_calls (order_id, client_id, master_id, initiator_id, status, created_at, last_activity)\n    VALUES (?, ?, ?, ?, 'ringing', NOW(), NOW())\n  ");
  $st->execute([$orderId, $clientId, $masterId, $meId]);
  $callId = (int)$pdo->lastInsertId();

  // системный сигнал "start" — чтобы второй участник увидел входящий
  $payload = json_encode(['order_id'=>$orderId, 'call_id'=>$callId], JSON_UNESCAPED_UNICODE);
  $st = $pdo->prepare("INSERT INTO webrtc_signals (call_id, from_user_id, type, payload, created_at) VALUES (?, ?, 'start', ?, NOW())");
  $st->execute([$callId, $meId, $payload]);

  json_out(['ok'=>true,'data'=>['call_id'=>$callId, 'reused'=>false]]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'db_error'], 500);
}
