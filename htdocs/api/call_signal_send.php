<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('call_signal_send', 120, 60);
$user = require_login($pdo);
$meId = (int)$user['id'];

$callId = get_int('call_id', 0);
$type = str_clip((string)($_POST['type'] ?? ''), 20);
$payload = (string)($_POST['payload'] ?? '');

if ($callId <= 0 || $type === '') json_out(['ok'=>false,'error'=>'validation'], 422);

$allowed = ['offer','answer','candidate','hangup','reject'];
if (!in_array($type, $allowed, true)) json_out(['ok'=>false,'error'=>'bad_type'], 422);

// ограничим размер, чтобы не убить БД
if (strlen($payload) > 200000) json_out(['ok'=>false,'error'=>'payload_too_large'], 413);

try {
  $st = $pdo->prepare("SELECT id, client_id, master_id, ended_at FROM webrtc_calls WHERE id = ? LIMIT 1");
  $st->execute([$callId]);
  $c = $st->fetch(PDO::FETCH_ASSOC);
  if (!$c) json_out(['ok'=>false,'error'=>'call_not_found'], 404);

  if (!empty($c['ended_at'])) json_out(['ok'=>false,'error'=>'call_ended'], 409);

  $isClient = ((int)$c['client_id'] === $meId);
  $isMaster = ((int)$c['master_id'] === $meId);
  if (!$isClient && !$isMaster) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  $st = $pdo->prepare("INSERT INTO webrtc_signals (call_id, from_user_id, type, payload, created_at) VALUES (?, ?, ?, ?, NOW())");
  $st->execute([$callId, $meId, $type, $payload]);

  $st = $pdo->prepare("UPDATE webrtc_calls SET last_activity = NOW(), status = CASE WHEN ? IN ('offer','answer') THEN 'in_call' ELSE status END WHERE id = ?");
  $st->execute([$type, $callId]);

  json_out(['ok'=>true,'data'=>['sent'=>true]]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'db_error'], 500);
}
