<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

$user = current_user($pdo);
$isLoggedIn = (bool)$user;

if ($isLoggedIn && (string)$user['role'] === 'master' && !isset($_GET['stay'])) {
  redirect('home-master.php');
}

$jsUser = $isLoggedIn ? [
  'id'           => (int)$user['id'],
  'name'         => (string)$user['name'],
  'city'         => (string)$user['city'],
  'role'         => (string)$user['role'],
  'avatar_url'   => (string)($user['avatar_url'] ?? ''),
  'avatar_color' => (string)($user['avatar_color'] ?? '#1cb7ff'),
  'profession'   => (string)($user['profession'] ?? ''),
  'experience'   => (int)($user['experience'] ?? 0),
  'phone'        => (string)($user['phone'] ?? ''),
  'bio'          => (string)($user['bio'] ?? ''),
] : null;

$displayName = $isLoggedIn ? (string)$user['name'] : '';
$displayCity = $isLoggedIn ? (string)$user['city'] : '';
$initial     = mb_strtoupper(mb_substr(trim($displayName ?: 'A'), 0, 1)) ?: 'A';

$profileData = null;
if ($isLoggedIn) {
  $uid  = (int)$user['id'];
  $role = (string)$user['role'];
  $stats = ['orders' => 0, 'rating_avg' => null, 'rating_count' => 0, 'bonus' => 0];
  try {
    if ($role === 'master') {
      $st = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE master_id = ?"); $st->execute([$uid]); $stats['orders'] = (int)$st->fetchColumn();
      $st = $pdo->prepare("SELECT COALESCE(SUM(price),0) FROM orders WHERE master_id=? AND status='completed'"); $st->execute([$uid]); $stats['bonus'] = (int)$st->fetchColumn();
      $st = $pdo->prepare("SELECT AVG(rating) AS a, COUNT(*) AS c FROM reviews WHERE master_id=?"); $st->execute([$uid]); $r = $st->fetch() ?: [];
      $stats['rating_avg']   = isset($r['a']) ? (float)$r['a'] : null;
      $stats['rating_count'] = isset($r['c']) ? (int)$r['c']   : 0;
    } else {
      $st = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE client_id=?"); $st->execute([$uid]); $stats['orders'] = (int)$st->fetchColumn();
      $st = $pdo->prepare("SELECT COALESCE(SUM(price),0) FROM orders WHERE client_id=? AND status='completed'"); $st->execute([$uid]); $stats['bonus'] = (int)$st->fetchColumn();
    }
  } catch (Throwable) {}

  // Загружаем последние заказы для секции «Недавние услуги» в профиле
  $recentOrders = [];
  try {
    $recentField = $role === 'master' ? 'master_id' : 'client_id';
    $otherName   = $role === 'master' ? 'COALESCE(c.name,\'\') AS other_name' : 'COALESCE(m.name,\'\') AS other_name';
    $otherJoin   = $role === 'master'
      ? 'LEFT JOIN users c ON c.id = o.client_id'
      : 'LEFT JOIN users m ON m.id = o.master_id';
    $stRec = $pdo->prepare(
      "SELECT o.id, COALESCE(mc.name, o.description, 'Услуга') AS service_title,
              o.price, o.status, o.created_at, o.completed_at,
              {$otherName}
       FROM orders o
       LEFT JOIN master_categories mc ON mc.id = o.category_id
       {$otherJoin}
       WHERE o.{$recentField} = ?
       ORDER BY o.created_at DESC LIMIT 5"
    );
    $stRec->execute([$uid]);
    $recentOrders = $stRec->fetchAll() ?: [];
  } catch (Throwable) {}

  $profileData = ['role' => $role, 'stats' => $stats, 'recent_orders' => $recentOrders];
}

$lang = lang_get();
$csrf = csrf_token();
$avatarColors = ['#1cb7ff','#2EC4B6','#FF6B6B','#F2994A','#9B51E0','#27AE60','#EB5757','#F2C94C','#2D9CDB','#6FCF97','#F97316','#8B5CF6'];

// Список городов для фильтра и регистрации (определяем глобально)
$cities = ['Алматы','Астана','Шымкент','Қызылорда'];
?>
<!DOCTYPE html>
<html lang="<?= e($lang) ?>" data-theme="<?= e(theme_get()) ?>">
<head>
  <script src="/assets/js/prefs.js"></script>
  <script>Prefs.applyThemeASAP();</script>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
  <title>Sheber.kz</title>
  <link rel="icon" type="image/png" sizes="32x32" href="favicon.png">
  <link rel="apple-touch-icon" href="favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="index.css?v=20">
  <meta name="csrf-token" content="<?= e($csrf) ?>">
  <script src="index.js?v=<?= filemtime(__DIR__.'/index.js') ?>" defer></script>
</head>

