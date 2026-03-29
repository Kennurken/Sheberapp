<?php
declare(strict_types=1);
require __DIR__ . '/../init.php';

// Read admin password from config.local.php or ENV
$cfg = [];
$localCfgFile = __DIR__ . '/../config.local.php';
if (is_file($localCfgFile)) {
  $cfg = require $localCfgFile;
  if (!is_array($cfg)) $cfg = [];
}
$ADMIN_PASS = (string)($cfg['ADMIN_PASSWORD'] ?? getenv('ADMIN_PASSWORD') ?: '');

if ($ADMIN_PASS === '') {
  http_response_code(500);
  echo 'ADMIN_PASSWORD is not configured in htdocs/config.local.php';
  exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $pass = (string)($_POST['password'] ?? '');
  $tok = (string)($_POST['csrf_token'] ?? '');
  if (!csrf_check($tok)) {
    http_response_code(419);
    echo 'CSRF';
    exit;
  }
  if (hash_equals($ADMIN_PASS, $pass)) {
    $_SESSION['is_admin'] = 1;
    header('Location: /admin/index.php');
    exit;
  }
  header('Location: /admin/login.php?err=1');
  exit;
}

$err = (int)($_GET['err'] ?? 0);
$csrf = csrf_token();
?>
<!doctype html>
<html lang="ru" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Admin — Sheber.kz</title>
  <link rel="stylesheet" href="/index.css?v=5">
  <script>
    (function(){
      try {
        var t = localStorage.getItem('theme');
        if (t === 'light' || t === 'dark') document.documentElement.setAttribute('data-theme', t);
      } catch(e) {}
    })();
  </script>
</head>
<body>
  <div class="card" style="max-width:420px;margin:24px auto;">
    <div class="h2" style="margin-bottom:8px;">Admin</div>
    <div class="txt-sm" style="opacity:.8;margin-bottom:12px;">Вход в админ-панель</div>

    <?php if ($err): ?>
      <div class="txt-sm" style="color:var(--danger,#ff5a5f);margin-bottom:10px;">Неверный пароль</div>
    <?php endif; ?>

    <form method="post" autocomplete="off">
      <input type="hidden" name="csrf_token" value="<?= e($csrf) ?>">
      <label class="txt-sm" style="display:block;margin-bottom:6px;opacity:.85;">Пароль</label>
      <input class="input" type="password" name="password" required style="width:100%;margin-bottom:12px;">
      <button class="cta-btn" type="submit" style="width:100%;">Войти</button>
    </form>
  </div>
</body>
</html>
