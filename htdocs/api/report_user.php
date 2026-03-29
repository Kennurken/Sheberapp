<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('report_user', 5, 300); // max 5 reports per 5 minutes

$user       = require_login($pdo);
$uid        = (int)$user['id'];
$reportedId = get_int('reported_id', 0);
$reason     = trim(get_str('reason', 120));

if ($reportedId <= 0 || $reason === '') {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}
if ($reportedId === $uid) {
    json_out(['ok' => false, 'error' => 'self_report'], 422);
}

// Ensure table exists
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS user_reports (
        id              INT AUTO_INCREMENT PRIMARY KEY,
        from_user_id    INT NOT NULL,
        against_user_id INT NOT NULL,
        reason          VARCHAR(120) NOT NULL,
        created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_against (against_user_id),
        KEY idx_from    (from_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

try {
    $pdo->prepare(
        "INSERT INTO user_reports (from_user_id, against_user_id, reason) VALUES (?, ?, ?)"
    )->execute([$uid, $reportedId, $reason]);
} catch (Throwable $e) {
    error_log('[report_user] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

json_out(['ok' => true]);