<body class="<?= ($isLoggedIn && (string)$user['role'] === 'master') ? 'role-master' : 'role-client' ?>">
<div class="app-container">

  <script>
    window.__SERVER_USER  = <?= json_encode($jsUser, JSON_UNESCAPED_UNICODE) ?>;
    window.__PROFILE_DATA = <?= json_encode($profileData, JSON_UNESCAPED_UNICODE) ?>;
    if (window.__SERVER_USER) {
      localStorage.setItem('sheber_user', JSON.stringify(window.__SERVER_USER));
    } else {
      localStorage.removeItem('sheber_user');
    }
  </script>

  <!-- ── Header ─────────────────────────────────────── -->
  <header class="header">
    <div class="brand">
      <button class="menu-btn" type="button" onclick="toggleMenu()">
        <svg viewBox="0 0 24 24" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
          <line x1="3" y1="6"  x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
        </svg>
      </button>
      <span style="font-weight:800;font-size:16px;">Sheber<span style="color:#0069ff">.kz</span></span>
    </div>
    <button class="menu-btn" type="button" id="notifBtn" onclick="primaryAction()" title="<?= $lang==='ru'?'Найти мастера':'Шебер іздеу' ?>">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
      </svg>
    </button>
  </header>

  <!-- ══════════════ HOME ══════════════ -->
  <div id="tab-home" class="tab-content active">

    <!-- Greeting -->
    <div class="hero">
      <div class="greeting">
        <div class="h1" id="greetingH1"><?= $lang==='ru'?'Привет! 👋':'Сәлем! 👋' ?></div>
        <div class="txt-sm sub" data-key="heroSub"></div>
      </div>
    </div>

    <!-- Urgent card -->
    <div class="card card-glow" style="padding:20px;margin-bottom:24px;">
      <div class="tag" style="background:rgba(37,99,235,.12);color:var(--primary);margin-bottom:12px;">
        <?= $lang==='ru'?'🔍 Бесплатный поиск':'🔍 Тегін іздеу' ?>
      </div>
      <div class="h2" style="margin-bottom:8px;"><?= $lang==='ru'?'Найдите мастера рядом с вами':'Жаныңыздағы шеберді табыңыз' ?></div>
      <div class="txt-sm" style="margin-bottom:18px;opacity:.75;line-height:1.55;">
        <?= $lang==='ru'
          ? 'Выберите ваш город — и мы покажем всех зарегистрированных мастеров с контактами для прямой связи.'
          : 'Қалаңызды таңдаңыз — тікелей байланыс контакттерімен барлық тіркелген шеберлерді көрсетеміз.' ?>
      </div>
      <button class="cta-btn" onclick="primaryAction()" style="margin-top:0;font-size:16px;padding:14px 20px;">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="width:20px;height:20px;">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <span><?= $lang==='ru'?'Найти мастера':'Шебер табу' ?></span>
      </button>
      <div class="txt-sm" style="margin-top:10px;opacity:.55;text-align:center;font-size:12px;">
        <?= $lang==='ru'?'Регистрация не нужна — поиск бесплатный':'Тіркелу қажет емес — іздеу тегін' ?>
      </div>
    </div>

    <!-- How it works section -->
    <div class="section-head" style="margin-bottom:14px;">
      <div class="h3"><?= $lang==='ru'?'Как это работает':'Қалай жұмыс істейді' ?></div>
    </div>
    <div style="display:flex;flex-direction:column;gap:10px;margin-bottom:8px;">
      <div style="display:flex;align-items:center;gap:14px;padding:14px 16px;background:var(--surface-highlight);border:1px solid var(--border);border-radius:16px;">
        <div style="width:40px;height:40px;border-radius:12px;background:rgba(59,130,246,.12);display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:18px;">1️</div>
        <div>
          <div style="font-weight:700;font-size:14px;margin-bottom:2px;"><?= $lang==='ru'?'Выберите город':'Қаланы таңдаңыз' ?></div>
          <div class="txt-sm" style="opacity:.6;"><?= $lang==='ru'?'Нажмите кнопку «Найти мастера»':'«Шебер табу» батырмасын басыңыз' ?></div>
        </div>
      </div>
      <div style="display:flex;align-items:center;gap:14px;padding:14px 16px;background:var(--surface-highlight);border:1px solid var(--border);border-radius:16px;">
        <div style="width:40px;height:40px;border-radius:12px;background:rgba(46,196,182,.12);display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:18px;">2️</div>
        <div>
          <div style="font-weight:700;font-size:14px;margin-bottom:2px;"><?= $lang==='ru'?'Смотрите мастеров':'Шеберлерді қараңыз' ?></div>
          <div class="txt-sm" style="opacity:.6;"><?= $lang==='ru'?'Рейтинг, опыт и отзывы':'Рейтинг, тәжірибе және пікірлер' ?></div>
        </div>
      </div>
      <div style="display:flex;align-items:center;gap:14px;padding:14px 16px;background:var(--surface-highlight);border:1px solid var(--border);border-radius:16px;">
        <div style="width:40px;height:40px;border-radius:12px;background:rgba(39,174,96,.12);display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:18px;">3️</div>
        <div>
          <div style="font-weight:700;font-size:14px;margin-bottom:2px;"><?= $lang==='ru'?'Свяжитесь напрямую':'Тікелей байланысыңыз' ?></div>
          <div class="txt-sm" style="opacity:.6;"><?= $lang==='ru'?'Звонок или WhatsApp':'Қоңырау немесе WhatsApp' ?></div>
        </div>
      </div>
    </div>

  </div><!-- /#tab-home -->

  <!-- ══════════════ MASTERS SEARCH RESULTS ══════════════ -->
  <div id="tab-courses" class="tab-content" style="padding-bottom:80px;">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;">
      <div>
        <div class="h2" style="margin-bottom:2px;"><?= $lang==='ru'?'Мастера':'Шеберлер' ?></div>
        <div class="txt-sm" id="mastersSearchCount" style="opacity:.6;">
          <?= $lang==='ru'?'Выберите город для поиска':'Іздеу үшін қаланы таңдаңыз' ?>
        </div>
      </div>

    </div>

    <div class="card" style="padding:14px 16px;margin-bottom:14px;">
      <div style="display:flex;align-items:center;gap:12px;">
        <div style="width:42px;height:42px;border-radius:12px;background:var(--primary-dim);display:flex;align-items:center;justify-content:center;flex-shrink:0;">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="var(--primary)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/><circle cx="12" cy="9" r="2.5"/></svg>
        </div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;opacity:.45;margin-bottom:2px;"><?= $lang==='ru'?'Город':'Қала' ?></div>
          <div class="h3" id="mastersSearchSelectedCity" style="margin:0;font-size:17px;"><?= $lang==='ru'?'Не выбран':'Таңдалмаған' ?></div>
        </div>
        <button type="button" onclick="primaryAction()" style="padding:8px 14px;border-radius:10px;border:1.5px solid var(--primary);background:transparent;color:var(--primary);font-weight:700;font-size:13px;cursor:pointer;font-family:var(--font-main);white-space:nowrap;">
          <?= $lang==='ru'?'Выбрать':'Таңдау' ?>
        </button>
      </div>
    </div>

    <div id="mastersList"></div>
  </div>

  <!-- ══════════════ MESSAGES ══════════════ -->
  <div id="tab-messages" class="tab-content" style="padding-bottom:80px;">
    <div style="text-align:center;margin-bottom:20px;">
      <div class="h3" data-key="messages">—</div>
      <div class="txt-sm" data-key="chatSub" style="opacity:.6;">—</div>
    </div>

    <div id="ordersList"></div>

    <div class="section-head" style="margin-top:20px;">
      <div class="h3" data-key="support">—</div>
    </div>
    <div class="msg-item" onclick="toggleAIChat()">
      <div class="msg-av" style="background-image:url('https://api.dicebear.com/7.x/bottts/svg?seed=Support');background-color:var(--surface-highlight);"></div>
      <div class="msg-content">
        <div class="msg-top">
          <div class="msg-name" data-key="supportName">Sheber AI</div>
          <div class="msg-time">AI</div>
        </div>
        <div class="msg-text" style="color:var(--primary);" data-key="supportHint">—</div>
      </div>
    </div>
  </div>

  <!-- ══════════════ PROFILE ══════════════ -->
  <div id="tab-profile" class="tab-content" style="padding-bottom:80px;">
    <div style="text-align:center;margin-bottom:16px;">
      <div class="h3" data-key="profile">—</div>
      <div class="txt-sm" data-key="profileSub" style="opacity:.6;">—</div>
    </div>

    <?php if (!$isLoggedIn): ?>
      <div class="card auth-card" style="padding:24px;">
        <div class="tag" style="background:rgba(28,183,255,.1);color:var(--primary);margin-bottom:16px;" data-key="authTag">—</div>

        <!-- SMS login CTA — временно отключено
        <button onclick="openSmsModal()" class="cta-btn" style="margin-bottom:14px;">
          📱 <?= $lang==='ru'?'Войти через телефон':'Телефон арқылы кіру' ?>
        </button>
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:14px;">
          <div style="flex:1;height:1px;background:var(--border);"></div>
          <span class="txt-sm" style="opacity:.4;white-space:nowrap;"><?= $lang==='ru'?'или':'немесе' ?></span>
          <div style="flex:1;height:1px;background:var(--border);"></div>
        </div>
        -->

        <div class="auth-switch" style="margin-bottom:16px;">
          <button type="button" class="auth-tab active" id="authTabLogin" onclick="showAuth('login')"><?= $lang==='ru'?'Войти':'Кіру' ?></button>
          <button type="button" class="auth-tab"        id="authTabReg"   onclick="showAuth('reg')"  ><?= $lang==='ru'?'Регистрация':'Тіркелу' ?></button>
        </div>

        <!-- Форма входа: логин + пароль -->
        <form class="auth-form" id="authLogin" action="login.php" method="post" autocomplete="on">
          <input class="auth-input" type="text"     name="login"    placeholder="<?= $lang==='ru'?'Логин или Email':'Логин немесе Email' ?>" required autocomplete="username">
          <input class="auth-input" type="password" name="password" placeholder="<?= $lang==='ru'?'Пароль':'Құпиясөз' ?>"                    required autocomplete="current-password">
          <button class="cta-btn" type="submit" style="margin-top:12px;"><?= $lang==='ru'?'Войти':'Кіру' ?></button>
        </form>

        <!-- Форма регистрации -->
        <form class="auth-form hidden" id="authReg" action="register.php" method="post" autocomplete="on">
          <div class="auth-row">
            <input class="auth-input" type="text" name="name"  placeholder="<?= $lang==='ru'?'Имя':'Аты-жөні' ?>" required autocomplete="name">
            <input class="auth-input" type="text" name="login" placeholder="<?= $lang==='ru'?'Логин':'Логин' ?>"   required autocomplete="username">
          </div>

          <!-- Город — чекбокс-лист -->
          <div style="margin-bottom:10px;">
            <div class="txt-sm" style="font-weight:700;margin-bottom:6px;"><?= $lang==='ru'?'Город':'Қала' ?> <span style="color:var(--danger);">*</span></div>
            <div id="cityDropdown" style="position:relative;">
              <button type="button" id="cityToggleBtn" onclick="toggleCityList()"
                style="width:100%;padding:12px 14px;text-align:left;background:var(--surface-highlight);border:1px solid var(--border);border-radius:var(--radius-md);color:var(--text-main);font-family:var(--font-main);font-size:14px;cursor:pointer;display:flex;justify-content:space-between;align-items:center;">
                <span id="cityBtnLabel"><?= $lang==='ru'?'Выберите город':'Қаланы таңдаңыз' ?></span>
                <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
              </button>
              <div id="cityList" style="display:none;position:absolute;top:calc(100% + 4px);left:0;right:0;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-md);z-index:100;max-height:220px;overflow-y:auto;box-shadow:0 8px 24px rgba(0,0,0,.18);">
                <div style="padding:8px;">
                  <input type="text" id="citySearch" placeholder="<?= $lang==='ru'?'Поиск...':'Іздеу...' ?>"
                    style="width:100%;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--surface-highlight);color:var(--text-main);font-family:var(--font-main);font-size:13px;box-sizing:border-box;"
                    oninput="filterCities(this.value)">
                </div>
                <div id="cityCheckboxes" style="padding:0 8px 8px;">
                <?php foreach ($cities as $city): ?>
                  <label style="display:flex;align-items:center;gap:8px;padding:8px 6px;cursor:pointer;border-radius:6px;font-size:13px;" class="city-option"
                    onmouseover="this.style.background='var(--surface-highlight)'" onmouseout="this.style.background=''">
                    <input type="radio" value="<?= e($city) ?>" style="accent-color:var(--primary);width:16px;height:16px;flex-shrink:0;" onchange="onCityPick('<?= e($city) ?>')">
                    <?= e($city) ?>
                  </label>
                <?php endforeach; ?>
                </div>
              </div>
            </div>
            <input type="hidden" name="city" id="cityHidden" required>
          </div>

          <select class="auth-input auth-select" name="role" required style="margin-bottom:10px;">
            <option value="client"><?= $lang==='ru'?'Клиент':'Клиент' ?></option>
            <option value="master"><?= $lang==='ru'?'Мастер':'Шебер' ?></option>
          </select>
          <div class="auth-row">
            <input class="auth-input" type="password" name="password"  placeholder="<?= $lang==='ru'?'Пароль (мин. 6)':'Құпиясөз (мин. 6)' ?>" required autocomplete="new-password">
            <input class="auth-input" type="password" name="password2" placeholder="<?= $lang==='ru'?'Повтор':'Қайталау' ?>"                       required autocomplete="new-password">
          </div>
          <button class="cta-btn" type="submit" style="margin-top:12px;"><?= $lang==='ru'?'Зарегистрироваться':'Тіркелу' ?></button>
        </form>
        <div class="txt-sm" style="margin-top:10px;opacity:.5;text-align:center;" data-key="authNote">—</div>
      </div>

    <?php else: ?>
      <div class="profile-card">
        <div class="profile-top">
          <div class="avatar" id="profileAvatar"
            style="background:<?= e($user['avatar_color'] ?? '#1cb7ff') ?>;color:#fff;border:none;<?= !empty($user['avatar_url']) ? 'background-image:url(\''.e($user['avatar_url']).'\');background-size:cover;background-position:center;' : '' ?>">
            <?= empty($user['avatar_url']) ? e($initial) : '' ?>
          </div>
          <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px;">
            <div class="h2" style="margin:0;" id="profileName"><?= e($displayName) ?></div>
            <div class="txt-sm" id="profileRole" style="opacity:.6;">—</div>
            <div class="txt-sm" id="profileProfession"
              style="color:var(--primary);font-weight:700;<?= (empty($user['profession']) || (string)$user['role']!=='master') ? 'display:none;' : '' ?>">
              <?= e($user['profession'] ?? '') ?>
              <?php if (!empty($user['experience']) && (int)$user['experience'] > 0): ?>
                • <?= (int)$user['experience'] ?> <span data-key="yearsSuffix">жыл</span>
              <?php endif; ?>
            </div>
          </div>
          <button class="profile-edit-btn" type="button" onclick="openProfileEdit()">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
          </button>
        </div>

        <?php if (!empty($user['bio'])): ?>
          <div id="profileBio" class="profile-bio"><?= e($user['bio']) ?></div>
        <?php else: ?>
          <div id="profileBio" class="profile-bio" style="display:none;"></div>
        <?php endif; ?>

        <div class="profile-stats">
          <div class="pstat">
            <div class="v" id="pProgress"><?= (int)($profileData['stats']['orders'] ?? 0) ?></div>
            <div class="l" data-key="statOrder">—</div>
          </div>
          <div class="pstat">
            <div class="v" id="pAccuracy">
              <?php
                $rc = (int)($profileData['stats']['rating_count'] ?? 0);
                $ra = $profileData['stats']['rating_avg'] ?? null;
                echo ($rc > 0 && $ra !== null) ? number_format((float)$ra, 1, '.', '') : '—';
              ?>
            </div>
            <div class="l" data-key="statRating">—</div>
          </div>
        </div>

        <!-- Phone verification -->
        <div style="border-top:1px solid var(--border);margin-top:18px;padding-top:18px;">
          <div class="h3" style="margin-bottom:12px;font-size:14px;" data-key="securityTitle"><?= $lang==='ru'?'Безопасность':'Қауіпсіздік' ?></div>
          <?php if (empty($user['phone'])): ?>
            <button class="cta-btn" style="margin-top:0;" onclick="openSmsModal()">
              📱 <?= $lang==='ru'?'Подтвердить номер':'Нөмірді растау' ?>
            </button>
          <?php else: ?>
            <div style="padding:12px;background:rgba(39,174,96,.1);border-radius:10px;margin-bottom:12px;">
              <div style="color:#27AE60;font-weight:700;margin-bottom:3px;">✓ <?= $lang==='ru'?'Номер подтверждён':'Нөмір расталды' ?></div>
              <div style="font-size:13px;color:#27AE60;"><?= e($user['phone']) ?></div>
            </div>
            <button onclick="smsRemovePhone()" style="padding:9px 16px;border-radius:10px;border:1px solid var(--danger);background:transparent;color:var(--danger);font-weight:700;font-size:13px;cursor:pointer;font-family:var(--font-main);">
              <?= $lang==='ru'?'Удалить номер':'Нөмірді жою' ?>
            </button>
          <?php endif; ?>
        </div>
      </div>

      <div class="section-head" style="margin-top:20px;">
        <div class="h3" data-key="recentServices">—</div>
      </div>
      <div id="profileCourses"></div>

      <button class="cta-btn" type="button" style="background:var(--surface-highlight);color:var(--text-main);border:1px solid var(--border);margin-top:16px;" onclick="setTab('settings')">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        <span data-key="settings">—</span>
      </button>
    <?php endif; ?>
  </div><!-- /#tab-profile -->

  <!-- ══════════════ SETTINGS ══════════════ -->
  <div id="tab-settings" class="tab-content" style="padding-bottom:80px;">
    <div style="text-align:center;margin-bottom:20px;">
      <div class="h3" data-key="settings">—</div>
      <div class="txt-sm" data-key="settingsSub" style="opacity:.6;">—</div>
    </div>

    <div class="setting-group">
      <div class="setting-row">
        <div class="setting-label">
          <span class="setting-icon">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
            </svg>
          </span>
          <span data-key="darkMode">—</span>
        </div>
        <label class="switch">
          <input type="checkbox" id="themeToggle" onchange="toggleTheme()">
          <span class="slider"></span>
        </label>
      </div>

      <div class="setting-row">
        <div class="setting-label">
          <span class="setting-icon">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>
              <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
            </svg>
          </span>
          <span data-key="language">—</span>
        </div>
        <div class="lang-switch">
          <div class="lang-opt <?= $lang==='kk'?'active':'' ?>" id="lang-kk" onclick="setLanguage('kk',true)">KZ</div>
          <div class="lang-opt <?= $lang==='ru'?'active':'' ?>" id="lang-ru" onclick="setLanguage('ru',true)">RU</div>
        </div>
      </div>
    </div>

    <div class="setting-group">
      <?php if ($isLoggedIn): ?>
        <div class="setting-row" onclick="logout()" style="cursor:pointer;color:var(--danger);">
          <div class="setting-label">
            <span class="setting-icon" style="color:var(--danger);">
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>
              </svg>
            </span>
            <span data-key="settingsLogoutAction">—</span>
          </div>
        </div>
      <?php else: ?>
        <div class="setting-row" onclick="setTab('profile')" style="cursor:pointer;">
          <div class="setting-label">
            <span class="setting-icon">
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M15 3h4a2 2 0 0 1 2 2v4"/><path d="M10 14L21 3"/>
                <path d="M21 14v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7"/>
              </svg>
            </span>
            <span data-key="settingsLoginAction">—</span>
          </div>
        </div>
      <?php endif; ?>
    </div>
  </div>

