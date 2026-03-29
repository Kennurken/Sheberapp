<?php
declare(strict_types=1);
require __DIR__ . '/../init.php';

// BUG FIX: CSRF endpoint - возвращает токен из сессии.
// Используется как fallback если мета-тег недоступен (SPA навигация).
header('Content-Type: application/json; charset=utf-8');

echo json_encode([
    'ok'   => true,
    'data' => ['csrf_token' => csrf_token()],
], JSON_UNESCAPED_UNICODE);