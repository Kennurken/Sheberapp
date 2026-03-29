<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

$period = strtolower((string)($_GET['period'] ?? 'week')); // week | month
if (!in_array($period, ['week', 'month'], true)) $period = 'week';

try {
    if ($period === 'week') {
        // Last 7 days, group by day
        $sql = "
            SELECT
                DATE(completed_at) AS day,
                COUNT(*) AS orders_count,
                COALESCE(SUM(price), 0) AS earnings
            FROM orders
            WHERE master_id = ?
              AND status = 'completed'
              AND completed_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
            GROUP BY DATE(completed_at)
            ORDER BY day ASC
        ";
    } else {
        // Last 30 days, group by week
        $sql = "
            SELECT
                DATE(DATE_SUB(completed_at, INTERVAL WEEKDAY(completed_at) DAY)) AS day,
                COUNT(*) AS orders_count,
                COALESCE(SUM(price), 0) AS earnings
            FROM orders
            WHERE master_id = ?
              AND status = 'completed'
              AND completed_at >= DATE_SUB(CURDATE(), INTERVAL 29 DAY)
            GROUP BY DATE(DATE_SUB(completed_at, INTERVAL WEEKDAY(completed_at) DAY))
            ORDER BY day ASC
        ";
    }

    $st = $pdo->prepare($sql);
    $st->execute([$uid]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

    // Fill missing days/weeks with zeros
    $filled = [];
    $days = $period === 'week' ? 7 : 5; // 7 days or 5 weeks
    for ($i = $days - 1; $i >= 0; $i--) {
        $dt = new DateTime();
        if ($period === 'week') {
            $dt->modify("-{$i} day");
            $key = $dt->format('Y-m-d');
        } else {
            // Шагаем назад по 7 дней и выравниваем на начало недели
            $dt->modify('-' . ($i * 7) . ' day');
            $dow = (int)$dt->format('N') - 1; // 0=Пн
            $dt->modify("-{$dow} day");
            $key = $dt->format('Y-m-d');
        }
        $found = null;
        foreach ($rows as $r) {
            if (substr((string)$r['day'], 0, 10) === $key) { $found = $r; break; }
        }
        $filled[] = [
            'day'          => $key,
            'orders_count' => (int)($found['orders_count'] ?? 0),
            'earnings'     => (float)($found['earnings'] ?? 0),
        ];
    }

    // Total stats
    $stTotal = $pdo->prepare("
        SELECT
            COALESCE(SUM(price), 0) AS total_earnings,
            COUNT(*) AS total_orders
        FROM orders
        WHERE master_id = ? AND status = 'completed'
    ");
    $stTotal->execute([$uid]);
    $totals = $stTotal->fetch(PDO::FETCH_ASSOC) ?: [];

    json_out([
        'ok'   => true,
        'data' => [
            'period'         => $period,
            'chart'          => $filled,
            'total_earnings' => (float)($totals['total_earnings'] ?? 0),
            'total_orders'   => (int)($totals['total_orders'] ?? 0),
        ]
    ]);
} catch (Throwable $e) {
    // Graceful empty response if table missing
    json_out([
        'ok'   => true,
        'data' => [
            'period'         => $period,
            'chart'          => [],
            'total_earnings' => 0,
            'total_orders'   => 0,
        ]
    ]);
}