</div><!-- /.app-container -->


<!-- ══════════════ MASTER SEARCH MODAL ══════════════ -->
<div class="overlay" id="createOrderOverlay" onclick="closeCreateOrder()"></div>
<div class="sheet-modal" id="createOrderModal">
  <div class="sheet-header">
    <div>
      <div style="font-weight:900;font-size:18px;margin-bottom:2px;" data-key="mastersFilterTitle">
        <?= $lang==='ru'?'🏙️ Выберите город':'🏙️ Қаланы таңдаңыз' ?>
      </div>
      <div style="font-size:13px;color:var(--text-sec);">
        <?= $lang==='ru'?'Мастера будут показаны в вашем городе':'Мастерлер қалаңызда көрсетіледі' ?>
      </div>
    </div>
    <button class="ai-close" type="button" onclick="closeCreateOrder()">
      <svg viewBox="0 0 24 24" width="22" height="22" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
  </div>
  <form class="sheet-body" onsubmit="createOrderSubmit(event)">
    <div style="font-size:14px;font-weight:700;margin-bottom:8px;color:var(--text-main);">
      <?= $lang==='ru'?'Ваш город':'Сіздің қалаңыз' ?> <span style="color:var(--danger);">*</span>
    </div>
    <select class="auth-input" id="orderCity" style="width:100%;margin-bottom:16px;font-size:15px;padding:14px 16px;">
      <option value=""><?= $lang==='ru'?'— Выберите город —':'— Қаланы таңдаңыз —' ?></option>
      <?php foreach ($cities as $city): ?>
        <option value="<?= e($city) ?>"><?= e($city) ?></option>
      <?php endforeach; ?>
    </select>

    <div style="display:flex;align-items:flex-start;gap:10px;padding:12px 14px;background:var(--surface-highlight);border-radius:12px;border:1px solid var(--border);margin-bottom:20px;">
      <span style="font-size:18px;flex-shrink:0;"></span>
      <div style="font-size:13px;line-height:1.5;color:var(--text-sec);">
        <?= $lang==='ru'
          ? 'Мы покажем всех мастеров в выбранном городе. Вы сможете позвонить им или написать в WhatsApp напрямую.'
          : 'Таңдалған қаладағы барлық шеберлерді көрсетеміз. Тікелей қоңырау шалуға немесе WhatsApp-та жазуға болады.' ?>
      </div>
    </div>

    <button class="cta-btn" type="submit" style="margin-top:0;font-size:16px;padding:15px 20px;">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="width:20px;height:20px;">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
      <?= $lang==='ru'?'Показать мастеров':'Шеберлерді көрсету' ?>
    </button>
  </form>
