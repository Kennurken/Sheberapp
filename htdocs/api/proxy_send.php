<?php
// Отключаем вывод системных ошибок PHP
error_reporting(0);
ini_set('display_errors', 0);
header('Content-Type: application/json; charset=utf-8');

$phone = $_POST['phone'] ?? '';
$code = $_POST['code'] ?? '';
$action = $_POST['action'] ?? 'send';

if (!$phone) {
    echo json_encode(['ok' => false, 'error' => 'no_phone']);
    exit;
}

$targetUrl = ($action === 'verify')
    ? 'https://usta-auth.vercel.app/api/verify'
    : 'https://usta-auth.vercel.app/api/send';

$payloadData = ['phone' => $phone];
if ($action === 'verify') {
    $payloadData['code'] = $code;
}
$jsonData = json_encode($payloadData);

$ch = curl_init($targetUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $jsonData);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen($jsonData)
]);

$response = curl_exec($ch);
curl_close($ch);

// ВАЖНО: Мы больше не ставим http_response_code($httpCode)! 
// Просто выплевываем то, что вернул Vercel.
if ($response) {
    echo $response;
} else {
    echo json_encode(['ok' => false, 'error' => 'empty_response_from_vercel']);
}