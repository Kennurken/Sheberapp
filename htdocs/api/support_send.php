<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('support_send', 10, 300);
$user = require_login($pdo);
$uid  = (int)$user['id'];
$text = trim((string)($_POST['message'] ?? ''));

if (strlen($text) < 1 || strlen($text) > 2000) {
    json_out(['ok' => false, 'error' => 'bad_message'], 422);
}

// Ensure support_messages table exists
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS support_messages (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        user_id     INT NOT NULL,
        direction   ENUM('in','out') NOT NULL,
        message     TEXT NOT NULL,
        created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_user_id (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

// Save message to DB
$newId = 0;
try {
    $pdo->prepare("INSERT INTO support_messages (user_id, direction, message) VALUES (?, 'in', ?)")
        ->execute([$uid, $text]);
    $newId = (int)$pdo->lastInsertId();
} catch (Throwable $e) {
    error_log('[support_send] db: ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

// Forward to Telegram
$botToken = trim((string)(defined('TELEGRAM_BOT_TOKEN') ? TELEGRAM_BOT_TOKEN : ''));
$chatId   = trim((string)(defined('TELEGRAM_SUPPORT_CHAT_ID') ? TELEGRAM_SUPPORT_CHAT_ID : ''));

$tokenLooksReal = ($botToken !== '' && strlen($botToken) > 30 && str_contains($botToken, ':'));
// Числовой id (личка / группа / супергруппа) или @username канала/супергруппы (как в Bot API)
$chatLooksReal = false;
if ($chatId !== '') {
    if (preg_match('/^-?\\d+$/', $chatId) === 1) {
        $chatLooksReal = true;
    } elseif (preg_match('/^@[A-Za-z][A-Za-z0-9_]{4,31}$/', $chatId) === 1) {
        $chatLooksReal = true;
    }
}

$tgSkipReason = '';
if ($botToken === '') {
    $tgSkipReason = 'empty_token';
} elseif (str_starts_with($botToken, 'PASTE_') || $botToken === 'YOUR_BOT_TOKEN_HERE') {
    $tgSkipReason = 'placeholder_token';
} elseif (!$tokenLooksReal) {
    $tgSkipReason = 'bad_token_format';
} elseif ($chatId === '' || $chatId === 'YOUR_CHAT_ID_HERE') {
    $tgSkipReason = 'empty_or_placeholder_chat';
} elseif (!$chatLooksReal) {
    $tgSkipReason = 'bad_chat_id_use_numeric_or_at_username';
}

if ($tgSkipReason === '' &&
    $tokenLooksReal && $chatLooksReal) {

    $userName = htmlspecialchars((string)($user['name'] ?? 'Пользователь'), ENT_XML1);
    $safeText = htmlspecialchars($text, ENT_XML1);
    $tgText   = "📩 <b>Поддержка Sheber.kz</b>\n"
              . "👤 {$userName} (ID: {$uid})\n\n"
              . "{$safeText}\n\n"
              . "<i>Ответить: /reply {$uid} ваш ответ</i>";

    $ch = curl_init("https://api.telegram.org/bot{$botToken}/sendMessage");
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 12,
        CURLOPT_POSTFIELDS     => http_build_query([
            'chat_id'    => $chatId,
            'text'       => $tgText,
            'parse_mode' => 'HTML',
        ]),
    ]);
    $tgBody = curl_exec($ch);
    $tgErr  = curl_error($ch);
    $tgCode = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);

    $tgOk = false;
    $tgDesc = '';
    if ($tgBody !== false) {
        $tgJson = json_decode((string)$tgBody, true);
        if (is_array($tgJson)) {
            $tgOk = !empty($tgJson['ok']);
            $tgDesc = (string)($tgJson['description'] ?? '');
        }
    }
    if (!$tgOk) {
        error_log('[support_send] telegram failed http=' . $tgCode . ' curl=' . $tgErr . ' desc=' . $tgDesc);
    }
} elseif ($tgSkipReason !== '') {
    error_log('[support_send] telegram skipped reason=' . $tgSkipReason . ' (set TELEGRAM_BOT_TOKEN + TELEGRAM_SUPPORT_CHAT_ID in config.local.php; deploy does not overwrite this file)');
}

json_out(['ok' => true, 'data' => ['id' => $newId]]);
