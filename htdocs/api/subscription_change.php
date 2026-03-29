<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

$planId = get_int('plan_id', 0);
$mode = strtolower((string)($_POST['mode'] ?? 'next')); // next | now
if ($planId <= 0) json_out(['ok' => false, 'error' => 'plan_id_required'], 400);
if ($mode !== 'next' && $mode !== 'now') $mode = 'next';

// ensure status up to date
subscription_sync($pdo, $uid);

// plan exists?
$st = $pdo->prepare("SELECT id FROM subscription_plans WHERE id = ? LIMIT 1");
$st->execute([$planId]);
if (!$st->fetchColumn()) json_out(['ok' => false, 'error' => 'plan_not_found'], 404);

try {
  $pdo->beginTransaction();

  $st = $pdo->prepare("\n    SELECT id, plan_id, ends_at, status
    FROM master_subscriptions
    WHERE master_id = ?
    ORDER BY ends_at DESC
    LIMIT 1
    FOR UPDATE
  ");
  $st->execute([$uid]);
  $sub = $st->fetch(PDO::FETCH_ASSOC);
  if (!$sub) {
    $pdo->rollBack();
    json_out(['ok' => false, 'error' => 'no_subscription'], 404);
  }

  $now = new DateTimeImmutable('now');
  $endsAt = !empty($sub['ends_at']) ? new DateTimeImmutable((string)$sub['ends_at']) : null;
  $isActive = ((string)($sub['status'] ?? '') === 'active') && $endsAt && ($endsAt > $now);
  if (!$isActive) {
    $pdo->rollBack();
    json_out(['ok' => false, 'error' => 'not_active'], 409);
  }

  if ((int)$sub['plan_id'] === $planId) {
    $pdo->rollBack();
    json_out(['ok' => false, 'error' => 'same_plan'], 409);
  }

  if ($mode === 'now') {
    // Switching now is handled by subscription_buy (debit + new period). Keep change.php minimal.
    $pdo->rollBack();
    json_out(['ok' => false, 'error' => 'use_buy_for_now'], 400);
  }

  // schedule change on next renewal
  $st = $pdo->prepare("\n    UPDATE master_subscriptions
    SET next_plan_id = ?,
        next_renew_at = ends_at
    WHERE id = ?
  ");
  $st->execute([$planId, (int)$sub['id']]);

  $pdo->commit();
  json_out(['ok' => true, 'mode' => 'next', 'next_plan_id' => $planId, 'next_renew_at' => $endsAt->format('Y-m-d H:i:s')]);

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  error_log('[SUB CHANGE] ' . $e->getMessage());
  json_out(['ok' => false, 'error' => 'server_error'], 500);
}
