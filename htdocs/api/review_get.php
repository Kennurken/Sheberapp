<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid = (int)$user['id'];

$orderId = get_int('order_id', 0);
if ($orderId <= 0) json_out(['ok' => false, 'error' => 'validation'], 422);

try {
  $st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
  $st->execute([$orderId]);
  $o = $st->fetch();
  if (!$o) json_out(['ok' => false, 'error' => 'not_found'], 404);

  $isClient = ((int)$o['client_id'] === $uid);
  $isMaster = ((int)($o['master_id'] ?? 0) === $uid);
  if (!$isClient && !$isMaster) json_out(['ok' => false, 'error' => 'forbidden'], 403);

  $st = $pdo->prepare("
    SELECT
      r.id,
      r.order_id,
      r.master_id,
      r.client_id,
      r.rating,
      r.comment            AS body,
      r.comment,
      r.created_at,
      r.editable_until,
      r.updated_at,
      (r.editable_until IS NOT NULL AND r.editable_until > NOW() AND r.rating < 5) AS can_edit,
      GREATEST(0, TIMESTAMPDIFF(HOUR, NOW(), r.editable_until))   AS hours_remaining
    FROM reviews r
    WHERE r.order_id = ?
    LIMIT 1
  ");

  // Fallback for DBs without editable_until column yet
  try {
    $st->execute([$orderId]);
    $r = $st->fetch(PDO::FETCH_ASSOC) ?: null;
  } catch (Throwable $e) {
    $st2 = $pdo->prepare("SELECT id, order_id, rating, comment AS body, comment, created_at FROM reviews WHERE order_id = ? LIMIT 1");
    $st2->execute([$orderId]);
    $r = $st2->fetch(PDO::FETCH_ASSOC) ?: null;
    if ($r) {
      $r['editable_until']  = null;
      $r['can_edit']        = false;
      $r['hours_remaining'] = 0;
      $r['updated_at']      = null;
    }
  }

  if ($r) {
    // Normalise types for Flutter
    $r['can_edit']        = (bool)($r['can_edit'] ?? false);
    $r['hours_remaining'] = (int)($r['hours_remaining'] ?? 0);
    $r['rating']          = (int)($r['rating'] ?? 5);
    // Only client can see can_edit (master sees review but can't edit it)
    if (!$isClient) $r['can_edit'] = false;
  }

  json_out(['ok' => true, 'data' => $r]);
} catch (Throwable $e) {
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}
