<?php
/**
 * api_proxy.php — универсальный прокси для api/ папки.
 * Лежит в корне htdocs/, принимает запросы от JS и
 * подключает нужный файл из api/ напрямую (без HTTP редиректа).
 *
 * Использование: api_proxy.php?endpoint=csrf.php
 *                api_proxy.php?endpoint=master_stats.php
 */
declare(strict_types=1);

// Белый список разрешённых эндпоинтов
const ALLOWED = [
    'csrf.php',
    'master_stats.php',
    'master_status_toggle.php',
    'master_earnings_chart.php',
    'orders_feed.php',
    'orders_accept.php',
    'order_get.php',
    'order_finish.php',
    'messages_list.php',
    'messages_send.php',
    'messages_read.php',
    'profile_update.php',
    'avatar_upload.php',
    'reviews_list.php',
    'role_switch.php',
    'subscription_status.php',
    'subscription_buy.php',
    'subscription_cancel.php',
    'subscription_resume.php',
    'push_poll.php',
    'push_subscribe.php',
    'portfolio_photos.php',
    'payment_history.php',
    'ping.php',
    'save_phone.php',
];

$endpoint = basename((string)($_GET['endpoint'] ?? ''));

if (!$endpoint || !in_array($endpoint, ALLOWED, true)) {
    http_response_code(404);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['ok' => false, 'error' => 'not_found']);
    exit;
}

$file = __DIR__ . '/api/' . $endpoint;
if (!file_exists($file)) {
    http_response_code(404);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['ok' => false, 'error' => 'endpoint_missing']);
    exit;
}

// Подключаем файл напрямую — он сам отдаст JSON
require $file;