</div>

<!-- ══════════════ ORDER CHAT MODAL ══════════════ -->

<div class="order-modal" id="orderChatModal">
  <div id="reviewBlock" style="display:none;padding:12px 16px;border-bottom:1px solid var(--border);">
    <div style="font-weight:700;margin-bottom:6px;" data-key="reviewBlockTitle">—</div>
    <select id="reviewRating" class="auth-input" style="margin-bottom:8px;">
      <option value="5">5 / 5 ★★★★★</option>
      <option value="4">4 / 5 ★★★★</option>
      <option value="3">3 / 5 ★★★</option>
      <option value="2">2 / 5 ★★</option>
      <option value="1">1 / 5 ★</option>
    </select>
    <textarea id="reviewText" class="auth-input" data-ph-key="reviewBlockPlaceholder" placeholder="—" style="width:100%;min-height:72px;resize:none;margin-bottom:8px;"></textarea>
    <button class="cta-btn" type="button" onclick="sendReview()" style="margin-top:0;" data-key="reviewBlockSend">—</button>
  </div>
  <div class="order-header">
    <button class="order-back" type="button" onclick="closeOrderChat()">
      <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
    </button>
    <div style="display:flex;flex-direction:column;gap:2px;min-width:0;flex:1;">
      <div class="order-title" id="orderChatTitle" data-key="chat">—</div>
      <div class="order-sub"   id="orderChatSub">—</div>
    </div>
    <button class="order-action" type="button" id="orderAcceptBtn" onclick="acceptCurrentOrder()" style="display:none;" data-key="orderAccept">—</button>
    <button class="order-action" type="button" id="orderFinishBtn" onclick="finishCurrentOrder()" style="display:none;" data-key="orderFinish">—</button>
  </div>
  <div class="chat-container" id="orderChatContainer"></div>
  <div class="modal-input-area">
    <input type="text" class="chat-input" id="orderChatInput" data-ph-key="chatInputPlaceholder" placeholder="—">
    <button class="send-btn" type="button" id="orderSendBtn" onclick="sendOrderMessage()">
      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
    </button>
  </div>
</div>

<!-- ══════════════ AI MODAL ══════════════ -->
<div class="ai-float-btn" onclick="toggleAIChat()">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
  </svg>
</div>
<div class="ai-modal" id="aiModal">
  <div class="ai-header">
    <div style="font-weight:800;font-size:18px;" data-key="aiTitle">—</div>
    <button class="ai-close" type="button" onclick="toggleAIChat()">
      <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
  </div>
  <div class="chat-container" id="chatContainer">
    <div class="chat-bubble chat-ai" data-html-key="aiWelcomeHtml"></div>
  </div>
  <div class="modal-input-area">
    <input type="text" class="chat-input" id="chatInput" data-ph-key="aiPlaceholder" placeholder="—">
    <button class="send-btn" type="button" id="sendBtn" onclick="sendMessage()">
      <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
    </button>
  </div>
