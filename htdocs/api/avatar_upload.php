<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
$uid  = (int)$user['id'];

// Check if avatar_url column exists, if not add it
try {
    $pdo->query("SELECT avatar_url FROM users LIMIT 1");
} catch (\PDOException $e) {
    // Column doesn't exist, let's create it
    try {
        $pdo->exec("ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255) NULL DEFAULT NULL");
    } catch (\Throwable $ex) {
        // Ignore if error, maybe someone else created it
    }
}

// Ensure avatar_color column exists too (used across UI)
try {
    $pdo->query("SELECT avatar_color FROM users LIMIT 1");
} catch (\PDOException $e) {
    try {
        $pdo->exec("ALTER TABLE users ADD COLUMN avatar_color VARCHAR(32) NULL DEFAULT '#1cb7ff'");
    } catch (\Throwable $ex) {
        // ignore
    }
}

if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
    json_out(['ok' => false, 'error' => 'upload_failed'], 400);
}

$file = $_FILES['avatar'];
$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

$allowed = ['jpg','jpeg','png','gif','webp'];
if (!in_array($ext, $allowed)) {
    json_out(['ok' => false, 'error' => 'invalid_format'], 400);
}

// Validate MIME type (not just extension)
$mime = upload_mime_type((string)($file['tmp_name'] ?? ''));
$allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
if (!in_array($mime, $allowedMimes, true)) {
    json_out(['ok' => false, 'error' => 'invalid_format'], 400);
}

// 5 MB max
if ($file['size'] > 5 * 1024 * 1024) {
    json_out(['ok' => false, 'error' => 'file_too_large'], 400);
}

$uploadDir = __DIR__ . '/../uploads/avatars/';
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0777, true);
} // We already made the dir but just in case

$filename = 'user_' . $uid . '_' . time() . '.' . $ext;
$dest = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $dest)) {
    json_out(['ok' => false, 'error' => 'move_failed'], 500);
}

// Generate public URL assuming uploads/ is reachable
$webPath = 'uploads/avatars/' . $filename;

try {
    $st = $pdo->prepare("UPDATE users SET avatar_url = ?, updated_at = NOW() WHERE id = ?");
    $st->execute([$webPath, $uid]);
} catch (\Throwable $e) {
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}

// Return updated user data (including new avatar_url)
try {
    $st = $pdo->prepare("
        SELECT id, name, email, role, city,
               COALESCE(profession, '')   AS profession,
               COALESCE(bio, '')          AS bio,
               COALESCE(phone, '')        AS phone,
               COALESCE(experience, 0)    AS experience,
               COALESCE(avatar_color, '#1cb7ff') AS avatar_color,
               avatar_url
        FROM users WHERE id = ? LIMIT 1
    ");
    $st->execute([$uid]);
    $updated = $st->fetch(PDO::FETCH_ASSOC) ?: [];
} catch (\Throwable $e) {
    $updated = ['id' => $uid, 'avatar_url' => $webPath];
}

// Add subscription info (same pattern as email_auth / mobile_auth)
$subscription  = 'free';
$subExpiresAt  = null;
$subIsTrial    = false;
if ((string)($updated['role'] ?? '') === 'master') {
    try {
        $stSub = $pdo->prepare(
            "SELECT ends_at, auto_renew FROM master_subscriptions
              WHERE master_id = ? AND status = 'active' AND ends_at > NOW()
              ORDER BY ends_at DESC LIMIT 1"
        );
        $stSub->execute([$uid]);
        $sub = $stSub->fetch(PDO::FETCH_ASSOC);
        if ($sub) {
            $subscription = 'premium';
            $subExpiresAt = (string)$sub['ends_at'];
            $subIsTrial   = (int)($sub['auto_renew'] ?? 1) === 0;
        }
    } catch (Throwable $e) {}
}
$updated['subscription']            = $subscription;
$updated['subscription_expires_at'] = $subExpiresAt;
$updated['subscription_is_trial']   = $subIsTrial;

json_out(['ok' => true, 'data' => $updated]);
