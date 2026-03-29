<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('portfolio_upload', 10, 60);

$user = require_login($pdo);
$uid  = (int)$user['id'];

if ((string)($user['role'] ?? '') !== 'master') {
    json_out(['ok' => false, 'error' => 'forbidden'], 403);
}

// Ensure table exists
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS master_portfolio (
        id INT AUTO_INCREMENT PRIMARY KEY,
        master_id INT NOT NULL,
        photo_url VARCHAR(255) NOT NULL,
        description VARCHAR(500) DEFAULT '',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        KEY idx_master (master_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

$description = get_str('description', 500);

if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
    json_out(['ok' => false, 'error' => 'upload_failed'], 400);
}

$file = $_FILES['photo'];
$mime = upload_mime_type((string)$file['tmp_name']);
$allowedMime = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mime, $allowedMime, true)) {
    json_out(['ok' => false, 'error' => 'invalid_format'], 400);
}
if ((int)$file['size'] > 10 * 1024 * 1024) {
    json_out(['ok' => false, 'error' => 'file_too_large'], 400);
}

// Check portfolio limit (max 20 photos)
$st = $pdo->prepare("SELECT COUNT(*) FROM master_portfolio WHERE master_id = ?");
$st->execute([$uid]);
if ((int)$st->fetchColumn() >= 20) {
    json_out(['ok' => false, 'error' => 'portfolio_limit'], 400);
}

$ext = $mime === 'image/png' ? 'png' : ($mime === 'image/webp' ? 'webp' : 'jpg');
$uploadDir = __DIR__ . '/../uploads/portfolio/';
if (!is_dir($uploadDir)) @mkdir($uploadDir, 0777, true);

$filename = 'portfolio_' . $uid . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
$dest = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $dest)) {
    json_out(['ok' => false, 'error' => 'move_failed'], 500);
}

$photoUrl = 'uploads/portfolio/' . $filename;

try {
    $pdo->prepare(
        "INSERT INTO master_portfolio (master_id, photo_url, description) VALUES (?, ?, ?)"
    )->execute([$uid, $photoUrl, $description]);

    $id = (int)$pdo->lastInsertId();
    json_out(['ok' => true, 'data' => ['id' => $id, 'photo_url' => $photoUrl]]);
} catch (Throwable $e) {
    error_log('[portfolio_upload] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
