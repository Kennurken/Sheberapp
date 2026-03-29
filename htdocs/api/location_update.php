<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('location_update', 60, 60); // 60 updates/min

$user = require_login($pdo);
$uid  = (int)$user['id'];

if ((string)($user['role'] ?? '') !== 'master') {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

$lat = (float)get_str('lat', 20);
$lng = (float)get_str('lng', 20);

if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180 || ($lat == 0 && $lng == 0)) {
    json_out(['ok' => false, 'error' => 'invalid_coords'], 422);
}

// Ensure columns exist
try { $pdo->exec("ALTER TABLE users ADD COLUMN last_lat DOUBLE DEFAULT NULL"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN last_lng DOUBLE DEFAULT NULL"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN location_updated_at DATETIME DEFAULT NULL"); } catch (Throwable $e) {}

try {
    $pdo->prepare(
        "UPDATE users SET last_lat = ?, last_lng = ?, location_updated_at = NOW(), last_seen = NOW() WHERE id = ?"
    )->execute([$lat, $lng, $uid]);

    json_out(['ok' => true]);
} catch (Throwable $e) {
    error_log('[location_update] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
