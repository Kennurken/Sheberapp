<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('save_phone', 5, 300);
$user = require_login($pdo);
$uid = (int)$user['id'];

$phone = trim(get_str('phone', 32));

if ($phone === '') {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Normalize phone
$phoneNorm = preg_replace('/[^0-9+]/', '', $phone);
if (!preg_match('/^\+?[0-9]{10,15}$/', $phoneNorm)) {
    json_out(['ok' => false, 'error' => 'invalid_phone'], 422);
}

// Check if phone is taken by another account
try {
    $st = $pdo->prepare("SELECT id FROM users WHERE phone = ? AND id != ? LIMIT 1");
    $st->execute([$phoneNorm, $uid]);
    if ($st->fetch()) {
        json_out(['ok' => false, 'error' => 'phone_taken'], 409);
    }
} catch (Throwable $e) {
    error_log('[save_phone] check: ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

// Save phone
try {
    $pdo->prepare("UPDATE users SET phone = ? WHERE id = ?")->execute([$phoneNorm, $uid]);
} catch (Throwable $e) {
    error_log('[save_phone] update: ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

json_out(['ok' => true]);