</div>

<!-- ══════════════ NAV ══════════════ -->
<nav class="nav-island">
  <div class="nav-btn active" id="nav-home" onclick="setTab('home')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
    <span class="nav-label" data-key="navHome"><?= $lang==='ru'?'Главная':'Басты' ?></span>
  </div>
  <div class="nav-btn" id="nav-messages" onclick="setTab('messages')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
    <span class="nav-label" data-key="navChats"><?= $lang==='ru'?'Чаты':'Чат' ?></span>
  </div>
  <div class="nav-fab" onclick="primaryAction()">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
  </div>
  <div class="nav-btn" id="nav-courses" onclick="setTab('courses')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
    <span class="nav-label" data-key="navMasters"><?= $lang==='ru'?'Мастера':'Шеберлер' ?></span>
  </div>
  <div class="nav-btn" id="nav-profile" onclick="setTab('profile')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
    <span class="nav-label" data-key="navProfile"><?= $lang==='ru'?'Профиль':'Профиль' ?></span>
  </div>
</nav>

<!-- ══════════════ SIDEBAR ══════════════ -->
<div class="sidebar-overlay" id="overlay" onclick="toggleMenu()"></div>
<aside class="sidebar" id="sidebar">
  <ul style="list-style:none;padding:0;width:100%;display:flex;flex-direction:column;gap:4px;">
    <li class="menu-item" onclick="setTab('home');toggleMenu();">
      <div class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></div>
      <span data-key="home">—</span>
    </li>
    <li class="menu-item" onclick="setTab('courses');toggleMenu();">
      <div class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg></div>
      <span><?= $lang==='ru'?'Заказы':'Тапсырыстар' ?></span>
    </li>
    <li class="menu-item" onclick="setTab('settings');toggleMenu();">
      <div class="icon-box"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg></div>
      <span data-key="settings">—</span>
    </li>
  </ul>
  <div style="margin-top:auto;opacity:.3;text-align:center;font-size:11px;" data-key="sidebarVersion">© Sheber.kz</div>
</aside>

<div id="toast" class="toast"></div>

<!-- ══════════════ MASTER PROFILE MODAL ══════════════ -->
<div class="sheet-overlay" id="masterProfileOverlay" onclick="closeMasterProfile()"></div>
<div class="sheet-modal" id="masterProfileModal" style="height:88vh;z-index:2300;">
  <div class="sheet-header">
    <div style="font-weight:900;font-size:16px;" data-key="masterProfileTitle"><?= $lang==='ru'?'Профиль мастера':'Шебер профилі' ?></div>
    <button class="ai-close" type="button" onclick="closeMasterProfile()">
      <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
  </div>
  <div class="sheet-body" id="masterProfileBody" style="overflow-y:auto;flex:1;padding-bottom:30px;"></div>
</div>

<?php if ($isLoggedIn): ?>
<!-- ══════════════ PROFILE EDIT MODAL ══════════════ -->
<div class="sheet-modal" id="profileEditModal" style="height:92vh;z-index:2400;">
  <div class="sheet-header">
    <div style="font-weight:900;font-size:16px;" data-key="peTitle">—</div>
    <button class="ai-close" type="button" onclick="closeProfileEdit()">
      <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
  </div>
  <div class="sheet-body" style="overflow-y:auto;flex:1;padding-bottom:50px;">
    <div class="prof-edit-section">
      <div class="prof-edit-label" data-key="peLabelAvatar">—</div>
      <div class="avatar-picker-row" style="margin-bottom:10px;">
        <div class="av-preview" id="avPreview"
          style="background:<?= e($user['avatar_color'] ?? '#1cb7ff') ?>;cursor:pointer;position:relative;<?= !empty($user['avatar_url']) ? 'background-image:url(\''.e($user['avatar_url']).'\');background-size:cover;background-position:center;' : '' ?>"
          onclick="document.getElementById('avatarUploadInput').click()">
          <div id="avPreviewText"><?= empty($user['avatar_url']) ? e($initial) : '' ?></div>
          <div style="position:absolute;bottom:0;right:0;background:var(--surface);border-radius:50%;width:20px;height:20px;display:flex;align-items:center;justify-content:center;box-shadow:0 1px 3px rgba(0,0,0,.3);">
            <svg viewBox="0 0 24 24" width="12" height="12" stroke="var(--text-main)" stroke-width="2" fill="none"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
          </div>
        </div>
        <input type="file" id="avatarUploadInput" accept="image/*" style="display:none;" onchange="uploadAvatarFile(this)">
        <div class="av-colors">
          <?php foreach ($avatarColors as $c): ?>
            <div class="av-dot<?= ($user['avatar_color'] ?? '#1cb7ff') === $c ? ' selected' : '' ?>"
              style="background:<?= e($c) ?>;" data-color="<?= e($c) ?>" onclick="pickAvatarColor('<?= e($c) ?>')"></div>
          <?php endforeach; ?>
        </div>
      </div>
    </div>

    <form id="profileEditForm" onsubmit="profileEditSubmit(event)" autocomplete="off">
      <input type="hidden" id="peAvatarColor" name="avatar_color" value="<?= e($user['avatar_color'] ?? '#1cb7ff') ?>">

      <div class="prof-edit-section">
        <div class="prof-edit-label" data-key="peLabelName">— <span style="color:var(--danger);">*</span></div>
        <input class="auth-input" id="peName" name="name" type="text" value="<?= e($displayName) ?>" data-ph-key="peNamePh" placeholder="—" required maxlength="80">
      </div>
      <div class="prof-edit-section">
        <div class="prof-edit-label" data-key="peLabelCity">—</div>
        <input class="auth-input" id="peCity" name="city" type="text" value="<?= e(!in_array($displayCity, ['—','']) ? $displayCity : '') ?>" data-ph-key="peCityPh" placeholder="—" maxlength="80">
      </div>

      <?php if ((string)$user['role'] === 'master'): ?>
        <div class="prof-edit-section">
          <div class="prof-edit-label" data-key="peLabelProfession">—</div>
          <input class="auth-input" id="peProfession" name="profession" type="text" value="<?= e($user['profession'] ?? '') ?>" data-ph-key="peProfessionPh" placeholder="—" maxlength="120">
        </div>
        <div class="prof-edit-section">
          <div class="prof-edit-label" data-key="peLabelExperience">—</div>
          <input class="auth-input" id="peExperience" name="experience" type="number" value="<?= (int)($user['experience'] ?? 0) ?>" min="0" max="80" placeholder="0" inputmode="numeric" style="max-width:120px;">
        </div>
      <?php else: ?>
        <input type="hidden" id="peProfession" name="profession" value="">
        <input type="hidden" id="peExperience" name="experience" value="0">
      <?php endif; ?>

      <div class="prof-edit-section">
        <div class="prof-edit-label" data-key="peLabelPhone">—</div>
        <input class="auth-input" id="pePhone" name="phone" type="tel" value="<?= e($user['phone'] ?? '') ?>" data-ph-key="pePhonePh" placeholder="—" maxlength="32">
      </div>
      <div class="prof-edit-section">
        <div class="prof-edit-label">
          <span data-key="peLabelBio">—</span>
          <span id="peBioCount" style="float:right;color:var(--text-sec);"><?= mb_strlen($user['bio'] ?? '') ?>/500</span>
        </div>
        <textarea class="auth-input" id="peBio" name="bio" rows="4" data-ph-key="peBioPh" placeholder="—" maxlength="500" style="resize:none;"><?= e($user['bio'] ?? '') ?></textarea>
      </div>

      <button class="cta-btn" type="submit" id="profileSaveBtn" style="margin-top:6px;" data-key="peSaveBtn">—</button>
      <button class="cta-btn" type="button" onclick="switchRole('master')" style="margin-top:10px;background:var(--surface-highlight);color:var(--text-main);border:1px solid var(--border);">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right:6px;"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
        <span data-key="switchToMaster">Стать мастером</span>
      </button>
    </form>
  </div>
