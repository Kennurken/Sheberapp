<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

// push_send.php is optional — guard so a missing/broken file never blocks order acceptance
try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}

require_method('POST');
rate_limit('orders_accept', 20, 60);
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

// refresh subscription state (auto-renew / expire)
// subscription_sync($pdo, $uid); // временно отключено — бесплатный период

// БЕСПЛАТНЫЙ ПЕРИОД: подписка не требуется
// Лимиты: не более 10 активных заказов одновременно
$maxActive = 10;
$maxDaily  = 0; // без ограничений

/*
// Подписка мастера — ВРЕМЕННО ОТКЛЮЧЕНО
$st = $pdo->prepare("
  SELECT sp.max_active_orders, COALESCE(sp.max_daily_accepts,0) AS max_daily_accepts
  FROM master_subscriptions ms
  JOIN subscription_plans sp ON sp.id = ms.plan_id
  WHERE ms.master_id = ? AND ms.status = 'active' AND ms.ends_at > NOW()
  ORDER BY ms.ends_at DESC
  LIMIT 1
");
$st->execute([$uid]);
$planRow = $st->fetch(PDO::FETCH_ASSOC);
if (!$planRow) {
  json_out(['ok' => false, 'error' => 'subscription_required'], 402);
}
$maxActive = (int)($planRow['max_active_orders'] ?? 0);
$maxDaily = (int)($planRow['max_daily_accepts'] ?? 0);
*/
if ($maxActive > 0) {
  $st = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE master_id = ? AND status = 'in_progress'");
  $st->execute([$uid]);
  $activeCnt = (int)$st->fetchColumn();
  if ($activeCnt >= $maxActive) {
    json_out(['ok' => false, 'error' => 'active_orders_limit', 'limit' => $maxActive], 409);
  }
}

// Дневной лимит принятых заказов (Basic = 5/day). Считаем по accepted_at.
// Важно: лимит не должен "освобождаться" от обновления страницы.
if ($maxDaily > 0) {
  $acceptedToday = 0;
  try {
    $st = $pdo->prepare("
      SELECT COUNT(*)
      FROM orders
      WHERE master_id = ?
        AND accepted_at >= CURDATE()
        AND accepted_at < (CURDATE() + INTERVAL 1 DAY)
    ");
    $st->execute([$uid]);
    $acceptedToday = (int)$st->fetchColumn();
  } catch (Throwable $e) {
    // fallback if accepted_at column отсутствует
    $st = $pdo->prepare("
      SELECT COUNT(*)
      FROM orders
      WHERE master_id = ?
        AND created_at >= CURDATE()
        AND created_at < (CURDATE() + INTERVAL 1 DAY)
    ");
    $st->execute([$uid]);
    $acceptedToday = (int)$st->fetchColumn();
  }
  if ($acceptedToday >= $maxDaily) {
    json_out(['ok' => false, 'error' => 'daily_limit', 'limit' => $maxDaily], 403);
  }
}

$orderId = get_int('order_id', 0);
if ($orderId <= 0) json_out(['ok' => false, 'error' => 'validation'], 422);

try {
  $st = $pdo->prepare("SELECT id, master_id, status FROM orders WHERE id = ? LIMIT 1");
  $st->execute([$orderId]);
  $o = $st->fetch();
  if (!$o) json_out(['ok' => false, 'error' => 'not_found'], 404);

  $curMaster = (int)($o['master_id'] ?? 0);
  // Разрешаем принять заказ, если:
  // - заказ назначен этому мастеру, либо
  // - заказ ещё без мастера (master_id IS NULL/0) — тогда назначаем.
  if ($curMaster !== 0 && $curMaster !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);

  $cur = (string)($o['status'] ?? 'new');
  // Идемпотентность: если этот мастер уже принял заказ — отвечаем ok
  if ($cur !== 'new') {
    if ($cur === 'in_progress' && $curMaster === $uid) {
      json_out(['ok' => true]);
    }
    json_out(['ok' => false, 'error' => 'bad_state'], 409);
  }

  // Атомарное принятие: назначаем мастера только если заказ ещё без мастера.
  // Это закрывает гонку, когда два мастера принимают почти одновременно.
  $updated = 0;
  try {
    $st = $pdo->prepare("
      UPDATE orders
      SET master_id = ?,
          status = 'in_progress',
          accepted_at = NOW(),
          updated_at = NOW()
      WHERE id = ?
        AND status = 'new'
        AND (master_id IS NULL OR master_id = 0)
    ");
    $st->execute([$uid, $orderId]);
    $updated = $st->rowCount();
  } catch (Throwable $e) {
    // fallback (без updated_at)
    $st = $pdo->prepare("
      UPDATE orders
      SET master_id = ?,
          status = 'in_progress',
          accepted_at = NOW()
      WHERE id = ?
        AND status = 'new'
        AND (master_id IS NULL OR master_id = 0)
    ");
    $st->execute([$uid, $orderId]);
    $updated = $st->rowCount();
  }

  if ($updated !== 1) {
    // кто-то уже принял / либо статус изменился
    $st = $pdo->prepare("SELECT master_id, status FROM orders WHERE id = ? LIMIT 1");
    $st->execute([$orderId]);
    $o2 = $st->fetch(PDO::FETCH_ASSOC);
    if ($o2 && (string)($o2['status'] ?? '') === 'in_progress' && (int)($o2['master_id'] ?? 0) === $uid) {
      json_out(['ok' => true]);
    }
    json_out(['ok' => false, 'error' => 'already_taken'], 409);
  }

  // служебное сообщение
  try {
    $st = $pdo->prepare("INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, ?, ?, 1, NOW())");
    $st->execute([$orderId, $uid, 'Мастер принял заказ / Шебер тапсырысты қабылдады']);
  } catch (Throwable $e) {}

  // Notify client
  try {
    $stOrder = $pdo->prepare("SELECT client_id FROM orders WHERE id = ? LIMIT 1");
    $stOrder->execute([$orderId]);
    $orderRow = $stOrder->fetch(PDO::FETCH_ASSOC);
    $clientId = (int)($orderRow['client_id'] ?? 0);
    if ($clientId > 0 && function_exists('push_notify_user')) {
      $masterName = (string)($user['name'] ?? 'Мастер');
      push_notify_user($pdo, $clientId,
        'Мастер принял заказ',
        "{$masterName} принял ваш заказ. Откройте чат.",
        ['type' => 'order_accepted', 'order_id' => (string)$orderId]
      );
    }
  } catch (Throwable $e) {
    error_log('[orders_accept] push error: ' . $e->getMessage());
  }

  json_out(['ok' => true]);
} catch (Throwable $e) {
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}