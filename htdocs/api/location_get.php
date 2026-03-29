<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid  = (int)$user['id'];

$masterId = get_int('master_id', 0);
$orderId  = get_int('order_id', 0);

if ($masterId <= 0 && $orderId <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// If master_id provided directly, verify the user has an active order with this master
if ($orderId <= 0 && $masterId > 0) {
    $stAuth = $pdo->prepare("SELECT id FROM orders WHERE master_id = ? AND client_id = ? AND status IN ('in_progress','completed') LIMIT 1");
    $stAuth->execute([$masterId, $uid]);
    if (!$stAuth->fetch()) {
        json_out(['ok' => false, 'error' => 'forbidden'], 403);
    }
}

// If order_id provided, resolve master_id from order
if ($orderId > 0) {
    $st = $pdo->prepare("SELECT client_id, master_id FROM orders WHERE id = ? LIMIT 1");
    $st->execute([$orderId]);
    $order = $st->fetch();
    if (!$order) json_out(['ok' => false, 'error' => 'not_found'], 404);

    // Only participants can track
    if ((int)$order['client_id'] !== $uid && (int)($order['master_id'] ?? 0) !== $uid) {
        json_out(['ok' => false, 'error' => 'forbidden'], 403);
    }
    $masterId = (int)($order['master_id'] ?? 0);
    if ($masterId <= 0) {
        json_out(['ok' => false, 'error' => 'no_master'], 404);
    }
}

// Ensure columns exist
try { $pdo->exec("ALTER TABLE users ADD COLUMN last_lat DOUBLE DEFAULT NULL"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN last_lng DOUBLE DEFAULT NULL"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN location_updated_at DATETIME DEFAULT NULL"); } catch (Throwable $e) {}

try {
    $st = $pdo->prepare(
        "SELECT last_lat, last_lng, location_updated_at, last_seen,
                COALESCE(name, 'Шебер') AS name
         FROM users WHERE id = ? AND role = 'master' LIMIT 1"
    );
    $st->execute([$masterId]);
    $master = $st->fetch(PDO::FETCH_ASSOC);

    if (!$master) {
        json_out(['ok' => false, 'error' => 'not_found'], 404);
    }

    $lat = $master['last_lat'] !== null ? (float)$master['last_lat'] : null;
    $lng = $master['last_lng'] !== null ? (float)$master['last_lng'] : null;
    $updatedAt = $master['location_updated_at'];

    // Check if location is fresh (within 10 minutes)
    $isFresh = false;
    if ($updatedAt) {
        $ts = strtotime((string) $updatedAt);
        $isFresh = (bool) $ts && (time() - $ts) <= 600;
    }

    $seenRaw = $master['last_seen'] ?? null;
    $seenTs = $seenRaw ? strtotime((string) $seenRaw) : false;
    $isOnline = $seenTs && (time() - (int) $seenTs) <= 120;

    json_out(['ok' => true, 'data' => [
        'master_id'   => $masterId,
        'name'        => $master['name'],
        'lat'         => $lat,
        'lng'         => $lng,
        'updated_at'  => $updatedAt,
        'is_fresh'    => $isFresh,
        'is_online'   => $isOnline,
    ]]);
} catch (Throwable $e) {
    error_log('[location_get] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
