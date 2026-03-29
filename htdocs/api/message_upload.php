<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('message_upload', 20, 60);   // 20 images/minute per session
$user    = require_login($pdo);
$uid     = (int)$user['id'];
$orderId = get_int('order_id', 0);

if ($orderId <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Verify the user is a participant in this order
$st = $pdo->prepare("SELECT client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
$st->execute([$orderId]);
$order = $st->fetch();
if (!$order) {
    json_out(['ok' => false, 'error' => 'not_found'], 404);
}
$clientId = (int)($order['client_id'] ?? 0);
$masterId = (int)($order['master_id'] ?? 0);
if ($clientId !== $uid && $masterId !== $uid) {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

$status = (string)($order['status'] ?? '');
if ($uid === $clientId && $status === 'new' && $masterId <= 0) {
    json_out(['ok' => false, 'error' => 'chat_locked'], 409);
}

require_once __DIR__ . '/order_chat_gate.php';
if (order_chat_closed_perfect_review($pdo, $orderId, $status)) {
    json_out(['ok' => false, 'error' => 'chat_closed_perfect'], 409);
}

// Validate upload
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    json_out(['ok' => false, 'error' => 'upload_failed'], 400);
}
$file = $_FILES['file'];
$ext  = strtolower(pathinfo((string)$file['name'], PATHINFO_EXTENSION));
$allowedExt  = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
$allowedMime = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

if (!in_array($ext, $allowedExt, true)) {
    json_out(['ok' => false, 'error' => 'invalid_format'], 400);
}
$mime = upload_mime_type((string)($file['tmp_name'] ?? ''));
if (!in_array($mime, $allowedMime, true)) {
    json_out(['ok' => false, 'error' => 'invalid_format'], 400);
}
// 10 MB max per image
if ((int)$file['size'] > 10 * 1024 * 1024) {
    json_out(['ok' => false, 'error' => 'file_too_large'], 400);
}

// Save file
$uploadDir = __DIR__ . '/../uploads/chat/';
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0777, true);
}
$filename = 'msg_' . $orderId . '_' . $uid . '_' . time() . '.' . $ext;
$dest     = $uploadDir . $filename;
if (!move_uploaded_file((string)$file['tmp_name'], $dest)) {
    json_out(['ok' => false, 'error' => 'move_failed'], 500);
}
$fileUrl = 'uploads/chat/' . $filename;

// Ensure msg_type and file_url columns exist
try {
    $pdo->query("SELECT msg_type FROM order_messages LIMIT 1");
} catch (\PDOException $e) {
    try {
        $pdo->exec("ALTER TABLE order_messages
            ADD COLUMN msg_type VARCHAR(16) NOT NULL DEFAULT 'text',
            ADD COLUMN file_url VARCHAR(255) NULL DEFAULT NULL");
    } catch (\Throwable $ex) {}
}

// Insert image message
$inserted = false;
foreach ([
    ["INSERT INTO order_messages (order_id, sender_id, message, msg_type, file_url, is_system, is_read, created_at) VALUES (?, ?, ?, 'image', ?, 0, 0, NOW())", [$orderId, $uid, '📷 Фото', $fileUrl]],
    ["INSERT INTO order_messages (order_id, sender_id, message, msg_type, file_url, is_system, created_at) VALUES (?, ?, ?, 'image', ?, 0, NOW())", [$orderId, $uid, '📷 Фото', $fileUrl]],
    ["INSERT INTO order_messages (order_id, sender_id, message, created_at) VALUES (?, ?, ?, NOW())", [$orderId, $uid, '📷 ' . $fileUrl]],
] as [$sql, $params]) {
    try {
        $st = $pdo->prepare($sql);
        $st->execute($params);
        if ((int)$pdo->lastInsertId() > 0) { $inserted = true; break; }
    } catch (\Throwable $e) {}
}

if (!$inserted) {
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

// Keep order timestamp fresh
try {
    $pdo->prepare("UPDATE orders SET updated_at = NOW() WHERE id = ?")->execute([$orderId]);
} catch (\Throwable $e) {}

json_out(['ok' => true, 'data' => ['file_url' => $fileUrl]]);
