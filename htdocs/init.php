<?php
declare(strict_types=1);

/**
 * Общая инициализация проекта.
 *
 * Рекомендация по безопасности:
 * - На хостинге InfinityFree лучше хранить файл с доступом к БД вне public папки (вне /htdocs)
 *   и подключать его через require.
 */

$__sessionSecure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
    || (strtolower((string)($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https');
session_set_cookie_params([
  'lifetime' => 86400 * 30,
  'path' => '/',
  'secure' => $__sessionSecure,
  'httponly' => true,
  'samesite' => 'Lax',
]);
unset($__sessionSecure);
session_start();

// ---------- Security basics ----------
// CSRF token stored in session (used by /api/* POST endpoints)
function csrf_token(): string {
  if (empty($_SESSION['csrf_token']) || !is_string($_SESSION['csrf_token']) || strlen($_SESSION['csrf_token']) < 20) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
  }
  return (string)$_SESSION['csrf_token'];
}

function csrf_check(?string $token): bool {
  $sess = (string)($_SESSION['csrf_token'] ?? '');
  if ($sess === '' || !is_string($token) || $token === '') return false;
  return hash_equals($sess, $token);
}

function is_admin(): bool {
  return (int)($_SESSION['is_admin'] ?? 0) === 1;
}

function require_admin(): void {
  if (!is_admin()) {
    http_response_code(403);
    echo 'Forbidden';
    exit;
  }
}

/** MIME для загруженного файла (PHP 8.1+: предпочтительнее mime_content_type). */
function upload_mime_type(string $path): string {
  if ($path === '' || !is_readable($path)) {
    return 'application/octet-stream';
  }
  $finfo = new finfo(FILEINFO_MIME_TYPE);
  $mime = $finfo->file($path);
  return (is_string($mime) && $mime !== '') ? $mime : 'application/octet-stream';
}

// ---------- Language (RU/KK) ----------
// ?lang=ru|kk сохраняем в сессию (cookie 'lang' используется как fallback для переходов между страницами)
$lang = (string)($_GET['lang'] ?? ($_SESSION['lang'] ?? ($_COOKIE['lang'] ?? 'ru')));
$lang = strtolower(trim($lang));
// Accept common aliases
if ($lang === 'kz' || $lang === 'kk-kz') $lang = 'kk';
$lang = in_array($lang, ['ru','kk'], true) ? $lang : 'ru';
$_SESSION['lang'] = $lang;
// Mirror lang into cookie for static pages / error pages
setcookie('lang', $lang, [
  'expires' => time()+60*60*24*365,
  'path' => '/',
  'samesite' => 'Lax',
]);

$__DICT = [];
try {
  $__DICT = require __DIR__ . '/lang.php';
} catch (Throwable $e) {
  $__DICT = [];
}

function lang_get(): string {
  return (string)($_SESSION['lang'] ?? 'ru');
}

function t(string $key): string {
  /** @var array $__DICT */
  global $__DICT;
  $l = lang_get();
  if (isset($__DICT[$l][$key])) return (string)$__DICT[$l][$key];
  if (isset($__DICT['ru'][$key])) return (string)$__DICT['ru'][$key];
  return $key;
}


// ---------- Theme (dark/light) ----------
// Theme is stored in localStorage (client) and mirrored into cookie 'theme' for SSR (no flash)
$theme = (string)($_COOKIE['theme'] ?? 'light');
$theme = in_array($theme, ['dark','light'], true) ? $theme : 'light';

function theme_get(): string {
  $t = (string)($_COOKIE['theme'] ?? 'light');
  return in_array($t, ['dark','light'], true) ? $t : 'light';
}

// --- базовые настройки для продакшена ---
// На бесплатных хостингах warning/notice часто включены и ломают JSON.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);

// Логи (если папки нет — просто игнорируем)
$logDir = __DIR__ . '/storage/logs';
if (is_dir($logDir) || @mkdir($logDir, 0775, true)) {
  @ini_set('error_log', $logDir . '/php.log');
}

function is_api_request(): bool {
  $uri = (string)($_SERVER['REQUEST_URI'] ?? '');
  return str_contains($uri, '/api/');
}

function api_fatal(string $error, int $code = 500): never {
  http_response_code($code);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode(['ok' => false, 'error' => $error], JSON_UNESCAPED_UNICODE);
  exit;
}

// ---------- DB config ----------
// Безопаснее хранить креды вне public-папки.
// В этом проекте используем htdocs/config.local.php (НЕ загружать в публичный репозиторий)
// либо переменные окружения.
$cfg = [
  'DB_HOST'   => getenv('DB_HOST') ?: '',
  'DB_PORT'   => getenv('DB_PORT') ?: '3306',
  'DB_NAME'   => getenv('DB_NAME') ?: '',
  'DB_USER'   => getenv('DB_USER') ?: '',
  'DB_PASS'   => getenv('DB_PASS') ?: '',
  'DB_SOCKET' => getenv('DB_SOCKET') ?: '',
];

$localCfgFile = __DIR__ . '/config.local.php';
if (is_file($localCfgFile)) {
  $local = require $localCfgFile;
  if (is_array($local)) {
    $cfg = array_merge($cfg, $local);
  }
}

$DB_HOST   = (string)($cfg['DB_HOST']   ?? '');
$DB_PORT   = (int)($cfg['DB_PORT']   ?? 3306);
$DB_NAME   = (string)($cfg['DB_NAME']   ?? '');
$DB_USER   = (string)($cfg['DB_USER']   ?? '');
$DB_PASS   = (string)($cfg['DB_PASS']   ?? '');
$DB_SOCKET = (string)($cfg['DB_SOCKET'] ?? '');

if ($DB_NAME === '' || $DB_USER === '') {
  if (is_api_request()) api_fatal('db_not_configured', 500);
  http_response_code(500);
  echo 'Database is not configured. Fill htdocs/config.local.php.';
  exit;
}

// ---------- PDO ----------
// Если задан сокет или host=localhost — используем unix_socket (MySQL на VPS без TCP).
// Иначе используем TCP (DB_HOST:DB_PORT для удалённых серверов).
if ($DB_SOCKET !== '') {
  // Явно указан путь к сокету
  $dsn = sprintf('mysql:unix_socket=%s;dbname=%s;charset=utf8mb4', $DB_SOCKET, $DB_NAME);
} elseif ($DB_HOST === '' || $DB_HOST === 'localhost' || $DB_HOST === '127.0.0.1') {
  // Локальный MySQL — ищем сокет автоматически
  $possibleSockets = [
    '/run/mysqld/mysqld.sock',
    '/var/run/mysqld/mysqld.sock',
    '/tmp/mysql.sock',
    '/var/lib/mysql/mysql.sock',
  ];
  $foundSocket = '';
  foreach ($possibleSockets as $s) {
    if (file_exists($s)) { $foundSocket = $s; break; }
  }
  if ($foundSocket !== '') {
    $dsn = sprintf('mysql:unix_socket=%s;dbname=%s;charset=utf8mb4', $foundSocket, $DB_NAME);
  } else {
    // Fallback: попробуем TCP
    $host = ($DB_HOST === '') ? '127.0.0.1' : $DB_HOST;
    $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $host, $DB_PORT, $DB_NAME);
  }
} else {
  // Удалённый сервер — TCP
  $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $DB_HOST, $DB_PORT, $DB_NAME);
}