</div>
<div class="sheet-overlay" id="profileEditOverlay" onclick="closeProfileEdit()"></div>

<!-- Profession modal -->
<div class="sheet-modal" id="roleProfessionModal" style="height:auto;min-height:45vh;z-index:2500;">
  <div class="sheet-header">
    <div style="font-weight:900;font-size:16px;" data-key="profInputTitle">Мамандығыңызды енгізіңіз</div>
    <button class="ai-close" type="button" onclick="closeRoleProfessionModal()">
      <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
  </div>
  <div class="sheet-body">
    <div class="txt-sm" style="margin-bottom:12px;opacity:.7;" data-key="profInputDesc">—</div>
    <div class="prof-edit-section">
      <div id="roleProfDropdown" style="position:relative;">
        <button type="button" id="roleProfBtn" onclick="toggleRoleProfList()"
          style="width:100%;padding:12px 14px;text-align:left;background:var(--surface-highlight);border:1.5px solid transparent;border-radius:var(--radius-md);color:var(--text-main);font-family:var(--font-main);font-size:14px;cursor:pointer;display:flex;justify-content:space-between;align-items:center;">
          <span id="roleProfLabel"><?= $lang==='ru'?'Выберите профессию':'Мамандықты таңдаңыз' ?></span>
          <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none"><polyline points="6 9 12 15 18 9"/></svg>
        </button>
        <div id="roleProfList" style="display:none;position:absolute;bottom:calc(100% + 4px);left:0;right:0;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-md);z-index:100;max-height:220px;overflow-y:auto;box-shadow:0 8px 24px rgba(0,0,0,.2);">
          <div style="padding:8px;">
            <input type="text" placeholder="<?= $lang==='ru'?'Поиск...':'Іздеу...' ?>"
              style="width:100%;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--surface-highlight);color:var(--text-main);font-family:var(--font-main);font-size:13px;box-sizing:border-box;"
              oninput="filterRoleProf(this.value)">
          </div>
          <div id="roleProfCheckboxes" style="padding:0 8px 8px;">
            <?php foreach (['Сантехник','Электрик','Сварщик','Плиточник','Маляр','Штукатур','Плотник','Столяр','Кровельщик','Мастер по окнам / дверям','Мастер по полам','Монтажник натяжных потолков','Отделочник','Разнорабочий','Грузчик','Водитель / Перевозки','Мастер по мебели','Мастер по технике','Компьютерный мастер','Установка кондиционеров','Уборщик / Клинер','Домработница','Садовник / Озеленение','Репетитор','Массажист','Парикмахер / Барбер','Фотограф','Дизайнер интерьера','Строитель','Бетонщик','Каменщик','Монтажник','Слесарь','Токарь','Сигнализация / Камеры','Замочник'] as $rp): ?>
            <label style="display:flex;align-items:center;gap:8px;padding:8px 6px;cursor:pointer;border-radius:6px;font-size:13px;" class="role-prof-option"
              onmouseover="this.style.background='var(--surface-highlight)'" onmouseout="this.style.background=''">
              <input type="radio" value="<?= e($rp) ?>" style="accent-color:var(--primary);width:16px;height:16px;flex-shrink:0;" onchange="onRoleProfPick('<?= e($rp) ?>')">
              <?= e($rp) ?>
            </label>
            <?php endforeach; ?>
          </div>
        </div>
      </div>
      <input type="hidden" id="roleProfessionInput" value="">
    </div>
    <button class="cta-btn" type="button" onclick="roleProfessionSubmit()" style="margin-top:14px;" data-key="profInputBtn">Жалғастыру</button>
  </div>
</div>
<div class="sheet-overlay" id="roleProfessionOverlay" onclick="closeRoleProfessionModal()" style="z-index:2450;"></div>
<?php endif; ?>

<!-- ══════════════ ORDER DETAIL MODAL ══════════════ -->
<div class="order-detail-modal" id="orderDetailModal" onclick="if(event.target.id==='orderDetailModal')closeOrderDetail()">
  <div class="order-detail-content">
    <div class="order-detail-header">
      <h3><?= $lang==='ru'?'Детали заказа':'Тапсырыс мәліметі' ?></h3>
      <button class="order-detail-close" onclick="closeOrderDetail()">✕</button>
    </div>
    <div class="order-detail-body">
      <img id="detailImage" class="order-detail-image" src="" alt="">
      <div class="order-detail-section">
        <div class="order-detail-label"><?= $lang==='ru'?'Мастер':'Шебер' ?></div>
        <div class="order-detail-master-card">
          <div class="order-detail-master-avatar" id="detailMasterAvatar">М</div>
          <div class="order-detail-master-info">
            <div class="order-detail-master-name"       id="detailMasterName">—</div>
            <div class="order-detail-master-profession" id="detailMasterProfession">—</div>
            <div class="order-detail-master-rating"     id="detailMasterRating">—</div>
          </div>
        </div>
      </div>
      <div class="order-detail-section">
        <div class="order-detail-label"><?= $lang==='ru'?'О заказе':'Тапсырыс туралы' ?></div>
        <div class="order-detail-title"       id="detailTitle">—</div>
        <div class="order-detail-description" id="detailDescription">—</div>
      </div>
      <div class="order-detail-section">
        <div class="order-detail-label"><?= $lang==='ru'?'Информация':'Ақпарат' ?></div>
        <div class="order-detail-info-row"><div class="order-detail-info-label"><?= $lang==='ru'?'Статус':'Күй' ?></div><div class="order-detail-info-value" id="detailStatus">—</div></div>
        <div class="order-detail-info-row"><div class="order-detail-info-label"><?= $lang==='ru'?'Дата':'Күні' ?></div><div class="order-detail-info-value" id="detailDate">—</div></div>
        <div class="order-detail-info-row"><div class="order-detail-info-label"><?= $lang==='ru'?'Место':'Жер' ?></div><div class="order-detail-info-value" id="detailLocation">—</div></div>
      </div>
      <div class="order-detail-section">
        <div class="order-detail-label"><?= $lang==='ru'?'Стоимость':'Бағасы' ?></div>
        <div class="order-detail-price" id="detailPrice">0 ₸</div>
      </div>
    </div>
    <div class="order-detail-actions">
      <button class="order-detail-btn order-detail-btn-secondary" onclick="closeOrderDetail()"><?= $lang==='ru'?'Закрыть':'Жабу' ?></button>
      <button class="order-detail-btn order-detail-btn-primary" id="detailActionBtn" onclick="handleOrderAction()">—</button>
    </div>
  </div>
</div>

