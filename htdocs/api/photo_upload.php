<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('photo_upload', 10, 60);

$user = require_login($pdo);
$uid  = (int)$user['id'];

if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
    json_out(['ok' => false, 'error' => 'upload_failed'], 400);
}

$file = $_FILES['photo'];
$mime = upload_mime_type((string)$file['tmp_name']);
$allowedMime = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mime, $allowedMime, true)) {
    json_out(['ok' => false, 'error' => 'invalid_format'], 400);
}
if ((int)$file['size'] > 5 * 1024 * 1024) {
    json_out(['ok' => false, 'error' => 'file_too_large'], 400);
}

$ext = $mime === 'image/png' ? 'png' : ($mime === 'image/webp' ? 'webp' : 'jpg');
$uploadDir = __DIR__ . '/../uploads/photos/';
if (!is_dir($uploadDir)) @mkdir($uploadDir, 0777, true);

$filename = 'photo_' . $uid . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
$dest = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $dest)) {
    json_out(['ok' => false, 'error' => 'move_failed'], 500);
}

$url = 'uploads/photos/' . $filename;
json_out(['ok' => true, 'data' => ['url' => $url]]);
