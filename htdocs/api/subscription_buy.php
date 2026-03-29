<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

$planId = get_int('plan_id', 0);
if ($planId <= 0) json_out(['ok' => false, 'error' => 'plan_id_required'], 400);

// plan
$st = $pdo->prepare("SELECT id, title, price, period_days FROM subscription_plans WHERE id = ? LIMIT 1");
$st->execute([$planId]);
$plan = $st->fetch(PDO::FETCH_ASSOC);
if (!$plan) json_out(['ok' => false, 'error' => 'plan_not_found'], 404);

$price = (float)$plan['price'];
$periodDays = (int)$plan['period_days'];

try {
  $pdo->beginTransaction();

  // refresh state first (auto-renew/expire)
  subscription_sync($pdo, $uid);

  // If there is an active subscription -> DO NOT switch immediately.
  // Like Spotify/Yandex: you stay on current plan until period end.
  // Any plan change is scheduled for next renewal via next_plan_id.
  $st = $pdo->prepare("
    SELECT id, plan_id, ends_at, status,
           COALESCE(auto_renew,1) AS auto_renew,
           COALESCE(cancel_at_period_end,0) AS cancel_at_period_end
    FROM master_subscriptions
    WHERE master_id = ?
    ORDER BY ends_at DESC
    LIMIT 1
    FOR UPDATE
  ");
  $st->execute([$uid]);
  $cur = $st->fetch(PDO::FETCH_ASSOC);

  $now = new DateTimeImmutable('now');
  $curEnds = ($cur && !empty($cur['ends_at'])) ? new DateTimeImmutable((string)$cur['ends_at']) : null;
  $curIsActive = $cur && ((string)($cur['status'] ?? '') === 'active') && $curEnds && ($curEnds > $now);

  if ($curIsActive) {
    if ((int)$cur['plan_id'] === $planId && (int)$cur['cancel_at_period_end'] === 0) {
      $pdo->rollBack();
      json_out(['ok' => false, 'error' => 'already_active'], 409);
    }

    // schedule change on next renewal
    $st = $pdo->prepare("\n      UPDATE master_subscriptions\n      SET next_plan_id = ?,\n          next_renew_at = ends_at,\n          auto_renew = 1,\n          cancel_at_period_end = 0,\n          canceled_at = NULL\n      WHERE id = ?\n    ");
    $st->execute([$planId, (int)$cur['id']]);

    $pdo->commit();
    json_out([
      'ok' => true,
      'scheduled' => true,
      'current_plan_id' => (int)$cur['plan_id'],
      'next_plan_id' => $planId,
      'next_renew_at' => $curEnds ? $curEnds->format('Y-m-d H:i:s') : null
    ]);
  }

  // No active subscription: real purchase now.

  // lock user balance
  $st = $pdo->prepare("SELECT balance FROM users WHERE id = ? FOR UPDATE");
  $st->execute([$uid]);
  $row = $st->fetch(PDO::FETCH_ASSOC);
  if (!$row) throw new RuntimeException('user_missing');

  $balance = (float)$row['balance'];
  if ($balance + 0.00001 < $price) {
    $pdo->rollBack();
    json_out([
      'ok' => false,
      'error' => 'insufficient_funds',
      'need' => $price,
      'balance' => $balance
    ], 402);
  }

  // debit
  $st = $pdo->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
  $st->execute([$price, $uid]);

  $startsAt = $now;
  $endsAt = $now->modify('+' . $periodDays . ' days');

  // create subscription row (auto-renew on by default)
  $st = $pdo->prepare("
    INSERT INTO master_subscriptions
      (master_id, plan_id, starts_at, ends_at, status, auto_renew, cancel_at_period_end, canceled_at, next_plan_id, next_renew_at)
    VALUES (?, ?, ?, ?, 'active', 1, 0, NULL, NULL, NULL)
  ");
  $st->execute([$uid, $planId, $startsAt->format('Y-m-d H:i:s'), $endsAt->format('Y-m-d H:i:s')]);

  // flag
  $st = $pdo->prepare("UPDATE users SET is_subscribed = 1 WHERE id = ?");
  $st->execute([$uid]);

  $pdo->commit();

  json_out([
    'ok' => true,
    'scheduled' => false,
    'paid' => $price,
    'balance_after' => round($balance - $price, 2),
    'plan' => ['id' => (int)$plan['id'], 'title' => (string)$plan['title']],
    'ends_at' => $endsAt->format('Y-m-d H:i:s')
  ]);

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  error_log('[SUB BUY] ' . $e->getMessage());
  json_out(['ok' => false, 'error' => 'server_error'], 500);
}
