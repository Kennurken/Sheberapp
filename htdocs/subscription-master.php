<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

$me = current_user($pdo);
if (!$me) {
  header('Location: /index.php?login=required');
  exit;
}
if (($me['role'] ?? '') !== 'master') {
  header('Location: /index.php?forbidden=1');
  exit;
}

$lang = lang_get();
?>
<!doctype html>
<html lang="<?= e($lang) ?>" data-theme="<?= e(theme_get()) ?>">
<head>
  <script src="/assets/js/prefs.js"></script>
  <script>Prefs.applyThemeASAP();</script>

  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Sheber.kz — <?= e(t('master_subscription')) ?></title>

  <link rel="icon" type="image/png" sizes="32x32" href="favicon.png">
  <link rel="apple-touch-icon" href="favicon.png">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

  <!-- Единый CSS (тот же, что у клиента) -->
  <link rel="stylesheet" href="/index.css?v=5">
  <style>
    .sub-plan-card { transition: box-shadow .15s; }
    .sub-plan-card:hover { box-shadow: 0 4px 24px rgba(0,105,255,.12); }
    .sub-autorenew { display:flex; justify-content:space-between; align-items:center; gap:12px; padding:14px 16px; }
    .sub-autorenew-label { font-weight:700; font-size:14px; margin-bottom:2px; }
    .sub-autorenew-desc { font-size:12px; opacity:.7; }
    .sub-switch { position:relative; display:inline-flex; align-items:center; cursor:pointer; }
    .sub-switch input { opacity:0; width:0; height:0; position:absolute; }
    .sub-switch .track { width:46px; height:26px; background:var(--border); border-radius:999px; position:relative; transition:background .2s; }
    .sub-switch input:checked + .track { background:var(--primary); }
    .sub-switch .thumb { position:absolute; top:3px; left:3px; width:20px; height:20px; background:#fff; border-radius:50%; transition:transform .2s; box-shadow:0 1px 4px rgba(0,0,0,.25); }
    .sub-switch input:checked ~ .track .thumb { transform:translateX(20px); }
    .sub-error { color:var(--danger); font-size:13px; padding:12px 16px; background:rgba(255,90,90,.1); border-radius:12px; margin-top:8px; }
  </style>
</head>
<body data-page="subscription-master">

  <div class="app-container">

    <!-- Header -->
    <header class="header">
      <div class="brand">
        <a href="home-master.php" class="menu-btn" style="padding:0; margin-right:4px; text-decoration:none; color:var(--text-main);">
          <svg viewBox="0 0 24 24" stroke="currentColor" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:24px;height:24px;">
            <polyline points="15 18 9 12 15 6"></polyline>
          </svg>
        </a>
        <div style="display:flex; flex-direction:column;">
          <span style="font-weight:800; font-size:16px; color:var(--text-main);">Sheber<span style="color:#0069ff">.kz</span></span>
        </div>
      </div>
      <div class="txt-sm" style="font-weight:700; color:var(--text-sec);"><?= e(t('subscription')) ?></div>
    </header>

    <!-- Page title -->
    <div style="margin-bottom:24px;">
      <div class="h2" style="margin-bottom:4px;"><?= e(t('master_subscription')) ?></div>
      <div class="txt-sm"><?= e(t('plan_select_title')) ?></div>
    </div>

    <!-- Autorenew toggle -->
    <div class="card sub-autorenew" style="margin-bottom:16px;">
      <div>
        <div class="sub-autorenew-label"><?= e(t('autorenew')) ?></div>
        <div class="sub-autorenew-desc" id="autoRenewDesc"><?= e(t('autorenew_sub')) ?></div>
      </div>
      <label class="sub-switch" title="<?= e(t('autorenew')) ?>">
        <input id="autoRenewSwitch" type="checkbox" />
        <span class="track"><span class="thumb"></span></span>
      </label>
    </div>

    <!-- Plans -->
    <div class="sub-plans" id="subPlans"></div>

    <!-- Error -->
    <div class="sub-error" id="subErr" style="display:none"></div>

  </div><!-- /.app-container -->

  <!-- i18n data attrs for JS -->
  <div id="subI18n"
    data-loading="<?= e(t('loading')) ?>"
    data-activate="<?= e(t('activate')) ?>"
    data-current="<?= e(t('current_plan')) ?>"
    data-change_next="<?= e(t('change_next_period')) ?>"
    data-current_label="<?= e(t('current_tariff')) ?>"
    data-badge="<?= e(t('your_plan')) ?>"
    data-confirm_cancel="<?= e(t('confirm_cancel')) ?>"
    data-session_expired="<?= e(t('session_expired')) ?>"
    data-plan_scheduled="<?= e(t('plan_scheduled')) ?>"
    data-sub_activated_until="<?= e(t('sub_activated_until')) ?>"
    data-autorenew_on="<?= e(t('autorenew_on')) ?>"
    data-autorenew_off="<?= e(t('autorenew_off')) ?>"
    data-sub_inactive="<?= e(t('subscription_inactive')) ?>"
    data-lang="<?= e($lang) ?>"
  ></div>

  <div id="toast" class="toast"></div>

  <script src="/subscription-master.js?v=<?= time() ?>"></script>
</body>
</html>