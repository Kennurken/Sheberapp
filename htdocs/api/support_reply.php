<?php
declare(strict_types=1);

// Telegram webhook endpoint — receives messages from Telegram bot
// Setup once: GET https://api.telegram.org/bot{TOKEN}/setWebhook?url=https://kmaruk4u.beget.tech/api/support_reply.php
//
// How to reply to a user from Telegram:
//   Send: /reply 123 Текст ответа
//   Where 123 = user_id from the support_send notification

$rawBody = file_get_contents('php://input');
if (empty($rawBody)) { http_response_code(200); exit; }

$update = json_decode($rawBody, true);
if (!is_array($update)) { http_response_code(200); exit; }

// Verify request comes from Telegram — check sender chat_id matches our support chat
$configPath = __DIR__ . '/../config.local.php';
if (!file_exists($configPath)) { http_response_code(200); exit; }
$cfg = require $configPath;
$allowedChatId = (string)($cfg['TELEGRAM_SUPPORT_CHAT_ID'] ?? '');
$fromChatId = (string)($update['message']['chat']['id'] ?? '');
if ($allowedChatId === '' || $fromChatId !== $allowedChatId) {
    error_log('[support_reply] unauthorized chat_id: ' . $fromChatId);
    http_response_code(200);
    exit;
}

$text = (string)($update['message']['text'] ?? '');

// Expect: /reply {user_id} {message text}
if (!preg_match('/^\/reply\s+(\d+)\s+(.+)$/su', $text, $m)) {
    http_response_code(200);
    exit;
}

$targetUid = (int)$m[1];
$replyText = trim((string)$m[2]);

if ($targetUid <= 0 || $replyText === '') {
    http_response_code(200);
    exit;
}

// Load DB config and save reply
$configPath = __DIR__ . '/../config.local.php';
if (!file_exists($configPath)) { http_response_code(200); exit; }

try {
    $cfg = require $configPath;
    $dsn = 'mysql:host=' . ($cfg['DB_HOST'] ?? 'localhost')
         . ';dbname=' . ($cfg['DB_NAME'] ?? '')
         . ';charset=utf8mb4';
    $pdo = new PDO($dsn, $cfg['DB_USER'] ?? '', $cfg['DB_PASS'] ?? '', [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    $pdo->exec("CREATE TABLE IF NOT EXISTS support_messages (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        user_id     INT NOT NULL,
        direction   ENUM('in','out') NOT NULL,
        message     TEXT NOT NULL,
        created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_user_id (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $pdo->prepare("INSERT INTO support_messages (user_id, direction, message) VALUES (?, 'out', ?)")
        ->execute([$targetUid, $replyText]);

} catch (Throwable $e) {
    error_log('[support_reply] ' . $e->getMessage());
}

http_response_code(200);
echo 'ok';
