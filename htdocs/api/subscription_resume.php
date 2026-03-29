<?php
declare(strict_types=1);

require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

subscription_sync($pdo, $uid);

try {
  $pdo->beginTransaction();

  $st = $pdo->prepare("\n    SELECT id, ends_at, status
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

  $st = $pdo->prepare("\n    UPDATE master_subscriptions
    SET auto_renew = 1,
        cancel_at_period_end = 0,
        canceled_at = NULL
    WHERE id = ?
  ");
  $st->execute([(int)$sub['id']]);

  $pdo->commit();
  json_out(['ok' => true, 'auto_renew' => true]);

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  error_log('[SUB RESUME] ' . $e->getMessage());
  json_out(['ok' => false, 'error' => 'server_error'], 500);
}
