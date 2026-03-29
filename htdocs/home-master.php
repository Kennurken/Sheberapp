<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

$user = current_user($pdo);
if (!$user || (string)$user['role'] !== 'master') {
  redirect('index.php?tab=profile');
}

$frontUser = [
  'id'           => (int)$user['id'],
  'name'         => (string)$user['name'],
  'city'         => (string)$user['city'],
  'role'         => 'master',
  'spec'         => 'Шебер',
  'avatar_url'   => (string)($user['avatar_url'] ?? ''),
  'avatar_color' => (string)($user['avatar_color'] ?? '#2563EB'),
  'profession'   => (string)($user['profession'] ?? ''),
  'experience'   => (int)($user['experience'] ?? 0),
  'phone'        => (string)($user['phone'] ?? ''),
  'bio'          => (string)($user['bio'] ?? ''),
];

$initial = mb_strtoupper(mb_substr(trim((string)$user['name'] ?: 'M'), 0, 1)) ?: 'M';
$lang = lang_get();
$isRu = ($lang === 'ru');
?>
<!DOCTYPE html>
<html lang="<?= e($lang) ?>" data-theme="<?= e(theme_get()) ?>">
<head>
  <script src="/assets/js/prefs.js"></script>
  <script>Prefs.applyThemeASAP();</script>

  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Sheber.kz — <?= $isRu ? 'Кабинет мастера' : 'Шебер кабинеті' ?></title>

  <link rel="icon" type="image/png" sizes="32x32" href="favicon.png">
  <link rel="apple-touch-icon" href="favicon.png">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" crossorigin="" />

  <style>
@keyframes nearbyPulse { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:.6;transform:scale(1.15)} }
@keyframes masterPulse { 0%,100%{opacity:.3;transform:scale(1)} 50%{opacity:.7;transform:scale(1.5)} }
</style>
  <link rel="stylesheet" href="index.css?v=20" />
  <script src="home-master.js?v=<?= time() ?>" defer></script>
</head>

