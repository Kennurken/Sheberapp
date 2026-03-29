<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$meId = (int)$user['id'];

$callId = get_int('call_id', 0);
$afterId = get_int('after_id', 0);
if ($callId <= 0) json_out(['ok'=>false,'error'=>'validation'], 422);

try {
  $st = $pdo->prepare("SELECT id, client_id, master_id, ended_at FROM webrtc_calls WHERE id = ? LIMIT 1");
  $st->execute([$callId]);
  $c = $st->fetch(PDO::FETCH_ASSOC);
  if (!$c) json_out(['ok'=>false,'error'=>'call_not_found'], 404);

  $isClient = ((int)$c['client_id'] === $meId);
  $isMaster = ((int)$c['master_id'] === $meId);
  if (!$isClient && !$isMaster) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  $st = $pdo->prepare("\n    SELECT id, from_user_id, type, payload, created_at\n    FROM webrtc_signals\n    WHERE call_id = ? AND id > ?\n    ORDER BY id ASC\n    LIMIT 50\n  ");
  $st->execute([$callId, $afterId]);
  $rows = $st->fetchAll(PDO::FETCH_ASSOC);

  $signals = [];
  foreach ($rows as $r) {
    $signals[] = [
      'id' => (int)$r['id'],
      'from_user_id' => (int)$r['from_user_id'],
      'type' => (string)$r['type'],
      'payload' => (string)$r['payload'],
      'created_at' => (string)$r['created_at'],
    ];
  }

  json_out(['ok'=>true,'data'=>[
    'me'=>$meId,
    'ended'=>!empty($c['ended_at']),
    'signals'=>$signals
  ]]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'db_error'], 500);
}
