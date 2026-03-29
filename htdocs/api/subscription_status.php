<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

// Refresh subscription state (auto-renew / expire)
subscription_sync($pdo, $uid);

// user (balance + flags)
$st = $pdo->prepare("SELECT id, role, balance, is_subscribed FROM users WHERE id = ? LIMIT 1");
$st->execute([$uid]);
$me = $st->fetch(PDO::FETCH_ASSOC);
if (!$me) json_out(['ok' => false, 'error' => 'unauthorized'], 401);

// plans
$plans = [];
// max_daily_accepts: 0 = unlimited
try {
  $st = $pdo->query("SELECT id, title, price, period_days, max_active_orders, COALESCE(max_daily_accepts,0) AS max_daily_accepts FROM subscription_plans ORDER BY price ASC, id ASC");
  $plans = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
} catch (Throwable $e) {
  // fallback for older DB schema
  $st = $pdo->query("SELECT id, title, price, period_days, max_active_orders, 0 AS max_daily_accepts FROM subscription_plans ORDER BY price ASC, id ASC");
  $plans = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
}

// current subscription (latest)
$sub = null;
$st = $pdo->prepare("
  SELECT ms.id, ms.plan_id, ms.starts_at, ms.ends_at, ms.status,
         COALESCE(ms.auto_renew, 1) AS auto_renew,
         COALESCE(ms.cancel_at_period_end, 0) AS cancel_at_period_end,
         ms.canceled_at,
         ms.next_plan_id,
         ms.next_renew_at,
         sp.title, sp.price, sp.period_days, sp.max_active_orders,
         COALESCE(sp.max_daily_accepts,0) AS max_daily_accepts,
         sp2.title AS next_plan_title
  FROM master_subscriptions ms
  LEFT JOIN subscription_plans sp ON sp.id = ms.plan_id
  LEFT JOIN subscription_plans sp2 ON sp2.id = ms.next_plan_id
  WHERE ms.master_id = ?
  ORDER BY ms.ends_at DESC
  LIMIT 1
");
try {
  $st->execute([$uid]);
  $sub = $st->fetch(PDO::FETCH_ASSOC) ?: null;
} catch (Throwable $e) {
  // fallback for older DB schema without max_daily_accepts
  $st = $pdo->prepare("
    SELECT ms.id, ms.plan_id, ms.starts_at, ms.ends_at, ms.status,
           COALESCE(ms.auto_renew, 1) AS auto_renew,
           COALESCE(ms.cancel_at_period_end, 0) AS cancel_at_period_end,
           ms.canceled_at,
           ms.next_plan_id,
           ms.next_renew_at,
           sp.title, sp.price, sp.period_days, sp.max_active_orders,
           0 AS max_daily_accepts,
           sp2.title AS next_plan_title
    FROM master_subscriptions ms
    LEFT JOIN subscription_plans sp ON sp.id = ms.plan_id
    LEFT JOIN subscription_plans sp2 ON sp2.id = ms.next_plan_id
    WHERE ms.master_id = ?
    ORDER BY ms.ends_at DESC
    LIMIT 1
  ");
  $st->execute([$uid]);
  $sub = $st->fetch(PDO::FETCH_ASSOC) ?: null;
}

$now = new DateTimeImmutable('now');
$isActive = false;

if ($sub && ($sub['status'] ?? '') === 'active' && !empty($sub['ends_at'])) {
  $endsAt = new DateTimeImmutable((string)$sub['ends_at']);
  $isActive = ($endsAt > $now);
}

json_out([
  'ok' => true,
  'me' => [
    'id' => (int)$me['id'],
    'balance' => (float)$me['balance'],
    'is_subscribed' => (int)$me['is_subscribed'],
  ],
  'subscription' => $sub ? [
    'plan_id' => (int)($sub['plan_id'] ?? 0),
    'title' => (string)($sub['title'] ?? ''),
    'starts_at' => (string)($sub['starts_at'] ?? ''),
    'ends_at' => (string)($sub['ends_at'] ?? ''),
    'status' => (string)($sub['status'] ?? ''),
    'is_active' => $isActive,
    'auto_renew' => (int)($sub['auto_renew'] ?? 1),
    'cancel_at_period_end' => (int)($sub['cancel_at_period_end'] ?? 0),
    'canceled_at' => (string)($sub['canceled_at'] ?? ''),
    'next_plan_id' => (int)($sub['next_plan_id'] ?? 0),
    'next_plan_title' => (string)($sub['next_plan_title'] ?? ''),
    'next_renew_at' => (string)($sub['next_renew_at'] ?? ''),
    'max_active_orders' => isset($sub['max_active_orders']) ? (int)$sub['max_active_orders'] : null,
    'max_daily_accepts' => isset($sub['max_daily_accepts']) ? (int)$sub['max_daily_accepts'] : null,
  ] : null,
  'plans' => array_map(static function($p) {
    return [
      'id' => (int)$p['id'],
      'title' => (string)$p['title'],
      'price' => (float)$p['price'],
      'period_days' => (int)$p['period_days'],
      'max_active_orders' => (int)$p['max_active_orders'],
      'max_daily_accepts' => (int)($p['max_daily_accepts'] ?? 0),
    ];
  }, $plans),
]);