<body class="role-master">
  <script>
    try {
      window.__SERVER_USER = <?= json_encode($frontUser, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
      localStorage.setItem('sheber_user', JSON.stringify(window.__SERVER_USER));
    } catch(e) {}
  </script>

  <div class="app-container">

    <!-- ── HEADER ─────────────────────────────────────────── -->
    <header class="header">
      <div class="brand">
        <button class="menu-btn" type="button" onclick="toggleMenu()" aria-label="Меню">
          <svg viewBox="0 0 24 24" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
            <line x1="3" y1="7" x2="21" y2="7"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="17" x2="16" y2="17"/>
          </svg>
        </button>
        <span class="logo-text">Sheber<span class="dot">.kz</span></span>
      </div>
      <div class="header-actions">
        <button class="menu-btn" type="button" onclick="showToast(t('toastNoNewMessages'))" aria-label="Уведомления" id="notifBtn" style="position:relative;">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
          </svg>
          <span id="notifDot" style="position:absolute;top:7px;right:7px;width:8px;height:8px;border-radius:50%;background:var(--danger);display:none;border:2px solid var(--bg-body);"></span>
        </button>
      </div>
    </header>

    <!-- ── TAB: HOME ─────────────────────────────────────── -->
    <div id="tab-home" class="tab-content active">

      <!-- Greeting + Online Toggle -->
      <div class="greeting">
        <div>
          <div class="h1" id="greetingH1"><?= $isRu ? 'Привет!' : 'Сәлем!' ?></div>
          <div class="sub txt-sm" style="margin-top:3px;" data-i18n="masterReadyQ"><?= $isRu ? 'Готовы работать сегодня?' : 'Бүгін жұмысқа дайынсыз ба?' ?></div>
        </div>
        <button id="onlineToggleBtn" onclick="toggleOnlineStatus()" class="status-pill" aria-label="Статус онлайн">
          <div id="onlineDot" class="status-dot"></div>
          <span id="onlineLabel" class="txt-sm" style="font-weight:700;white-space:nowrap;"><?= $isRu ? 'Офлайн' : 'Желіден тыс' ?></span>
        </button>
      </div>

      <!-- Onboarding -->
      <div id="onboardingBanner" style="display:none;"></div>

      <!-- FREE PERIOD BANNER -->
      <div class="balance-card mb-16" style="background:linear-gradient(135deg,rgba(28,183,255,.12) 0%,rgba(99,102,241,.1) 100%);border-color:rgba(28,183,255,.25);">
        <div class="tag tag-success" style="margin-bottom:10px;">🎉 <?= $isRu ? 'Бесплатный период' : 'Тегін кезең' ?></div>
        <div style="font-size:18px;font-weight:800;margin-bottom:6px;"><?= $isRu ? 'Первый месяц — бесплатно!' : 'Бірінші ай — тегін!' ?></div>
        <div class="txt-sm" style="opacity:.75;line-height:1.5;"><?= $isRu ? 'Принимайте заказы без ограничений. Подписка и оплата появятся позже.' : 'Шектеусіз тапсырыс қабылдаңыз. Жазылым кейінірек қосылады.' ?></div>
      </div>

      <!--
      BALANCE + SUBSCRIPTION — временно отключено (бесплатный период)
      <div class="balance-card mb-16">
        <div class="tag tag-success" style="margin-bottom:10px;"><?= $isRu ? 'Баланс' : 'Баланс' ?></div>
        <div class="balance-amount" id="masterBalance">0 ₸</div>
        <div class="txt-sm mt-8" style="opacity:.65;"><?= $isRu ? 'Ваш счёт — для оплаты подписки' : 'Сіздің шотыңыз — жазылым төлеміне' ?></div>
        <button class="cta-btn" onclick="window.location.href='payment-master.php'" style="margin-top:14px;">
          <svg viewBox="0 0 24 24"><path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
          <span><?= $isRu ? 'Пополнить баланс' : 'Балансты толтыру' ?></span>
        </button>
        <div style="margin-top:12px;padding:14px;background:var(--surface-highlight);border-radius:var(--radius-md);border:1px solid var(--border);">
          <div style="display:flex;justify-content:space-between;align-items:center;gap:10px;">
            <div>
              <div class="h4"><?= $isRu ? 'Подписка' : 'Жазылым' ?></div>
              <div class="txt-sm mt-8" id="subTitle" style="font-size:13px;"><span><?= $isRu ? 'Загрузка...' : 'Жүктелуде...' ?></span></div>
              <div class="txt-sm" id="subDesc" style="font-size:12px;opacity:.7;"></div>
              <div class="txt-sm" id="subRenewHint" style="font-size:11px;display:none;opacity:.6;margin-top:3px;"></div>
            </div>
            <button class="cta-btn btn-sm" id="subBtn" onclick="openSubscription()" style="flex-shrink:0;">
              <span id="subBtnText"><?= $isRu ? 'Оформить' : 'Оформить' ?></span>
            </button>
          </div>
        </div>
      </div>
      -->

      <!-- Earnings Chart -->
      <div class="card mb-16">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:14px;">
          <div>
            <div class="h4" style="margin-bottom:3px;" data-i18n="chartTitle"><?= $isRu ? '📊 Заработок' : '📊 Табыс' ?></div>
            <div style="font-weight:900;color:var(--primary);font-size:22px;letter-spacing:-0.8px;" id="chartTotalEarnings">0 ₸</div>
            <div class="txt-xs mt-8" id="chartTotalOrders" style="opacity:.6;"></div>
          </div>
          <div style="display:flex;gap:5px;">
            <button id="chartBtn-week" onclick="loadEarningsChart('week')"
              style="font-size:11px;font-weight:800;padding:6px 13px;border-radius:999px;border:none;background:var(--primary);color:#fff;cursor:pointer;">
              <span data-i18n="chartWeek"><?= $isRu ? 'Неделя' : 'Апта' ?></span>
            </button>
            <button id="chartBtn-month" onclick="loadEarningsChart('month')"
              style="font-size:11px;font-weight:800;padding:6px 13px;border-radius:999px;border:1px solid var(--border);background:transparent;color:var(--text-sec);cursor:pointer;">
              <span data-i18n="chartMonth"><?= $isRu ? 'Месяц' : 'Ай' ?></span>
            </button>
          </div>
        </div>
        <div id="earningsChart"></div>
      </div>

      <!-- Master level -->
      <div class="card mb-16" id="masterLevelCard">
        <div class="txt-sm flex-center" style="padding:8px;opacity:.6;" data-i18n="loading"><?= $isRu ? 'Загрузка...' : 'Жүктелуде...' ?></div>
      </div>

      <!-- Quick actions -->
      <div class="section-head" style="margin-top:4px;">
        <div class="h3" data-i18n="newOrders"><?= $isRu ? 'Новые заказы' : 'Жаңа тапсырыстар' ?></div>
        <div class="link-btn" onclick="setTab('courses')">
          <span data-i18n="all"><?= $isRu ? 'Все' : 'Барлығы' ?></span>
          <svg viewBox="0 0 24 24" style="width:14px;height:14px;stroke:currentColor;stroke-width:2.5;fill:none;"><polyline points="9 18 15 12 9 6"/></svg>
        </div>
      </div>

      <div class="stats-row" style="margin-top:0;">
        <div class="stat-item" onclick="setTab('profile')" style="cursor:pointer;">
          <div class="stat-val" id="pProgress">—</div>
          <div class="stat-lbl" data-i18n="statOrder"><?= $isRu ? 'Заказы' : 'Тапсырыс' ?></div>
        </div>
        <div class="stat-item" onclick="setTab('profile')" style="cursor:pointer;">
          <div class="stat-val" id="pAccuracy">—</div>
          <div class="stat-lbl" data-i18n="statRating"><?= $isRu ? 'Рейтинг' : 'Рейтинг' ?></div>
        </div>
        <div class="stat-item" onclick="setTab('profile')" style="cursor:pointer;">
          <div class="stat-val" id="pStreak">0 ₸</div>
          <div class="stat-lbl" data-i18n="statBonus"><?= $isRu ? 'Доход' : 'Табыс' ?></div>
        </div>
      </div>

      <div style="margin-top:16px;">
        <div id="masterOrdersHome"></div>
        <div id="masterOrdersHomePlaceholder" style="display:none;"></div>
      </div>
    </div>
    <!-- /tab-home -->

    <!-- ── TAB: CATALOG (лента заказов) ──────────────────── -->
    <div id="tab-courses" class="tab-content" style="padding-bottom:60px;">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
        <div>
          <div class="h2" data-i18n="ordersFeed"><?= $isRu ? 'Лента заказов' : 'Тапсырыстар таспасы' ?></div>
          <div class="txt-sm mt-8" data-i18n="nearbyOrders" style="opacity:.7;"><?= $isRu ? 'Заказы рядом' : 'Жақын маңдағы тапсырыстар' ?></div>
        </div>
        <div style="display:flex;gap:4px;background:var(--surface-highlight);border-radius:var(--radius-md);padding:4px;">
          <button id="viewBtnList" onclick="switchOrdersView('list')"
            style="padding:7px 14px;border-radius:var(--radius-sm);border:none;background:var(--primary);color:#fff;font-size:13px;font-weight:700;cursor:pointer;">☰</button>
          <button id="viewBtnMap" onclick="switchOrdersView('map')"
            style="padding:7px 12px;border-radius:var(--radius-sm);border:none;background:transparent;color:var(--text-sec);font-size:13px;cursor:pointer;display:flex;align-items:center;gap:5px;">
            🗺️ <span id="mapOrdersCount" style="font-size:10px;background:var(--primary);color:#fff;border-radius:999px;padding:1px 6px;">0</span>
            <span id="nearbyOrdersBadge" style="display:none;font-size:10px;background:#ff5000;color:#fff;border-radius:999px;padding:1px 7px;font-weight:800;"></span>
          </button>
        </div>
      </div>

      <!-- LIST VIEW -->
      <div id="ordersListView">
        <div class="search-wrap" style="margin-bottom:14px;">
          <span class="search-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg></span>
          <input class="course-search" id="courseSearch" data-i18n-placeholder="searchPlaceholder" placeholder="<?= $isRu ? 'Поиск заказа...' : 'Тапсырыс іздеу...' ?>">
        </div>
        <div class="course-wrap" id="coursesRoot">
          <div id="masterOrdersCourses"></div>
          <div id="masterOrdersCoursesPlaceholder"></div>
        </div>
      </div>

      <!-- MAP VIEW -->
      <div id="ordersMapView" style="display:none;">
        <div id="ordersMapContainer" style="height:calc(100vh - 230px);min-height:360px;"></div>
        <div style="margin-top:10px;text-align:center;">
          <button class="cta-btn btn-ghost btn-sm" style="margin:0 auto;" onclick="loadOrdersOnMap()">
            <svg viewBox="0 0 24 24" style="width:15px;height:15px;" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
            <span><?= $isRu ? 'Обновить' : 'Жаңарту' ?></span>
          </button>
        </div>
      </div>
    </div>
    <!-- /tab-courses -->

    <!-- ── TAB: MESSAGES ──────────────────────────────────── -->
    <div id="tab-messages" class="tab-content" style="padding-bottom:60px;">
      <div style="margin-bottom:18px;">
        <div class="h2" data-i18n="messages"><?= $isRu ? 'Сообщения' : 'Хабарламалар' ?></div>
        <div class="txt-sm mt-8" data-i18n="chatSub" style="opacity:.7;"><?= $isRu ? 'Чат с клиентами' : 'Клиенттермен чат' ?></div>
      </div>
      <div id="masterChats"></div>
      <div id="masterChatsPlaceholder">
        <div class="empty-state">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          <div class="empty-title"><?= $isRu ? 'Нет сообщений' : 'Хабарлама жоқ' ?></div>
          <div class="empty-desc"><?= $isRu ? 'Здесь появятся чаты с клиентами' : 'Клиент чаттары осында пайда болады' ?></div>
        </div>
      </div>
    </div>
    <!-- /tab-messages -->

    <!-- ── TAB: PROFILE ───────────────────────────────────── -->
    <div id="tab-profile" class="tab-content" style="padding-bottom:60px;">

      <div style="margin-bottom:16px;">
        <div class="h2" data-i18n="profile"><?= $isRu ? 'Профиль' : 'Профиль' ?></div>
        <div class="txt-sm mt-8" style="opacity:.7;" data-i18n="profileSub"><?= $isRu ? 'Рейтинг и отзывы' : 'Рейтинг және пікірлер' ?></div>
      </div>

      <!-- Profile card -->
      <div class="profile-card">
        <div class="profile-top">
          <div class="avatar-wrap">
            <div class="avatar avatar-lg" id="profileAvatar"
              style="background:<?= e($user['avatar_color'] ?? '#2563EB') ?>;<?= !empty($user['avatar_url']) ? 'background-image:url(\''.e($user['avatar_url']).'\');background-size:cover;background-position:center;' : '' ?>">
              <?= empty($user['avatar_url']) ? e($initial) : '' ?>
            </div>
          </div>
          <div style="flex:1;min-width:0;">
            <div class="h3" id="profileName"><?= e($user['name'] ?? 'Мастер') ?></div>
            <div class="txt-sm mt-8" id="profileRole"><?= !empty($user['profession']) ? e($user['profession']) : ($isRu ? 'Мастер' : 'Шебер') ?> · <?= e($user['city'] ?? 'Алматы') ?></div>
            <?php if (!empty($user['profession'])): ?>
              <div class="txt-sm mt-8" id="profileProfession" style="display:none;"></div>
              <div class="txt-sm mt-8" id="profileProfession" style="color:var(--primary);font-weight:700;">
                <?= e($user['profession']) ?><?= (!empty($user['experience']) && (int)$user['experience'] > 0) ? ' · ' . e((string)(int)$user['experience']) . ($isRu ? ' лет' : ' жыл') : '' ?>
              </div>
            <?php else: ?>
              <div id="profileProfession" style="display:none;"></div>
            <?php endif; ?>
          </div>
          <button class="profile-edit-btn" type="button" onclick="openProfileEdit()" aria-label="Редактировать профиль">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
        </div>

        <?php if (!empty($user['bio'])): ?>
          <div class="profile-bio" id="profileBio"><?= e($user['bio']) ?></div>
        <?php else: ?>
          <div id="profileBio" class="profile-bio" style="display:none;"></div>
        <?php endif; ?>

        <?php if (!empty($user['phone'])): ?>
          <div class="txt-sm mt-8" id="profilePhone" style="display:flex;align-items:center;gap:6px;color:var(--text-sec);">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.61 1.16h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
            <?= e($user['phone']) ?>
          </div>
        <?php else: ?>
          <div id="profilePhone" class="txt-sm" style="display:none;align-items:center;gap:6px;"></div>
        <?php endif; ?>

        <div class="profile-stats">
          <div class="pstat"><div class="v" id="profileOrders">0</div><div class="l" data-i18n="statOrder"><?= $isRu ? 'Заказы' : 'Тапсырыс' ?></div></div>
          <div class="pstat"><div class="v" id="profileRating">—</div><div class="l" data-i18n="statRating"><?= $isRu ? 'Рейтинг' : 'Рейтинг' ?></div></div>
          <div class="pstat"><div class="v" id="profileEarnings">0 ₸</div><div class="l" data-i18n="statBonus"><?= $isRu ? 'Доход' : 'Табыс' ?></div></div>
        </div>
      </div>

      <!-- Reviews -->
      <div class="card mt-12">
        <div class="h3" style="margin-bottom:12px;"><?= $isRu ? 'Отзывы' : 'Пікірлер' ?></div>
        <div id="masterReviews" class="txt-sm" style="opacity:.75;">
          <div class="empty-state" style="padding:24px 0 8px;">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
            <div class="empty-title"><?= $isRu ? 'Нет отзывов' : 'Пікір жоқ' ?></div>
          </div>
        </div>
      </div>

      <!-- Portfolio -->
      <div class="card mt-12">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
          <div>
            <div class="h3"><?= $isRu ? 'Портфолио' : 'Портфолио' ?></div>
            <div class="txt-xs mt-8" id="portfolioCount" style="opacity:.6;">0/12</div>
          </div>
          <label class="cta-btn btn-sm" style="cursor:pointer;width:auto;">
            <svg viewBox="0 0 24 24" style="width:14px;height:14px;" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            <?= $isRu ? 'Добавить' : 'Фото қосу' ?>
            <input type="file" accept="image/*" style="display:none;" onchange="uploadPortfolioPhoto(this)">
          </label>
        </div>
        <div style="display:flex;gap:8px;align-items:center;margin-bottom:10px;">
          <input type="text" id="portfolioCaptionInput" placeholder="<?= $isRu ? 'Описание к фото...' : 'Сурет сипаттамасы...' ?>" class="auth-input"
            style="flex:1;font-size:12px;padding:9px 14px;" maxlength="255">
          <button type="button" onclick="savePortfolioCaption()" class="cta-btn btn-sm" style="flex-shrink:0;white-space:nowrap;">
            <?= $isRu ? 'Сохранить' : 'Сақтау' ?>
          </button>
        </div>
        <div id="portfolioGrid"></div>
      </div>

      <!-- Logout / Switch role -->
      <button class="cta-btn btn-ghost mt-16" type="button" onclick="setTab('settings')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        <span data-i18n="settings"><?= $isRu ? 'Настройки' : 'Баптаулар' ?></span>
      </button>
    </div>
    <!-- /tab-profile -->

    <!-- ── TAB: SETTINGS ──────────────────────────────────── -->
    <div id="tab-settings" class="tab-content" style="padding-bottom:60px;">
      <div style="margin-bottom:20px;">
        <div class="h2" data-i18n="settings"><?= $isRu ? 'Настройки' : 'Баптаулар' ?></div>
        <div class="txt-sm mt-8" style="opacity:.7;" data-i18n="settingsSub"><?= $isRu ? 'Параметры приложения' : 'Қосымша параметрлер' ?></div>
      </div>

      <div class="setting-group">
        <div class="setting-row">
          <div class="setting-label">
            <span class="setting-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>
            </span>
            <span data-i18n="darkMode"><?= $isRu ? 'Ночной режим' : 'Түнгі режим' ?></span>
          </div>
          <label class="switch">
            <input type="checkbox" id="themeToggle" onchange="toggleTheme()">
            <span class="slider"></span>
          </label>
        </div>

        <div class="setting-row">
          <div class="setting-label">
            <span class="setting-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
            </span>
            <span data-i18n="language"><?= $isRu ? 'Язык' : 'Тіл' ?></span>
          </div>
          <div class="lang-switch">
            <div class="lang-opt" id="lang-kk" onclick="setLanguage('kk')">KZ</div>
            <div class="lang-opt" id="lang-ru" onclick="setLanguage('ru')">RU</div>
          </div>
        </div>
      </div>

      <div class="setting-group">
        <div class="setting-row" onclick="openProfileEdit()" style="cursor:pointer;">
          <div class="setting-label">
            <span class="setting-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </span>
            <span><?= $isRu ? 'Редактировать профиль' : 'Профильді өңдеу' ?></span>
          </div>
          <svg viewBox="0 0 24 24" style="width:16px;height:16px;opacity:.4;" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
        </div>

        <!-- Подписка и баланс — временно отключены (бесплатный период)
        <div class="setting-row" onclick="window.location.href='subscription-master.php'" style="cursor:pointer;">...</div>
        <div class="setting-row" onclick="window.location.href='payment-master.php'" style="cursor:pointer;">...</div>
        -->
      </div>

      <div class="setting-group">
        <div class="setting-row" onclick="logout()" style="cursor:pointer;">
          <div class="setting-label" style="color:var(--danger);">
            <span class="setting-icon" style="color:var(--danger);">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            </span>
            <?= $isRu ? 'Выйти' : 'Шығу' ?>
          </div>
        </div>
      </div>
    </div>
    <!-- /tab-settings -->

  </div><!-- /.app-container -->

  <!-- ── ORDER CHAT MODAL ────────────────────────────────── -->
  <div class="ai-modal" id="orderChatModal">
    <div class="ai-header" style="gap:10px;padding-top:24px;">
      <div style="display:flex;flex-direction:column;gap:2px;min-width:0;flex:1;">
        <div style="font-weight:800;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;" id="orderChatTitle">Чат</div>
        <div class="txt-sm" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;" id="orderChatSub">—</div>
      </div>
      <div style="display:flex;gap:7px;align-items:center;flex-shrink:0;">
        <button class="cta-btn btn-sm btn-success" id="orderAcceptBtn" style="display:none;" onclick="acceptCurrentOrder()">
          <span data-i18n="accept"><?= $isRu ? 'Принять' : 'Қабылдау' ?></span>
        </button>
        <button class="cta-btn btn-sm" id="orderFinishBtn" style="display:none;" onclick="finishCurrentOrder()">
          <?= $isRu ? 'Завершить' : 'Аяқтау' ?>
        </button>
        <button class="ai-close" type="button" onclick="closeOrderChat()">
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2.5" fill="none"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
    </div>

    <div id="orderInfoBox" style="padding:10px 16px;border-top:1px solid var(--border);border-bottom:1px solid var(--border);background:var(--surface-2);">
      <div class="txt-sm" id="orderInfoText" style="line-height:1.4;">—</div>
      <div id="orderMapWrap" style="margin-top:8px;display:none;">
        <div id="orderMap" style="height:170px;width:100%;border-radius:var(--radius-md);overflow:hidden;"></div>
        <div class="txt-xs" id="orderMapHint" style="margin-top:5px;opacity:.6;">GPS</div>
      </div>
    </div>

    <div class="chat-container" id="orderChatContainer"></div>

    <div class="modal-input-area" style="gap:7px;">
      <label class="chat-attach-btn" title="Фото">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
        <input type="file" accept="image/*" style="display:none;" onchange="sendChatImage(this)">
      </label>
      <input type="text" class="chat-input" id="orderChatInput" placeholder="<?= $isRu ? 'Написать сообщение...' : 'Хабарлама жазыңыз...' ?>" style="flex:1;min-width:0;">
      <button id="voiceRecordBtn" type="button" onclick="toggleVoiceRecord(this)" class="chat-attach-btn">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M19 10a7 7 0 0 1-14 0"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>
      </button>
      <button class="send-btn" type="button" id="orderSendBtn" onclick="sendOrderMessage()">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
      </button>
    </div>
  </div>

  <!-- ── AI MODAL ────────────────────────────────────────── -->
  <div class="ai-float-btn" onclick="toggleAIChat()" title="Sheber AI">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
    </svg>
  </div>

  <div class="ai-modal" id="aiModal">
    <div class="ai-header" style="padding-top:24px;">
      <div>
        <div style="font-weight:800;font-size:16px;">Sheber AI</div>
        <div class="txt-sm mt-8" style="opacity:.7;"><?= $isRu ? 'Умный помощник' : 'Ақылды көмекші' ?></div>
      </div>
      <button class="ai-close" type="button" onclick="toggleAIChat()">
        <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2.5" fill="none"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="chat-container" id="chatContainer">
      <div class="chat-bubble chat-ai">
        <?= $isRu ? 'Привет! Я AI-помощник Sheber.kz.<br><br>Возник спор с клиентом или вопрос по цене?' : 'Сәлем! Мен Sheber.kz AI көмекшісімін.<br><br>Клиентпен дау туындады ма?' ?>
      </div>
    </div>
    <div class="modal-input-area">
      <input type="text" class="chat-input" id="chatInput" data-i18n-placeholder="aiPlaceholder" placeholder="<?= $isRu ? 'Напишите вопрос...' : 'Сұрағыңызды жазыңыз...' ?>">
      <button class="send-btn" type="button" id="sendBtn" onclick="sendMessage()">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
      </button>
    </div>
  </div>

  <!-- ── BOTTOM NAV ──────────────────────────────────────── -->
  <nav class="nav-island" role="navigation">
    <div class="nav-btn active" id="nav-home" onclick="setTab('home')" title="Главная">
      <svg viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
    </div>
    <div class="nav-btn" id="nav-messages" onclick="setTab('messages')" title="Сообщения" style="position:relative;">
      <svg viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      <span class="nav-badge" id="msgBadge" style="display:none;">0</span>
    </div>
    <div class="nav-fab" onclick="primaryAction()" title="Быстрое действие">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
    </div>
    <div class="nav-btn" id="nav-courses" onclick="setTab('courses')" title="Заказы">
      <svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
    </div>
    <div class="nav-btn" id="nav-profile" onclick="setTab('profile')" title="Профиль">
      <svg viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
    </div>
  </nav>

  <!-- ── SIDEBAR ─────────────────────────────────────────── -->
  <div class="sidebar-overlay" id="overlay" onclick="toggleMenu()"></div>
  <aside class="sidebar" id="sidebar" role="complementary">
    <div class="sidebar-header">
      <div class="avatar avatar-xl" id="sideAvatar"
        style="background:<?= e($user['avatar_color'] ?? '#2563EB') ?>;<?= !empty($user['avatar_url']) ? 'background-image:url(\''.e($user['avatar_url']).'\');background-size:cover;background-position:center;' : '' ?>">
        <?= empty($user['avatar_url']) ? e($initial) : '' ?>
      </div>
      <div class="h3 mt-12" id="sideName"><?= e($user['name'] ?? 'Шебер') ?></div>
      <div class="txt-sm mt-8" id="sideRole" style="opacity:.7;"><?= e($user['profession'] ?: ($isRu ? 'Мастер' : 'Шебер')) ?> · <?= e($user['city'] ?? 'Алматы') ?></div>
    </div>

    <ul style="list-style:none;padding:0;display:flex;flex-direction:column;gap:3px;">
      <li class="menu-item" onclick="setTab('home');toggleMenu();">
        <span class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></span>
        <span data-i18n="home"><?= $isRu ? 'Главная' : 'Басты бет' ?></span>
      </li>
      <li class="menu-item" onclick="toggleAIChat();toggleMenu();">
        <span class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg></span>
        <span>Sheber AI</span>
      </li>
      <li class="menu-item" onclick="setTab('messages');toggleMenu();">
        <span class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg></span>
        <span data-i18n="messages"><?= $isRu ? 'Сообщения' : 'Хабарламалар' ?></span>
      </li>
      <li class="menu-item" onclick="setTab('courses');toggleMenu();">
        <span class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg></span>
        <span><?= $isRu ? 'Заказы' : 'Тапсырыстар' ?></span>
      </li>
      <li class="menu-item" onclick="setTab('settings');toggleMenu();">
        <span class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33"/></svg></span>
        <span data-i18n="settings"><?= $isRu ? 'Настройки' : 'Баптаулар' ?></span>
      </li>
    </ul>

    <div style="margin-top:auto;opacity:.3;text-align:center;font-size:11px;font-weight:700;">© Sheber.kz</div>
  </aside>

  <!-- ── PROFILE EDIT SHEET ──────────────────────────────── -->
  <div class="sheet-modal" id="profileEditModal" style="height:92vh;z-index:2400;">
    <div class="sheet-header">
      <div style="font-weight:800;font-size:15px;"><?= $isRu ? 'Редактировать профиль' : 'Профильді өңдеу' ?></div>
      <button class="ai-close" type="button" onclick="closeProfileEdit()">
        <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2.5" fill="none"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="sheet-body" style="overflow-y:auto;flex:1;padding-bottom:60px;">

      <!-- Avatar picker -->
      <div class="prof-edit-section">
        <label class="prof-edit-label"><?= $isRu ? 'Аватар' : 'Аватар' ?></label>
        <div class="avatar-picker-row">
          <div class="av-preview" id="avPreview"
            style="background:<?= e($user['avatar_color'] ?? '#2563EB') ?>;<?= !empty($user['avatar_url']) ? 'background-image:url(\''.e($user['avatar_url']).'\');background-size:cover;background-position:center;' : '' ?>"
            onclick="document.getElementById('avatarUploadInput').click()">
            <div id="avPreviewText"><?= empty($user['avatar_url']) ? e($initial) : '' ?></div>
            <div style="position:absolute;bottom:0;right:0;background:var(--surface);border-radius:50%;width:22px;height:22px;display:flex;align-items:center;justify-content:center;box-shadow:0 1px 4px rgba(0,0,0,.25);">
              <svg viewBox="0 0 24 24" width="12" height="12" stroke="var(--text-main)" stroke-width="2" fill="none"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
            </div>
          </div>
          <input type="file" id="avatarUploadInput" accept="image/*" style="display:none;" onchange="uploadAvatarFile(this)">
          <div class="av-colors">
            <?php
              $avatarColors = ['#2563EB','#2EC4B6','#EF4444','#F97316','#9B51E0','#16A34A','#DB2777','#D97706','#0891B2','#65A30D','#7C3AED','#DC2626'];
              foreach ($avatarColors as $c):
            ?>
              <div class="av-dot<?= ($user['avatar_color'] ?? '#2563EB') === $c ? ' selected' : '' ?>"
                style="background:<?= e($c) ?>;" data-color="<?= e($c) ?>" onclick="pickAvatarColor('<?= e($c) ?>')"></div>
            <?php endforeach; ?>
          </div>
        </div>
      </div>

      <form id="profileEditForm" onsubmit="profileEditSubmit(event)" autocomplete="off">
        <input type="hidden" id="peAvatarColor" name="avatar_color" value="<?= e($user['avatar_color'] ?? '#2563EB') ?>">

        <div class="prof-edit-section">
          <label class="prof-edit-label" for="peName"><?= $isRu ? 'Имя *' : 'Аты *' ?></label>
          <input class="auth-input" id="peName" name="name" type="text" value="<?= e($user['name'] ?? '') ?>" placeholder="<?= $isRu ? 'Полное имя' : 'Аты-жөні' ?>" required maxlength="80">
        </div>
        <div class="prof-edit-section">
          <label class="prof-edit-label"><?= $isRu ? 'Город' : 'Қала' ?></label>
          <div id="masterCityDropdown" style="position:relative;">
            <button type="button" id="masterCityBtn" onclick="toggleMasterCityList()"
              style="width:100%;padding:12px 14px;text-align:left;background:var(--surface-highlight);border:1.5px solid transparent;border-radius:var(--radius-md);color:var(--text-main);font-family:var(--font-main);font-size:14px;cursor:pointer;display:flex;justify-content:space-between;align-items:center;">
              <span id="masterCityLabel"><?= e($user['city'] ?? ($isRu ? 'Выберите город' : 'Қаланы таңдаңыз')) ?></span>
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none"><polyline points="6 9 12 15 18 9"/></svg>
            </button>
            <div id="masterCityList" style="display:none;position:absolute;top:calc(100% + 4px);left:0;right:0;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-md);z-index:100;max-height:220px;overflow-y:auto;box-shadow:0 8px 24px rgba(0,0,0,.2);">
              <div style="padding:8px;">
                <input type="text" placeholder="<?= $isRu ? 'Поиск...' : 'Іздеу...' ?>"
                  style="width:100%;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--surface-highlight);color:var(--text-main);font-family:var(--font-main);font-size:13px;box-sizing:border-box;"
                  oninput="filterMasterCities(this.value)">
              </div>
              <div id="masterCityCheckboxes" style="padding:0 8px 8px;">
                <?php
                $kzCities = ['Алматы','Астана','Шымкент','Қарағанды','Ақтөбе','Тараз','Павлодар','Өскемен','Семей','Атырау','Қостанай','Ақтау','Орал','Қызылорда','Петропавл','Көкшетау','Талдықорған','Балқаш','Жезқазған','Жаңаөзен','Теміртау','Риддер','Екібастұз','Лисаковск','Рудный','Степногорск','Сарыағаш','Түркістан','Шу','Хромтау','Қапшағай','Үштөбе','Ленгер','Жаркент','Форт-Шевченко'];
                foreach ($kzCities as $kzCity):
                ?>
                <label style="display:flex;align-items:center;gap:8px;padding:8px 6px;cursor:pointer;border-radius:6px;font-size:13px;" class="master-city-option"
                  onmouseover="this.style.background='var(--surface-highlight)'" onmouseout="this.style.background=''">
                  <input type="radio" value="<?= e($kzCity) ?>" style="accent-color:var(--primary);width:16px;height:16px;flex-shrink:0;"
                    <?= ($user['city'] ?? '') === $kzCity ? 'checked' : '' ?>
                    onchange="onMasterCityPick('<?= e($kzCity) ?>')">
                  <?= e($kzCity) ?>
                </label>
                <?php endforeach; ?>
              </div>
            </div>
          </div>
          <input type="hidden" id="peCity" name="city" value="<?= e($user['city'] ?? '') ?>">
        </div>
        <div class="prof-edit-section">
          <label class="prof-edit-label"><?= $isRu ? 'Профессия' : 'Мамандығы' ?></label>
          <input type="text" id="masterProfSearch" placeholder="<?= $isRu ? 'Поиск...' : 'Іздеу...' ?>"
            style="width:100%;padding:10px 12px;border:1.5px solid var(--border);border-radius:var(--radius-md);background:var(--surface-highlight);color:var(--text-main);font-family:var(--font-main);font-size:13px;box-sizing:border-box;margin-bottom:6px;"
            oninput="filterMasterProf(this.value)">
          <div id="masterProfCheckboxes" style="max-height:200px;overflow-y:auto;border:1px solid var(--border);border-radius:var(--radius-md);background:var(--surface-highlight);">
            <?php
            $professions = [
              'Сантехник','Электрик','Сварщик','Плиточник','Маляр','Штукатур',
              'Плотник','Столяр','Кровельщик','Мастер по окнам / дверям',
              'Мастер по полам','Монтажник натяжных потолков','Отделочник',
              'Разнорабочий','Грузчик','Водитель / Перевозки','Мастер по мебели',
              'Мастер по технике','Компьютерный мастер','Установка кондиционеров',
              'Уборщик / Клинер','Домработница','Садовник / Озеленение',
              'Репетитор','Массажист','Парикмахер / Барбер','Фотограф',
              'Дизайнер интерьера','Строитель','Бетонщик','Каменщик',
              'Монтажник','Слесарь','Токарь','Сигнализация / Камеры','Замочник',
            ];
            foreach ($professions as $prof):
            ?>
            <label style="display:flex;align-items:center;gap:10px;padding:10px 12px;cursor:pointer;border-bottom:1px solid var(--border);font-size:13px;font-weight:500;" class="master-prof-option"
              onmouseover="this.style.background='var(--border)'" onmouseout="this.style.background=''">
              <input type="radio" name="prof_pick" value="<?= e($prof) ?>"
                style="accent-color:var(--primary);width:17px;height:17px;flex-shrink:0;"
                <?= ($user['profession'] ?? '') === $prof ? 'checked' : '' ?>
                onchange="onMasterProfPick('<?= e($prof) ?>')">
              <?= e($prof) ?>
            </label>
            <?php endforeach; ?>
          </div>
          <input type="hidden" id="peProfession" name="profession" value="<?= e($user['profession'] ?? '') ?>">
        </div>
        <div class="prof-edit-section">
          <label class="prof-edit-label" for="peExperience"><?= $isRu ? 'Стаж (лет)' : 'Тәжірибе (жыл)' ?></label>
          <input class="auth-input" id="peExperience" name="experience" type="number" value="<?= e((string)(int)($user['experience'] ?? 0)) ?>" min="0" max="80" placeholder="0" inputmode="numeric" style="max-width:120px;">
        </div>
        <div class="prof-edit-section">
          <label class="prof-edit-label" for="pePhone"><?= $isRu ? 'Телефон' : 'Телефон' ?></label>
          <input class="auth-input" id="pePhone" name="phone" type="tel" value="<?= e($user['phone'] ?? '') ?>" placeholder="+7 ___ ___-__-__" maxlength="32">
        </div>
        <div class="prof-edit-section">
          <label class="prof-edit-label" for="peBio">
            <?= $isRu ? 'О себе' : 'Өзім туралы' ?>
            <span id="peBioCount" style="float:right;color:var(--text-sec);font-weight:600;"><?= mb_strlen($user['bio'] ?? '') ?>/500</span>
          </label>
          <textarea class="auth-input" id="peBio" name="bio" rows="4" placeholder="<?= $isRu ? 'Несколько слов о себе...' : 'Өз мамандығым туралы...' ?>" maxlength="500"><?= e($user['bio'] ?? '') ?></textarea>
        </div>

        <button class="cta-btn" type="submit" id="profileSaveBtn">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
          <?= $isRu ? 'Сохранить' : 'Сақтау' ?>
        </button>

        <button class="cta-btn btn-ghost mt-12" type="button" onclick="switchRole('client')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          <span data-i18n="switchToClient"><?= $isRu ? 'Стать клиентом' : 'Клиентке ауысу' ?></span>
        </button>
      </form>
    </div>
  </div>
  <div class="sheet-overlay" id="profileEditOverlay" onclick="closeProfileEdit()"></div>

  <!-- ── SMS VERIFY MODAL ────────────────────────────────── -->
  <div id="smsVerifyOverlay"></div>
  <div id="smsVerifyModal" style="padding:24px;">
    <div style="text-align:center;margin-bottom:20px;">
      <div style="font-size:32px;margin-bottom:8px;">📱</div>
      <div class="h3" style="color:var(--text-main);"><?= $isRu ? 'Подтверждение номера' : 'Нөмірді растау' ?></div>
    </div>
    <div id="sms-step-phone">
      <p class="txt-sm" style="margin-bottom:14px;text-align:center;"><?= $isRu ? 'Введите номер телефона:' : 'Телефон нөмірін енгізіңіз:' ?></p>
      <input id="verifyPhoneInput" type="tel" placeholder="+7 (7xx) xxx-xx-xx" class="auth-input" style="text-align:center;font-size:18px;font-weight:700;letter-spacing:1px;">
      <button class="cta-btn" id="btn-verify-send" onclick="handleSendVerificationCode()" style="margin-top:14px;">
        <?= $isRu ? 'Получить код' : 'Код алу' ?>
      </button>
      <button onclick="handleAuthLater()"
        style="width:100%;margin-top:10px;padding:10px;background:transparent;color:var(--text-muted);border:none;font-size:13px;cursor:pointer;font-family:var(--font-main);">
        <?= $isRu ? 'Подтвердить позже' : 'Кейінірек растау' ?>
      </button>
    </div>
    <div id="sms-step-code" style="display:none;">
      <p class="txt-sm" style="text-align:center;margin-bottom:4px;"><?= $isRu ? 'Код отправлен на:' : 'Код жіберілді:' ?></p>
      <p style="text-align:center;font-weight:800;margin-bottom:18px;" id="verify-display-phone"></p>
      <div id="verify-code-inputs" style="display:flex;gap:10px;justify-content:center;margin-bottom:14px;">
        <input class="code-input" type="text" maxlength="1" inputmode="numeric">
        <input class="code-input" type="text" maxlength="1" inputmode="numeric">
        <input class="code-input" type="text" maxlength="1" inputmode="numeric">
        <input class="code-input" type="text" maxlength="1" inputmode="numeric">
      </div>
      <p class="txt-sm" style="text-align:center;margin-bottom:14px;"><?= $isRu ? 'Повтор через' : 'Қайтадан' ?> <span id="verify-timer-count">180</span> <?= $isRu ? 'сек.' : 'сек.' ?></p>
      <button class="cta-btn" id="btn-verify-confirm" onclick="handleVerifyAccountCode()"><?= $isRu ? 'Подтвердить' : 'Растау' ?></button>
      <button onclick="handleAuthLater()" style="width:100%;margin-top:10px;padding:10px;background:transparent;color:var(--text-muted);border:none;font-size:13px;cursor:pointer;font-family:var(--font-main);">
        <?= $isRu ? 'Отмена' : 'Бас тарту' ?>
      </button>
    </div>
  </div>

  <div id="toast" class="toast"></div>

  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" crossorigin=""></script>
<script>
// Сохранение описания портфолио без фото
function savePortfolioCaption() {
  const input = document.getElementById('portfolioCaptionInput');
  if (!input || !input.value.trim()) {
    showToast(getLang() === 'ru' ? 'Введите описание' : 'Сипаттама енгізіңіз');
    return;
  }
  showToast(getLang() === 'ru' ? '✅ Описание обновлено' : '✅ Сипаттама жаңартылды');
}

// City picker для профиля мастера
function toggleMasterCityList() {
  const list = document.getElementById('masterCityList');
  list.style.display = list.style.display === 'none' ? 'block' : 'none';
  if (list.style.display === 'block') list.querySelector('input').focus();
}
function onMasterCityPick(name) {
  document.getElementById('masterCityLabel').textContent = name;
  document.getElementById('peCity').value = name;
  document.getElementById('masterCityList').style.display = 'none';
}
function filterMasterCities(q) {
  q = q.toLowerCase();
  document.querySelectorAll('.master-city-option').forEach(el => {
    el.style.display = el.textContent.trim().toLowerCase().includes(q) ? '' : 'none';
  });
}
// Profession picker
function toggleMasterProfList() {
  const list = document.getElementById('masterProfList');
  list.style.display = list.style.display === 'none' ? 'block' : 'none';
  if (list.style.display === 'block') list.querySelector('input').focus();
}
function onMasterProfPick(name) {
  document.getElementById('masterProfLabel').textContent = name;
  document.getElementById('peProfession').value = name;
  document.getElementById('masterProfList').style.display = 'none';
}
function filterMasterProf(q) {
  q = q.toLowerCase();
  document.querySelectorAll('.master-prof-option').forEach(el => {
    el.style.display = el.textContent.trim().toLowerCase().includes(q) ? '' : 'none';
  });
}
document.addEventListener('click', e => {
  const dd = document.getElementById('masterCityDropdown');
  if (dd && !dd.contains(e.target)) {
    const list = document.getElementById('masterCityList');
    if (list) list.style.display = 'none';
  }
  const pd = document.getElementById('masterProfDropdown');
  if (pd && !pd.contains(e.target)) {
    const list = document.getElementById('masterProfList');
    if (list) list.style.display = 'none';
  }
});
</script>
</body>
</html>