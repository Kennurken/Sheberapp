<?php
declare(strict_types=1);
/**
 * Telegram polling — called via URL cron from Beget CronTab.
 * Cron command: curl -s "http://kmaruk4u.beget.tech/api/support_tg_poll.php?key=sheber2025"
 */

require __DIR__ . '/_boot.php';

// Simple secret key check (no login required — called by cron)
$key = (string)($_GET['key'] ?? '');
$expectedKey = defined('TELEGRAM_BOT_TOKEN') ? md5(TELEGRAM_BOT_TOKEN . '_poll') : 'sheber2025';
if (!hash_equals($expectedKey, $key)) {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

$botToken = defined('TELEGRAM_BOT_TOKEN') ? TELEGRAM_BOT_TOKEN : '';
if ($botToken === '' || $botToken === 'YOUR_BOT_TOKEN_HERE') {
    json_out(['ok' => false, 'error' => 'no_token'], 500);
}

// Store offset in a writable location
$offsetFile = sys_get_temp_dir() . '/sheber_tg_' . md5(__FILE__) . '.txt';
$offset = file_exists($offsetFile) ? (int)file_get_contents($offsetFile) : 0;

// Fetch updates from Telegram
$ch = curl_init("https://api.telegram.org/bot{$botToken}/getUpdates");
curl_setopt_array($ch, [
    CURLOPT_POST           => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 8,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_POSTFIELDS     => http_build_query(['offset' => $offset, 'limit' => 20, 'timeout' => 0]),
]);
$raw = curl_exec($ch);
curl_close($ch);

$data = $raw ? json_decode($raw, true) : null;
if (!isset($data['ok']) || !$data['ok']) {
    json_out(['ok' => false, 'error' => 'tg_api_failed']);
}

$updates    = $data['result'] ?? [];
$lastId     = $offset;
$processed  = 0;

foreach ($updates as $update) {
    $uid = (int)($update['update_id'] ?? 0);
    if ($uid >= $lastId) $lastId = $uid + 1;

    $text = (string)($update['message']['text'] ?? '');
    if (!preg_match('/^\/reply\s+(\d+)\s+(.+)$/su', $text, $m)) continue;

    $targetUid = (int)$m[1];
    $replyText = trim((string)$m[2]);
    if ($targetUid <= 0 || $replyText === '') continue;

    try {
        $pdo->prepare("INSERT INTO support_messages (user_id, direction, message) VALUES (?, 'out', ?)")
            ->execute([$targetUid, $replyText]);
        $processed++;
    } catch (Throwable $e) {
        error_log('[tg_poll] ' . $e->getMessage());
    }
}

@file_put_contents($offsetFile, (string)$lastId);
json_out(['ok' => true, 'processed' => $processed, 'next_offset' => $lastId]);
