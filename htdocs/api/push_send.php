<?php
declare(strict_types=1);
/**
 * FCM Push Notification Helper (NOT a public endpoint — include-only)
 *
 * Usage:
 *   require_once __DIR__ . '/push_send.php';
 *   push_notify_user($pdo, $userId, 'Заголовок', 'Текст уведомления', ['order_id' => 42]);
 *   push_notify_users($pdo, [1, 2, 3], 'Заголовок', 'Текст', $data);
 *
 * Requires FCM_SERVICE_ACCOUNT_PATH defined in config.local.php — path to
 * the Firebase service account JSON file (keep it OUTSIDE public_html!).
 *
 * Also inserts a row into push_notifications for in-app polling fallback.
 */

if (!function_exists('push_notify_user')) {

/**
 * Send push notification to a single user (all their devices).
 */
function push_notify_user(
    PDO    $pdo,
    int    $userId,
    string $title,
    string $body,
    array  $data = [],
    string $url  = ''
): void {
    push_notify_users($pdo, [$userId], $title, $body, $data, $url);
}

/**
 * Send push notification to multiple users (all their devices).
 */
function push_notify_users(
    PDO    $pdo,
    array  $userIds,
    string $title,
    string $body,
    array  $data = [],
    string $url  = ''
): void {
    if (empty($userIds)) return;

    // ── 1. In-app polling fallback (push_notifications table) ──────────────
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS push_notifications (
                id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
                user_id    INT          NOT NULL,
                title      VARCHAR(255) NOT NULL DEFAULT '',
                body       TEXT,
                url        VARCHAR(512) NOT NULL DEFAULT '',
                is_sent    TINYINT(1)   NOT NULL DEFAULT 0,
                created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                KEY idx_user_unsent (user_id, is_sent)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ");
    } catch (Throwable $e) {}

    try {
        $ins = $pdo->prepare("
            INSERT INTO push_notifications (user_id, title, body, url)
            VALUES (?, ?, ?, ?)
        ");
        foreach ($userIds as $uid) {
            $ins->execute([(int)$uid, $title, $body, $url]);
        }
    } catch (Throwable $e) {
        error_log('[push_send] in-app insert: ' . $e->getMessage());
    }

    // ── 2. Real FCM push via HTTP V1 API ────────────────────────────────────
    $saPath = defined('FCM_SERVICE_ACCOUNT_PATH') ? FCM_SERVICE_ACCOUNT_PATH : '';
    if ($saPath === '' || !file_exists($saPath)) {
        // Service account not configured yet — in-app polling only
        return;
    }

    $serviceAccount = json_decode((string)file_get_contents($saPath), true);
    if (empty($serviceAccount['project_id'])) {
        error_log('[push_send] Invalid service account JSON at: ' . $saPath);
        return;
    }

    // Collect all FCM tokens for these users
    $tokens = [];
    try {
        $placeholders = implode(',', array_fill(0, count($userIds), '?'));
        $st = $pdo->prepare("
            SELECT token FROM fcm_tokens
            WHERE user_id IN ($placeholders)
        ");
        $st->execute(array_values($userIds));
        $tokens = array_column($st->fetchAll(PDO::FETCH_ASSOC), 'token');
    } catch (Throwable $e) {
        error_log('[push_send] token fetch: ' . $e->getMessage());
        return;
    }

    if (empty($tokens)) return;

    // Get OAuth2 access token (valid 1 hour)
    $accessToken = _fcm_get_access_token($serviceAccount);
    if (!$accessToken) {
        error_log('[push_send] Failed to get FCM access token');
        return;
    }

    // V1 API sends one message per token — loop through all tokens
    foreach ($tokens as $token) {
        _fcm_send_v1($serviceAccount['project_id'], $accessToken, $token, $title, $body, $data);
    }
}

/**
 * Base64url encode (required for JWT).
 */
function _fcm_base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Create a signed JWT and exchange it for a Google OAuth2 access token.
 */
function _fcm_get_access_token(array $sa): ?string {
    $now = time();

    // Build JWT header + payload
    $header  = _fcm_base64url_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $payload = _fcm_base64url_encode(json_encode([
        'iss'   => $sa['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'iat'   => $now,
        'exp'   => $now + 3600,
    ]));

    $signingInput = "$header.$payload";

    // Sign with the private key (RS256)
    $privateKey = openssl_pkey_get_private($sa['private_key']);
    if (!$privateKey) {
        error_log('[push_send] Cannot load private key from service account');
        return null;
    }
    openssl_sign($signingInput, $signature, $privateKey, 'sha256WithRSAEncryption');

    $jwt = "$signingInput." . _fcm_base64url_encode($signature);

    // Exchange JWT for access token
    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_POSTFIELDS     => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        ]),
        CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
    ]);

    $response = json_decode((string)curl_exec($ch), true);
    curl_close($ch);

    return $response['access_token'] ?? null;
}

/**
 * Send one FCM V1 message to a single device token.
 */
function _fcm_send_v1(
    string $projectId,
    string $accessToken,
    string $token,
    string $title,
    string $body,
    array  $data
): void {
    $message = [
        'message' => [
            'token'        => $token,
            'notification' => [
                'title' => $title,
                'body'  => $body,
            ],
            'data'         => array_merge(
                array_map('strval', $data),
                ['click_action' => 'FLUTTER_NOTIFICATION_CLICK']
            ),
            'android'      => [
                'priority'     => 'high',
                'notification' => [
                    'channel_id'  => 'sheber_main',
                    'sound'       => 'default',
                ],
            ],
        ],
    ];

    $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
    $ch  = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_POSTFIELDS     => json_encode($message, JSON_UNESCAPED_UNICODE),
        CURLOPT_HTTPHEADER     => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $accessToken,
        ],
    ]);

    $result   = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        error_log('[push_send] FCM V1 error ' . $httpCode . ': ' . $result);
    }
}

} // end if !function_exists