try {
  $pdo = new PDO($dsn, $DB_USER, $DB_PASS, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
  ]);
} catch (Throwable $e) {
  // Не показываем детали пользователю (безопасность).
  error_log('[DB] ' . $e->getMessage());
  if (is_api_request()) api_fatal('db_connect_error', 500);
  http_response_code(500);
  echo 'Database connection error.';
  exit;
}

// ---------- FCM (Firebase Cloud Messaging — V1 API) ----------
if (!defined('FCM_SERVICE_ACCOUNT_PATH')) {
  define('FCM_SERVICE_ACCOUNT_PATH', (string)($cfg['FCM_SERVICE_ACCOUNT_PATH'] ?? ''));
}

// ---------- Telegram (support_send.php → уведомление в чат админа) ----------
// config.local.php обычно return [...]; константы из массива, если ещё не заданы (старый стиль: define в том же файле).
if (!defined('TELEGRAM_BOT_TOKEN')) {
  define('TELEGRAM_BOT_TOKEN', (string)($cfg['TELEGRAM_BOT_TOKEN'] ?? ''));
}
if (!defined('TELEGRAM_SUPPORT_CHAT_ID')) {
  define('TELEGRAM_SUPPORT_CHAT_ID', (string)($cfg['TELEGRAM_SUPPORT_CHAT_ID'] ?? ''));
}

if (!function_exists('e')) {
  function e($v): string {
    return htmlspecialchars((string)$v, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
  }
}

function redirect(string $url): never {
  header('Location: ' . $url);
  exit;
}

/**
 * Возвращает текущего авторизованного пользователя или null.
 */
function current_user(PDO $pdo): ?array {
  $uid = $_SESSION['user_id'] ?? null;
  if (!is_int($uid) && !ctype_digit((string)$uid)) return null;
  $uid = (int)$uid;

  try {
// Try to fetch extended profile fields (after migration); fallback to legacy schema
try {
  $st = $pdo->prepare('SELECT id, name, email, role, city, created_at, ' .
    'COALESCE(balance,0) AS balance, COALESCE(is_blocked,0) AS is_blocked, last_seen, ' .
    'avatar_url, COALESCE(avatar_color,\'#1cb7ff\') AS avatar_color, ' .
    'COALESCE(profession,\'\') AS profession, COALESCE(experience,0) AS experience, ' .
    'COALESCE(phone,\'\') AS phone, COALESCE(bio,\'\') AS bio ' .
    'FROM users WHERE id = ? LIMIT 1');
  $st->execute([$uid]);
  $u = $st->fetch();
} catch (Throwable $e) {
  try {
    $st = $pdo->prepare('SELECT id, name, email, role, city, created_at, COALESCE(balance,0) AS balance, COALESCE(is_blocked,0) AS is_blocked, last_seen FROM users WHERE id = ? LIMIT 1');
    $st->execute([$uid]);
    $u = $st->fetch();
  } catch (Throwable $e2) {
    return null;
  }
}
if (!$u) return null;
if ((int)($u['is_blocked'] ?? 0) === 1) return null;
return $u;
  } catch (Throwable $e) {
    return null;
  }
}