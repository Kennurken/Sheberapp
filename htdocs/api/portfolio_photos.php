<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

$user = require_login($pdo);
require_role($user, 'master');
$uid = (int)$user['id'];

$method = strtoupper((string)($_SERVER['REQUEST_METHOD'] ?? 'GET'));

// ── Ensure portfolio_photos table exists ──────────────────────────────────────
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS portfolio_photos (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            master_id   INT NOT NULL,
            file_path   VARCHAR(512) NOT NULL,
            caption     VARCHAR(255) NOT NULL DEFAULT '',
            created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_master (master_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
} catch (Throwable) {}

// ── GET: list ─────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $st = $pdo->prepare('SELECT id, file_path, caption, created_at FROM portfolio_photos WHERE master_id = ? ORDER BY id DESC LIMIT 20');
    $st->execute([$uid]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
    $out = array_map(fn($r) => [
        'id'         => (int)$r['id'],
        'url'        => '/' . ltrim((string)$r['file_path'], '/'),
        'caption'    => (string)$r['caption'],
        'created_at' => (string)$r['created_at'],
    ], $rows);
    json_out(['ok' => true, 'data' => $out]);
}

// ── POST: upload ──────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $tok = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ($_POST['csrf_token'] ?? ''));
    if (!csrf_check($tok)) json_out(['ok' => false, 'error' => 'csrf'], 419);

    // Check limit (max 12 portfolio photos)
    $stC = $pdo->prepare('SELECT COUNT(*) FROM portfolio_photos WHERE master_id = ?');
    $stC->execute([$uid]);
    $count = (int)$stC->fetchColumn();
    if ($count >= 12) json_out(['ok' => false, 'error' => 'limit_reached'], 429);

    $file = $_FILES['photo'] ?? null;
    if (!$file || ($file['error'] ?? 1) !== UPLOAD_ERR_OK) {
        json_out(['ok' => false, 'error' => 'no_file'], 400);
    }

    $size = (int)($file['size'] ?? 0);
    if ($size > 8 * 1024 * 1024) json_out(['ok' => false, 'error' => 'file_too_large'], 400);

    $mime = upload_mime_type((string)$file['tmp_name']);
    $allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if (!in_array($mime, $allowed, true)) json_out(['ok' => false, 'error' => 'invalid_type'], 400);

    $ext  = match($mime) { 'image/png' => 'png', 'image/webp' => 'webp', default => 'jpg' };
    $dir  = __DIR__ . '/../uploads/portfolio/';
    if (!is_dir($dir)) mkdir($dir, 0755, true);
    $name = 'p_' . $uid . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
    $dest = $dir . $name;

    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        json_out(['ok' => false, 'error' => 'upload_failed'], 500);
    }

    $caption = trim((string)($_POST['caption'] ?? ''));
    if (mb_strlen($caption) > 255) $caption = mb_substr($caption, 0, 255);

    $filePath = 'uploads/portfolio/' . $name;
    $st = $pdo->prepare('INSERT INTO portfolio_photos (master_id, file_path, caption) VALUES (?, ?, ?)');
    $st->execute([$uid, $filePath, $caption]);
    $newId = (int)$pdo->lastInsertId();

    json_out(['ok' => true, 'data' => ['id' => $newId, 'url' => '/' . $filePath, 'caption' => $caption]]);
}

// ── DELETE ────────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    $tok = (string)($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    if (!csrf_check($tok)) json_out(['ok' => false, 'error' => 'csrf'], 419);

    parse_str(file_get_contents('php://input'), $body);
    $photoId = (int)($body['photo_id'] ?? 0);
    if ($photoId <= 0) json_out(['ok' => false, 'error' => 'photo_id_required'], 400);

    $st = $pdo->prepare('SELECT file_path FROM portfolio_photos WHERE id = ? AND master_id = ? LIMIT 1');
    $st->execute([$photoId, $uid]);
    $row = $st->fetch();
    if (!$row) json_out(['ok' => false, 'error' => 'not_found'], 404);

    $fullPath = __DIR__ . '/' . ltrim((string)$row['file_path'], '/');
    if (file_exists($fullPath)) @unlink($fullPath);

    $pdo->prepare('DELETE FROM portfolio_photos WHERE id = ? AND master_id = ?')->execute([$photoId, $uid]);
    json_out(['ok' => true]);
}

json_out(['ok' => false, 'error' => 'method_not_allowed'], 405);