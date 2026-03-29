<?php
declare(strict_types=1);
/**
 * api/profile_update.php  — обновление профиля пользователя
 */

require __DIR__ . '/_boot.php';

require_method('POST');
$user = require_login($pdo);
$uid  = (int)$user['id'];

/* ── читаем текущие данные пользователя (для partial update) ── */
$stCur = $pdo->prepare("SELECT name, city, profession, bio, phone, experience, avatar_color FROM users WHERE id = ? LIMIT 1");
$stCur->execute([$uid]);
$cur = $stCur->fetch(PDO::FETCH_ASSOC) ?: [];

/* ── читаем поля (partial update: если не передано — берём из БД) */
$name               = isset($_POST['name'])        ? str_clip((string)$_POST['name'], 80)        : (string)($cur['name'] ?? '');
$city               = isset($_POST['city'])         ? str_clip((string)$_POST['city'], 80)        : (string)($cur['city'] ?? '');
$profession         = isset($_POST['profession'])   ? str_clip((string)$_POST['profession'], 120) : (string)($cur['profession'] ?? '');
$bio                = isset($_POST['bio'])          ? str_clip((string)$_POST['bio'], 500)        : (string)($cur['bio'] ?? '');
$phone              = isset($_POST['phone'])        ? str_clip((string)$_POST['phone'], 32)       : (string)($cur['phone'] ?? '');
$experience         = isset($_POST['experience'])   ? get_int('experience', 0)                    : (int)($cur['experience'] ?? 0);
$avatarColor        = isset($_POST['avatar_color']) ? str_clip((string)$_POST['avatar_color'], 7) : (string)($cur['avatar_color'] ?? '#1cb7ff');
$profCategoryId     = get_int('profession_category_id', 0);

/* ── валидация ──────────────────────────────────────────────── */
if ($name === '') {
    json_out(['ok' => false, 'error' => 'name_required'], 422);
}

if ($phone !== '' && !preg_match('/^\+?[\d\s\-()]{7,20}$/', $phone)) {
    json_out(['ok' => false, 'error' => 'bad_phone'], 422);
}

if ($experience < 0 || $experience > 80) {
    $experience = 0;
}

// Разрешаем только hex-цвета (#rrggbb)
if (!preg_match('/^#[0-9a-fA-F]{6}$/', $avatarColor)) {
    $avatarColor = '#1cb7ff';
}

// Ensure profession_category_id column exists (silent — fails if already exists)
try { $pdo->exec("ALTER TABLE users ADD COLUMN profession_category_id INT DEFAULT NULL"); } catch (Throwable $e) {}

/* ── обновление ─────────────────────────────────────────────── */
try {
    $sql = "
        UPDATE users
        SET name        = ?,
            city        = ?,
            profession  = ?,
            bio         = ?,
            phone       = ?,
            experience  = ?,
            avatar_color= ?,
            updated_at  = NOW()
        WHERE id = ?
    ";
    $st = $pdo->prepare($sql);
    $st->execute([$name, $city, $profession, $bio, $phone, $experience, $avatarColor, $uid]);
} catch (\Throwable $e) {
    // Фолбэк: только базовые поля (если новые колонки ещё не добавлены)
    try {
        $st = $pdo->prepare("UPDATE users SET name = ?, city = ?, updated_at = NOW() WHERE id = ?");
        $st->execute([$name, $city, $uid]);
    } catch (\Throwable $e2) {
        json_out(['ok' => false, 'error' => 'db_error'], 500);
    }
}

// Сохраняем profession_category_id отдельным запросом — изолировано от основного UPDATE
if ($profCategoryId > 0) {
    try {
        $st = $pdo->prepare("UPDATE users SET profession_category_id = ? WHERE id = ?");
        $st->execute([$profCategoryId, $uid]);
    } catch (\Throwable $e) {
        // column may not exist yet — ignore
    }
}

// Возвращаем обновлённые данные (без пароля)
try {
    $st = $pdo->prepare("
        SELECT id, name, email, role, city,
               COALESCE(profession, '')   AS profession,
               COALESCE(bio, '')          AS bio,
               COALESCE(phone, '')        AS phone,
               COALESCE(experience, 0)    AS experience,
               COALESCE(avatar_color, '#1cb7ff') AS avatar_color,
               profession_category_id
        FROM users WHERE id = ? LIMIT 1
    ");
    $st->execute([$uid]);
    $updated = $st->fetch() ?: [];
} catch (\Throwable $e) {
    $updated = ['id' => $uid, 'name' => $name, 'city' => $city];
}

json_out(['ok' => true, 'data' => $updated]);
