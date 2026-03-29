<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('role_switch', 5, 300);
$user = require_login($pdo);

$targetRole = (string)($_POST['target_role'] ?? '');
$profession = trim((string)($_POST['profession'] ?? ''));

if ($targetRole !== 'client' && $targetRole !== 'master') {
    json_out(['ok' => false, 'error' => 'invalid_role'], 400);
}

if ($user['role'] === $targetRole && $profession === '') {
    json_out(['ok' => true]); // Already in that role
}

$uid = (int)$user['id'];

try {
    if ($targetRole === 'master' && $profession !== '') {
        $st = $pdo->prepare('UPDATE users SET role = ?, profession = ? WHERE id = ?');
        $st->execute([$targetRole, mb_substr($profession, 0, 120), $uid]);
    } else {
        $st = $pdo->prepare('UPDATE users SET role = ? WHERE id = ?');
        $st->execute([$targetRole, $uid]);
    }

    // Обновляем сессию при необходимости
    $_SESSION['role'] = $targetRole;

    // Auto-trial: give 30-day free Premium to brand-new masters (only once ever)
    if ($targetRole === 'master') {
        try {
            $st = $pdo->prepare('SELECT COUNT(*) FROM master_subscriptions WHERE master_id = ?');
            $st->execute([$uid]);
            $hasHadSub = (int)$st->fetchColumn() > 0;

            if (!$hasHadSub) {
                // Use the cheapest available plan; fallback to plan_id=1
                $planId = 1;
                try {
                    $st2 = $pdo->query('SELECT MIN(id) FROM subscription_plans');
                    $minPlan = $st2->fetchColumn();
                    if ($minPlan) $planId = (int)$minPlan;
                } catch (Throwable $e) {}

                $endsAt = (new DateTimeImmutable('now'))->modify('+30 days');
                $pdo->prepare("
                    INSERT INTO master_subscriptions
                        (master_id, plan_id, starts_at, ends_at, status, auto_renew, cancel_at_period_end)
                    VALUES (?, ?, NOW(), ?, 'active', 0, 0)
                ")->execute([$uid, $planId, $endsAt->format('Y-m-d H:i:s')]);

                $pdo->prepare('UPDATE users SET is_subscribed = 1 WHERE id = ?')->execute([$uid]);
            }
        } catch (Throwable $e) {
            error_log('[ROLE SWITCH TRIAL] ' . $e->getMessage());
            // Non-fatal: role switch succeeds even if trial insert fails
        }
    }

    json_out(['ok' => true]);
} catch (Throwable $e) {
    error_log('[ROLE SWITCH] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
