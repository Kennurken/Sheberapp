<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
$uid = (int)$user['id'];
require_role($user, 'client');

$orderId = get_int('order_id', 0);
$rating  = get_int('rating', 0);
$body    = str_clip((string)($_POST['body'] ?? ''), 1000);

if ($orderId <= 0 || $rating < 1 || $rating > 5) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Ensure photo column exists
try {
    $pdo->exec("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS photo_url VARCHAR(512) NOT NULL DEFAULT ''");
} catch (Throwable) {}

try {
    $st = $pdo->prepare("SELECT id, client_id, master_id, status FROM orders WHERE id = ? LIMIT 1");
    $st->execute([$orderId]);
    $o = $st->fetch();
    if (!$o) json_out(['ok' => false, 'error' => 'not_found'], 404);

    if ((int)$o['client_id'] !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);
    if ((string)$o['status'] !== 'completed') json_out(['ok' => false, 'error' => 'not_completed'], 409);

    $mid = (int)($o['master_id'] ?? 0);
    if ($mid <= 0) json_out(['ok' => false, 'error' => 'no_master'], 409);

    // Prevent duplicates
    $st = $pdo->prepare("SELECT id FROM reviews WHERE order_id = ? LIMIT 1");
    $st->execute([$orderId]);
    if ($st->fetch()) json_out(['ok' => false, 'error' => 'exists'], 409);

    // Handle photo upload
    $photoUrl = '';
    $file = $_FILES['photo'] ?? null;
    if ($file && ($file['error'] ?? 1) === UPLOAD_ERR_OK) {
        $size = (int)($file['size'] ?? 0);
        if ($size > 8 * 1024 * 1024) json_out(['ok' => false, 'error' => 'photo_too_large'], 400);
        $mime = upload_mime_type((string)$file['tmp_name']);
        if (!in_array($mime, ['image/jpeg','image/png','image/webp'], true)) {
            json_out(['ok' => false, 'error' => 'invalid_photo_type'], 400);
        }
        $ext = match($mime) { 'image/png'=>'png','image/webp'=>'webp', default=>'jpg' };
        $dir = __DIR__ . '/../uploads/reviews/';
        if (!is_dir($dir)) mkdir($dir, 0755, true);
        $fname = 'r_' . $uid . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
        if (move_uploaded_file($file['tmp_name'], $dir . $fname)) {
            $photoUrl = '/uploads/reviews/' . $fname;
        }
    }

    $st = $pdo->prepare("
        INSERT INTO reviews (order_id, master_id, client_id, rating, comment, photo_url, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");
    $st->execute([$orderId, $mid, $uid, $rating, ($body === '' ? null : $body), $photoUrl]);

    // System message in chat
    try {
        $pdo->prepare("INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, ?, ?, 1, NOW())")
            ->execute([$orderId, $uid, 'Клиент оставил отзыв ⭐' . str_repeat('★', $rating)]);
    } catch (Throwable) {}

    json_out(['ok' => true, 'data' => ['saved' => true, 'photo_url' => $photoUrl]]);

} catch (Throwable $e) {
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}