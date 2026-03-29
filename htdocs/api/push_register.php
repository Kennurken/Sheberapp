<?php
declare(strict_types=1);
/**
 * FCM Token Registration
 *
 * Called by Flutter app on every launch to register the device FCM token.
 * POST /api/push_register.php
 *   token    — FCM device token (string, required)
 *   platform — android | ios (default: android)
 *
 * Uses INSERT ... ON DUPLICATE KEY UPDATE to handle token refresh atomically.
 */

require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('push_register', 20, 60);

$user = require_login($pdo);
$uid  = (int)$user['id'];

// Auto-create fcm_tokens table on first use
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS fcm_tokens (
            id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
            user_id    INT          NOT NULL,
            token      TEXT         NOT NULL,
            platform   VARCHAR(16)  NOT NULL DEFAULT 'android',
            created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uq_user_token (user_id, token(200)),
            KEY idx_user_id (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
} catch (Throwable $e) {
    error_log('[push_register] table create: ' . $e->getMessage());
}

// Parse token from POST body or form data
$rawBody = file_get_contents('php://input');
$bodyJson = $rawBody ? (json_decode($rawBody, true) ?? []) : [];

$token    = trim((string)($_POST['token']    ?? $bodyJson['token']    ?? ''));
$platform = trim((string)($_POST['platform'] ?? $bodyJson['platform'] ?? 'android'));
$platform = in_array($platform, ['android', 'ios', 'web'], true) ? $platform : 'android';

if ($token === '') {
    json_out(['ok' => false, 'error' => 'no_token'], 400);
}

// Reject obviously invalid tokens (FCM tokens are typically 152+ chars)
if (strlen($token) < 20 || strlen($token) > 4096) {
    json_out(['ok' => false, 'error' => 'invalid_token'], 400);
}

try {
    $st = $pdo->prepare("
        INSERT INTO fcm_tokens (user_id, token, platform)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            platform   = VALUES(platform),
            updated_at = NOW()
    ");
    $st->execute([$uid, $token, $platform]);
    json_out(['ok' => true]);
} catch (Throwable $e) {
    error_log('[push_register] db: ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
