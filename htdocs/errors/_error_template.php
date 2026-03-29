<?php
// Shared error page template for Sheber.kz.
// Usage: set $code, $titleKey, $descKey, $primaryHref, $primaryKey, $secondaryAction.

session_start();

// language/theme for error pages (no DB)
$lang = (string)($_GET['lang'] ?? ($_SESSION['lang'] ?? ($_COOKIE['lang'] ?? 'ru')));
$lang = in_array($lang, ['ru','kk'], true) ? $lang : 'ru';
$_SESSION['lang'] = $lang;
setcookie('lang', $lang, ['expires'=>time()+60*60*24*365,'path'=>'/','samesite'=>'Lax']);

$theme = (string)($_COOKIE['theme'] ?? 'dark');
$theme = in_array($theme, ['dark','light'], true) ? $theme : 'dark';

http_response_code((int)($code ?? 500));

$code = (int)($code ?? 500);
$titleKey = (string)($titleKey ?? 'err503Title');
$descKey  = (string)($descKey  ?? 'err503Desc');

$primaryHref = (string)($primaryHref ?? '/');
$primaryKey  = (string)($primaryKey  ?? 'backHome');

// secondaryAction: ['type' => 'link'|'js', 'href' => '...', 'js' => '...', 'key' => 'tryAgain']
$secondaryAction = $secondaryAction ?? ['type' => 'js', 'js' => 'history.back()', 'key' => 'goBack'];

?><!DOCTYPE html>
<html lang="<?= htmlspecialchars($lang, ENT_QUOTES) ?>" data-theme="<?= htmlspecialchars($theme, ENT_QUOTES) ?>">
<head>
  <script src="/assets/js/prefs.js"></script>
  <script>Prefs.applyThemeASAP();</script>
  <script src="/assets/js/i18n_dict.js"></script>
  <script src="/assets/js/i18n_runtime.js"></script>
<meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Sheber.kz | <?= (int)$code ?></title>

  <link rel="icon" type="image/png" sizes="32x32" href="/favicon.png">
  <link rel="apple-touch-icon" href="/favicon.png">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

  <link rel="stylesheet" href="/index.css" />
<style>
    .err-wrap{ padding: 16px 0 24px; }
    .err-center{ margin-top: 14px; }
    .err-card{ text-align:center; overflow:hidden; }
    .err-code{
      font-weight: 900;
      font-size: 58px;
      letter-spacing: -1px;
      line-height: 1;
      margin: 6px 0 12px;
      color: var(--text-main);
    }
    .err-title{ font-weight: 800; font-size: 18px; margin-bottom: 6px; }
    .err-desc{ font-size: 13px; opacity: .8; line-height: 1.5; }
    .err-actions{ display:flex; gap: 10px; margin-top: 16px; }
    .btn-secondary{
      background: transparent;
      color: var(--text-main);
      border: 1px solid var(--border);
    }
    .btn-secondary:active{ opacity: .85; }
    .small-note{ margin-top: 12px; font-size: 11px; opacity: .55; }
  </style>
</head>

<body>
  <div class="app-container">

    <header class="header">
      <div class="brand">
        <a href="/" style="display:flex; align-items:center; gap:10px; text-decoration:none; color:inherit;">
          <div style="display:flex; flex-direction:column;">
            <span style="font-weight:800; font-size:16px; color: var(--primary);">Sheber<span style="color:var(--text-main)">.kz</span></span>
          </div>
        </a>
      </div>

      <button class="menu-btn" onclick="toggleTheme()" title="Theme">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
        </svg>
      </button>
    </header>

    <div class="err-wrap">
      <div class="card err-card">
        <div class="tag" style="margin-bottom:10px;">HTTP</div>

        <div class="err-code"><?= (int)$code ?></div>

        <div class="err-title" data-i18n="<?= htmlspecialchars($titleKey, ENT_QUOTES, 'UTF-8') ?>"> </div>
        <div class="err-desc" data-i18n="<?= htmlspecialchars($descKey, ENT_QUOTES, 'UTF-8') ?>"> </div>

        <div class="err-actions">
          <a class="cta-btn" href="<?= htmlspecialchars($primaryHref, ENT_QUOTES, 'UTF-8') ?>" style="text-decoration:none;">
            <svg viewBox="0 0 24 24"><path d="M3 12l9-9 9 9"></path><path d="M9 21V9h6v12"></path></svg>
            <span data-i18n="<?= htmlspecialchars($primaryKey, ENT_QUOTES, 'UTF-8') ?>"> </span>
          </a>

          <?php if (($secondaryAction['type'] ?? 'js') === 'link') : ?>
            <a class="cta-btn btn-secondary" href="<?= htmlspecialchars((string)($secondaryAction['href'] ?? '/'), ENT_QUOTES, 'UTF-8') ?>" style="text-decoration:none;">
              <svg viewBox="0 0 24 24"><path d="M21 12a9 9 0 1 1-9-9"></path><path d="M21 3v9h-9"></path></svg>
              <span data-i18n="<?= htmlspecialchars((string)($secondaryAction['key'] ?? 'tryAgain'), ENT_QUOTES, 'UTF-8') ?>"> </span>
            </a>
          <?php else : ?>
            <button class="cta-btn btn-secondary" type="button" onclick="<?= htmlspecialchars((string)($secondaryAction['js'] ?? 'history.back()'), ENT_QUOTES, 'UTF-8') ?>">
              <svg viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
              <span data-key="<?= htmlspecialchars((string)($secondaryAction['key'] ?? 'goBack'), ENT_QUOTES, 'UTF-8') ?>"> </span>
            </button>
          <?php endif; ?>
        </div>

        <div class="small-note">Sheber.kz</div>
      </div>
    </div>

    <div id="toast" class="toast"></div>
  </div>
</body>
</html>
