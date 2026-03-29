<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  redirect('index.php?tab=profile');
}

$name      = trim((string)($_POST['name']      ?? ''));
$city      = trim((string)($_POST['city']      ?? ''));
$role      = trim((string)($_POST['role']      ?? 'client'));
$login     = trim((string)($_POST['login']     ?? ''));  // логин → хранится в поле email
$password  = (string)($_POST['password']  ?? '');
$password2 = (string)($_POST['password2'] ?? '');

// Все обязательные поля
if ($name === '' || $city === '' || $login === '' || $password === '' || $password2 === '') {
  redirect('index.php?tab=profile&auth=reg_empty');
}

// Логин: буквы (включая кириллицу), цифры, _, - (3–32 символа)
if (!preg_match('/^[a-zA-Z0-9_\-а-яА-ЯёЁ]{3,32}$/u', $login)) {
  redirect('index.php?tab=profile&auth=reg_login_invalid');
}

if (mb_strlen($password) < 6) {
  redirect('index.php?tab=profile&auth=reg_passlen');
}

if ($password !== $password2) {
  redirect('index.php?tab=profile&auth=reg_passmatch');
}

$role = in_array($role, ['master', 'pro', 'usta'], true) ? 'master' : 'client';

$hash = password_hash($password, PASSWORD_DEFAULT);

try {
  $st = $pdo->prepare(
    'INSERT INTO users (name, email, password_hash, role, city, created_at) VALUES (?, ?, ?, ?, ?, NOW())'
  );
  $st->execute([$name, $login, $hash, $role, $city]);

  // Защита от Session Fixation
  session_regenerate_id(true);

  $newId = (int)$pdo->lastInsertId();
  $_SESSION['user_id'] = $newId;
  $_SESSION['role']    = $role;
  // ИСПРАВЛЕНО: is_admin обязателен для корректной работы is_admin() из init.php
  $_SESSION['is_admin'] = 0;

  // pending_sms — флаг для последующей верификации номера (если нужен)
  $_SESSION['pending_sms'] = true;

} catch (\PDOException $e) {
  // Код 23000 — нарушение UNIQUE (логин уже занят)
  if ((string)$e->getCode() === '23000') {
    redirect('index.php?tab=profile&auth=reg_exists');
  }
  // Другая ошибка — логируем и показываем общую
  error_log('[register] PDO error: ' . $e->getMessage());
  redirect('index.php?tab=profile&auth=reg_error');
}

if ($role === 'master') {
  redirect('home-master.php');
}

// ИСПРАВЛЕНО: после регистрации клиента перенаправляем на профиль
// (оригинал не передавал ?auth=reg_ok, из-за чего в JS не было никакого feedback)
redirect('index.php?tab=profile&auth=reg_ok');