<!-- ══════════════ SMS MODAL ══════════════ -->
<div id="smsAuthModal" class="sms-modal-overlay">
  <div class="sms-modal">
    <button style="position:absolute;top:14px;right:14px;background:none;border:none;color:var(--text-main);cursor:pointer;font-size:22px;line-height:1;" onclick="closeSmsModal()">✕</button>

    <div id="smsStep1" class="sms-step active">
      <div class="sms-modal-header"><?= $lang==='ru'?'Подтверждение номера':'Нөмірді растау' ?></div>
      <div class="sms-modal-desc"><?= $lang==='ru'?'Введите номер телефона для получения кода':'Код алу үшін телефон нөмірін енгізіңіз' ?></div>
      <div id="smsStatus1"></div>
      <div class="form-group-sms">
        <label><?= $lang==='ru'?'Номер телефона':'Телефон нөмірі' ?></label>
        <input type="tel" id="smsPhoneInput" placeholder="+7 (7xx) xxx-xx-xx" maxlength="20" value="+7">
      </div>
      <button class="sms-button sms-button-primary" id="smsSendBtn" onclick="smsSendCode()"><?= $lang==='ru'?'Отправить код':'Код жіберу' ?></button>
      <button class="sms-button sms-button-secondary" onclick="closeSmsModal()"><?= $lang==='ru'?'Отмена':'Бас тарту' ?></button>
    </div>

    <div id="smsStep2" class="sms-step">
      <div class="sms-modal-header"><?= $lang==='ru'?'Введите код':'Кодты енгізіңіз' ?></div>
      <div class="sms-modal-desc"><?= $lang==='ru'?'Код отправлен на номер':'Код жіберілді:' ?> <strong id="smsPhoneDisplay">+7...</strong></div>
      <div id="smsStatus2"></div>
      <div class="code-inputs">
        <input type="text" class="code-input" id="code0" maxlength="1" inputmode="numeric" oninput="smsCodeInput(this,'code1')">
        <input type="text" class="code-input" id="code1" maxlength="1" inputmode="numeric" oninput="smsCodeInput(this,'code2')">
        <input type="text" class="code-input" id="code2" maxlength="1" inputmode="numeric" oninput="smsCodeInput(this,'code3')">
        <input type="text" class="code-input" id="code3" maxlength="1" inputmode="numeric" oninput="smsCodeInput(this,null)">
      </div>
      <div class="sms-timer" id="smsTimer"><?= $lang==='ru'?'Повторить через':'Қайта жіберу:' ?> <span id="smsTimerCount">120</span> <?= $lang==='ru'?'сек':'сек' ?></div>
      <button class="sms-button sms-button-primary" id="smsVerifyBtn" onclick="smsVerifyCode()"><?= $lang==='ru'?'Подтвердить':'Растау' ?></button>
      <button class="sms-button sms-button-secondary" onclick="smsBackToPhone()"><?= $lang==='ru'?'Назад':'Артқа' ?></button>
    </div>

    <div id="smsStep3" class="sms-step">
      <div style="text-align:center;padding:16px 0;">
        <div style="font-size:44px;margin-bottom:12px;">✓</div>
        <div class="sms-modal-header" style="margin-bottom:6px;"><?= $lang==='ru'?'Номер подтверждён!':'Нөмір расталды!' ?></div>
        <div class="sms-modal-desc"><?= $lang==='ru'?'Ваш номер':'Нөміріңіз' ?> <strong id="smsPhoneSuccess">+7...</strong> <?= $lang==='ru'?'успешно привязан':'сәтті байланысты' ?></div>
      </div>
      <button class="sms-button sms-button-primary" onclick="closeSmsModal()"><?= $lang==='ru'?'Закрыть':'Жабу' ?></button>
    </div>
  </div>
</div>

<!-- ══════════════ ORDERS JS ══════════════ -->
<script>
const ordersData = [
  { id:101, image:'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=200&fit=crop', title:'Укладка плитки в ванной', description:'Нужна укладка плитки в ванной комнате 2x2м. Плитка уже куплена.', status:'in_progress', statusText:'В процессе', date:'03 марта 2026 г.', location:'Алматы, Бостандыкский р.', price:50000, master:{name:'Ахмет Сейтов', profession:'Плиточник', rating:4.9, reviews:43, initial:'А'} },
  { id:102, image:'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=400&h=200&fit=crop', title:'Ремонт электропроводки', description:'Ремонт электропроводки в 3-комнатной квартире. Замена розеток и выключателей.', status:'completed', statusText:'Завершен', date:'01 марта 2026 г.', location:'Астана, Есиль', price:120000, master:{name:'Марат Рахимов', profession:'Электрик', rating:5.0, reviews:27, initial:'М'} },
  { id:103, image:'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&h=200&fit=crop', title:'Монтаж окон ПВХ', description:'Монтаж 6 окон ПВХ в частном доме. Окна куплены и доставлены.', status:'in_progress', statusText:'В процессе', date:'02 марта 2026 г.', location:'Шымкент, Абайский р.', price:180000, master:{name:'Кайрат Дауов', profession:'Мастер по окнам', rating:4.8, reviews:15, initial:'К'} },
  { id:104, image:'https://images.unsplash.com/photo-1578654881897-d8d73d52e07f?w=400&h=200&fit=crop', title:'Уборка после ремонта', description:'Генеральная уборка 4-комнатной квартиры после завершения ремонта.', status:'completed', statusText:'Завершен', date:'28 февраля 2026 г.', location:'Алматы, Медеуский р.', price:45000, master:{name:'Зарина Исмаилова', profession:'Клинер', rating:4.7, reviews:89, initial:'З'} }
];

let currentOrderTab = 'actual', selectedOrder = null;

function switchOrderTab(tab) {
  currentOrderTab = tab;
  document.getElementById('tabActual').classList.toggle('active', tab === 'actual');
  document.getElementById('tabCompleted').classList.toggle('active', tab === 'completed');
  renderOrdersList();
}

function renderOrdersList() {
  const c = document.getElementById('ordersContainer'); if (!c) return;
  const list = ordersData.filter(o => currentOrderTab === 'actual' ? o.status === 'in_progress' : o.status === 'completed');
  if (!list.length) {
    c.innerHTML = `<div class="empty-state-orders"><div class="empty-state-icon">${currentOrderTab === 'actual' ? '📋' : '✓'}</div><div class="empty-state-title">${currentOrderTab === 'actual' ? 'Нет активных заказов' : 'Нет завершённых заказов'}</div></div>`;
    return;
  }
  c.innerHTML = list.map(o => `
    <div class="order-card-detailed" onclick="openOrderDetail(${o.id})">
      <img src="${o.image}" class="order-card-image" onerror="this.style.display='none'">
      <div class="order-card-body">
        <div class="order-card-header">
          <div class="order-master-avatar">${o.master.initial}</div>
          <div class="order-master-info">
            <div class="order-master-name">${o.master.name}</div>
            <div class="order-master-profession">${o.master.profession}</div>
            <div class="order-master-rating"> ${o.master.rating} (${o.master.reviews})</div>
          </div>
        </div>
        <div class="order-card-title">${o.title}</div>
        <div class="order-card-description">${o.description}</div>
        <div class="order-card-footer">
          <div class="order-card-price">${o.price.toLocaleString()} ₸</div>
          <div class="order-card-status ${o.status}">${o.statusText}</div>
        </div>
      </div>
    </div>`).join('');
}

