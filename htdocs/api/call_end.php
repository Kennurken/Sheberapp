<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
$meId = (int)$user['id'];

$callId = get_int('call_id', 0);
if ($callId <= 0) json_out(['ok' => false, 'error' => 'validation'], 422);

try {
  $st = $pdo->prepare("SELECT id, client_id, master_id, ended_at FROM webrtc_calls WHERE id = ? LIMIT 1");
  $st->execute([$callId]);
  $c = $st->fetch(PDO::FETCH_ASSOC);
  if (!$c) json_out(['ok' => false, 'error' => 'call_not_found'], 404);

  $isClient = ((int)$c['client_id'] === $meId);
  $isMaster = ((int)$c['master_id'] === $meId);
  if (!$isClient && !$isMaster) json_out(['ok' => false, 'error' => 'forbidden'], 403);

  // Idempotent: already ended
  if (!empty($c['ended_at'])) {
    json_out(['ok' => true, 'already_ended' => true]);
  }

  // Mark call ended and update status
  $st = $pdo->prepare("
    UPDATE webrtc_calls
    SET ended_at = NOW(), status = 'ended', last_activity = NOW()
    WHERE id = ?
  ");
  $st->execute([$callId]);

  // Insert hangup signal so the other participant sees it
  try {
    $st = $pdo->prepare("INSERT INTO webrtc_signals (call_id, from_user_id, type, payload, created_at) VALUES (?, ?, 'hangup', '{}', NOW())");
    $st->execute([$callId, $meId]);
  } catch (Throwable $e) {}

  json_out(['ok' => true]);
} catch (Throwable $e) {
  error_log('[call_end] ' . $e->getMessage());
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}
