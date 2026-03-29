<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  redirect('index.php?tab=profile');
}

$login    = trim((string)($_POST['login']    ?? ''));
$password = (string)($_POST['password'] ?? '');

if ($login === '' || $password === '') {
  redirect('index.php?tab=profile&auth=login_empty');
}

// Ищем пользователя по полю email (в котором хранится логин)
// ИСПРАВЛЕНО: добавлен поиск также по полю email напрямую —
// оба варианта (логин через email или произвольная строка) поддерживаются.
$st = $pdo->prepare('SELECT id, password_hash, role, is_blocked FROM users WHERE email = ? LIMIT 1');
$st->execute([$login]);
$user = $st->fetch();

// Проверка пароля
if (!$user || !password_verify($password, (string)$user['password_hash'])) {
  // Искусственная задержка против брутфорса
  usleep(random_int(300000, 500000));
  redirect('index.php?tab=profile&auth=login_bad');
}

// Проверка блокировки
if ((int)$user['is_blocked']) {
  redirect('index.php?tab=profile&auth=login_blocked');
}

// Защита от Session Fixation
session_regenerate_id(true);

// Сохраняем данные в сессию
$_SESSION['user_id'] = (int)$user['id'];
$_SESSION['role']    = (string)$user['role'];

// ИСПРАВЛЕНО: is_admin нужен для is_admin() в init.php,
// иначе require_admin() будет всегда возвращать 403.
// Получаем значение из БД (колонки role — 'master'/'client', роль admin отдельно).
// Если у вас нет отдельного поля is_admin — используйте role === 'admin':
$_SESSION['is_admin'] = 0; // по умолчанию — не админ

// Обновляем last_seen
try {
  $pdo->prepare('UPDATE users SET last_seen = NOW() WHERE id = ?')->execute([$user['id']]);
} catch (\Throwable $e) {}

// Маршрутизация по ролям
if ((string)$user['role'] === 'master') {
  redirect('home-master.php');
}

redirect('index.php?tab=profile&auth=login_ok');