function openOrderDetail(id) {
  selectedOrder = ordersData.find(o => o.id === id); if (!selectedOrder) return;
  document.getElementById('detailImage').src                = selectedOrder.image;
  document.getElementById('detailMasterAvatar').textContent = selectedOrder.master.initial;
  document.getElementById('detailMasterName').textContent   = selectedOrder.master.name;
  document.getElementById('detailMasterProfession').textContent = selectedOrder.master.profession;
  document.getElementById('detailMasterRating').textContent = `${selectedOrder.master.rating} (${selectedOrder.master.reviews})`;
  document.getElementById('detailTitle').textContent        = selectedOrder.title;
  document.getElementById('detailDescription').textContent  = selectedOrder.description;
  document.getElementById('detailStatus').textContent       = selectedOrder.statusText;
  document.getElementById('detailDate').textContent         = selectedOrder.date;
  document.getElementById('detailLocation').textContent     = selectedOrder.location;
  document.getElementById('detailPrice').textContent        = selectedOrder.price.toLocaleString() + ' ₸';
  document.getElementById('detailActionBtn').textContent    = selectedOrder.status === 'in_progress' ? 'Сообщение' : ' Отзыв';
  document.getElementById('orderDetailModal').classList.add('active');
}
function closeOrderDetail() { document.getElementById('orderDetailModal').classList.remove('active'); selectedOrder = null; }
function handleOrderAction() { if (!selectedOrder) return; showToast(selectedOrder.status === 'in_progress' ? 'Открыт чат' : 'Форма отзыва'); closeOrderDetail(); }

// SMS
let smsState = { timerInterval: null, timerSeconds: 120 };
function openSmsModal()  { document.getElementById('smsAuthModal').classList.add('active'); resetSmsModal(); }
function closeSmsModal() { document.getElementById('smsAuthModal').classList.remove('active'); clearInterval(smsState.timerInterval); }
function resetSmsModal() {
  clearInterval(smsState.timerInterval);
  document.querySelectorAll('.sms-step').forEach(el => el.classList.remove('active'));
  document.getElementById('smsStep1').classList.add('active');
  document.getElementById('smsPhoneInput').value = '+7';
  document.getElementById('smsPhoneInput').focus();
  ['smsStatus1','smsStatus2'].forEach(id => { const el = document.getElementById(id); if (el) el.innerHTML = ''; });
  document.querySelectorAll('.code-input').forEach(el => el.value = '');
}
function showSmsStep(n) { document.querySelectorAll('.sms-step').forEach(el => el.classList.remove('active')); document.getElementById('smsStep' + n).classList.add('active'); }
function smsSendCode() {
  const phone = document.getElementById('smsPhoneInput').value.trim();
  if (phone.length < 10) { document.getElementById('smsStatus1').innerHTML = '<div class="sms-status error">Некорректный номер</div>'; return; }
  const btn = document.getElementById('smsSendBtn');
  btn.disabled = true; btn.innerHTML = '<span class="typing-dots-sms"><span>.</span><span>.</span><span>.</span></span>';
  fetch('api_sms_auth.php?action=send_code', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'phone='+encodeURIComponent(phone) })
    .then(r => r.json()).then(data => {
      btn.disabled = false; btn.innerHTML = '<?= $lang==="ru"?"Отправить код":"Код жіберу" ?>';
      if (data.ok) { smsState.phone = phone; document.getElementById('smsPhoneDisplay').textContent = phone; document.getElementById('smsPhoneSuccess').textContent = phone; showSmsStep(2); startSmsTimer(); }
      else document.getElementById('smsStatus1').innerHTML = '<div class="sms-status error">' + (data.error || 'Ошибка') + '</div>';
    }).catch(() => { btn.disabled = false; btn.innerHTML = '<?= $lang==="ru"?"Отправить код":"Код жіберу" ?>'; document.getElementById('smsStatus1').innerHTML = '<div class="sms-status error">Ошибка сети</div>'; });
}
function smsCodeInput(el, nextId) { el.value = el.value.replace(/\D/g,''); if (el.value && nextId) document.getElementById(nextId).focus(); }
function smsVerifyCode() {
  const code = ['code0','code1','code2','code3'].map(id => document.getElementById(id).value).join('');
  if (code.length !== 4) { document.getElementById('smsStatus2').innerHTML = '<div class="sms-status error">Введите все 4 цифры</div>'; return; }
  const btn = document.getElementById('smsVerifyBtn');
  btn.disabled = true; btn.innerHTML = '<span class="typing-dots-sms"><span>.</span><span>.</span><span>.</span></span>';
  fetch('api_sms_auth.php?action=verify_code', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'code='+encodeURIComponent(code) })
    .then(r => r.json()).then(data => {
      btn.disabled = false; btn.innerHTML = '<?= $lang==="ru"?"Подтвердить":"Растау" ?>';
      if (data.ok) { clearInterval(smsState.timerInterval); showSmsStep(3); setTimeout(() => location.reload(), 2000); }
      else document.getElementById('smsStatus2').innerHTML = '<div class="sms-status error">' + (data.error || 'Ошибка') + '</div>';
    }).catch(() => { btn.disabled = false; btn.innerHTML = '<?= $lang==="ru"?"Подтвердить":"Растау" ?>'; document.getElementById('smsStatus2').innerHTML = '<div class="sms-status error">Ошибка сети</div>'; });
}
function smsBackToPhone() { clearInterval(smsState.timerInterval); showSmsStep(1); }
function startSmsTimer() {
  smsState.timerSeconds = 120;
  const el = document.getElementById('smsTimer'); el.classList.add('active');
  smsState.timerInterval = setInterval(() => {
    document.getElementById('smsTimerCount').textContent = --smsState.timerSeconds;
    if (smsState.timerSeconds <= 0) { clearInterval(smsState.timerInterval); el.classList.remove('active'); }
  }, 1000);
}
function smsRemovePhone() {
  if (!confirm('<?= $lang==="ru"?"Удалить номер телефона?":"Телефон нөмірін жою керек пе?" ?>')) return;
  fetch('api_sms_auth.php?action=remove_phone', { method:'POST' }).then(r => r.json()).then(d => { if (d.ok) location.reload(); else alert(d.error || 'Ошибка'); });
}

// Role profession picker
function toggleRoleProfList() {
  const list = document.getElementById('roleProfList');
  list.style.display = list.style.display === 'none' ? 'block' : 'none';
  if (list.style.display === 'block') list.querySelector('input[type=text]').focus();
}
function onRoleProfPick(name) {
  document.getElementById('roleProfLabel').textContent = name;
  document.getElementById('roleProfessionInput').value = name;
  document.getElementById('roleProfList').style.display = 'none';
}
function filterRoleProf(q) {
  q = q.toLowerCase();
  document.querySelectorAll('.role-prof-option').forEach(el => {
    el.style.display = el.textContent.trim().toLowerCase().includes(q) ? '' : 'none';
  });
}
document.addEventListener('click', e => {
  const pd = document.getElementById('roleProfDropdown');
  if (pd && !pd.contains(e.target)) {
    const list = document.getElementById('roleProfList');
    if (list) list.style.display = 'none';
  }
});

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', renderOrdersList);
else renderOrdersList();

// City picker
function toggleCityList() {
  const list = document.getElementById('cityList');
  list.style.display = list.style.display === 'none' ? 'block' : 'none';
  if (list.style.display === 'block') document.getElementById('citySearch').focus();
}
function onCityPick(name) {
  document.getElementById('cityBtnLabel').textContent = name;
  document.getElementById('cityHidden').value = name;
  document.getElementById('cityList').style.display = 'none';
}
function filterCities(q) {
  q = q.toLowerCase();
  document.querySelectorAll('.city-option').forEach(el => {
    el.style.display = el.textContent.trim().toLowerCase().includes(q) ? '' : 'none';
  });
}
// Close city list on outside click
document.addEventListener('click', e => {
  const dd = document.getElementById('cityDropdown');
  if (dd && !dd.contains(e.target)) {
    const list = document.getElementById('cityList');
    if (list) list.style.display = 'none';
  }
});
</script>

</body>
</html>