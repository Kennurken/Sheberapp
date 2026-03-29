<?php
declare(strict_types=1);
require __DIR__ . '/init.php';
require_admin();

$lang = lang_get();

// ── Stats queries ──────────────────────────────────────────────
try {
    $stats = [];

    // Totals
    $st = $pdo->query("SELECT COUNT(*) FROM users WHERE role='client'");
    $stats['clients'] = (int)$st->fetchColumn();

    $st = $pdo->query("SELECT COUNT(*) FROM users WHERE role='master'");
    $stats['masters'] = (int)$st->fetchColumn();

    $st = $pdo->query("SELECT COUNT(*) FROM orders");
    $stats['orders_total'] = (int)$st->fetchColumn();

    $st = $pdo->query("SELECT COUNT(*) FROM orders WHERE status='completed'");
    $stats['orders_done'] = (int)$st->fetchColumn();

    $st = $pdo->query("SELECT COUNT(*) FROM orders WHERE status IN ('new','in_progress')");
    $stats['orders_active'] = (int)$st->fetchColumn();

    $st = $pdo->query("SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURDATE()");
    $stats['orders_today'] = (int)$st->fetchColumn();

    $st = $pdo->query("SELECT COUNT(*) FROM users WHERE DATE(created_at) = CURDATE()");
    $stats['users_today'] = (int)$st->fetchColumn();

    // Try subscriptions
    try {
        $st = $pdo->query("SELECT COUNT(*) FROM master_subscriptions WHERE status='active'");
        $stats['subs_active'] = (int)$st->fetchColumn();
    } catch (Throwable) { $stats['subs_active'] = 0; }

    // Revenue estimate
    try {
        $st = $pdo->query("SELECT COALESCE(SUM(price),0) FROM orders WHERE status='completed'");
        $stats['revenue'] = (float)$st->fetchColumn();
    } catch (Throwable) { $stats['revenue'] = 0; }

    // Online masters
    try {
        $st = $pdo->query("SELECT COUNT(*) FROM users WHERE role='master' AND is_online=1");
        $stats['masters_online'] = (int)$st->fetchColumn();
    } catch (Throwable) { $stats['masters_online'] = 0; }

    // Chart: orders last 7 days
    $st = $pdo->query("
        SELECT DATE(created_at) AS day, COUNT(*) AS cnt
        FROM orders
        WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
        GROUP BY DATE(created_at)
        ORDER BY day ASC
    ");
    $chartRaw = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
    $chartMap = [];
    foreach ($chartRaw as $r) $chartMap[$r['day']] = (int)$r['cnt'];
    $chartDays = [];
    for ($i = 6; $i >= 0; $i--) {
        $d = date('Y-m-d', strtotime("-{$i} days"));
        $chartDays[] = ['day' => $d, 'cnt' => $chartMap[$d] ?? 0];
    }

    // Recent orders
    $st = $pdo->query("
        SELECT o.id, o.status, o.price, o.created_at,
               COALESCE(mc.name,'—') AS category,
               COALESCE(c.name,'—') AS client_name,
               COALESCE(m.name,'—') AS master_name
        FROM orders o
        LEFT JOIN users c ON c.id = o.client_id
        LEFT JOIN users m ON m.id = o.master_id
        LEFT JOIN master_categories mc ON mc.id = o.category_id
        ORDER BY o.id DESC LIMIT 20
    ");
    $recentOrders = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

    // Recent users
    $st = $pdo->query("
        SELECT id, name, phone, role, created_at
        FROM users ORDER BY id DESC LIMIT 20
    ");
    $recentUsers = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

    // Top masters
    $st = $pdo->query("
        SELECT u.id, u.name, u.phone,
               COUNT(o.id) AS orders_cnt,
               COALESCE(AVG(r.rating),0) AS avg_rating
        FROM users u
        LEFT JOIN orders o ON o.master_id = u.id AND o.status='completed'
        LEFT JOIN reviews r ON r.master_id = u.id
        WHERE u.role='master'
        GROUP BY u.id, u.name, u.phone
        ORDER BY orders_cnt DESC LIMIT 10
    ");
    $topMasters = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

} catch (Throwable $e) {
    $stats = ['error' => $e->getMessage()];
    $chartDays = $recentOrders = $recentUsers = $topMasters = [];
}

function fmtNum(float $n): string {
    return number_format($n, 0, '.', ' ');
}
function statusBadge(string $s): string {
    $map = [
        'new' => ['#3B82F6','Новый'],
        'in_progress' => ['#F97316','В работе'],
        'completed' => ['#10B981','Выполнен'],
        'cancelled' => ['#EF4444','Отменён'],
    ];
    [$color, $label] = $map[$s] ?? ['#6B7280', $s];
    return "<span style='background:{$color}22;color:{$color};padding:3px 10px;border-radius:999px;font-size:11px;font-weight:700;'>{$label}</span>";
}
?>
<!doctype html>
<html lang="ru" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sheber.kz — Админ панель</title>
<link rel="icon" type="image/png" href="favicon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:Manrope,sans-serif;background:#0d0d0f;color:#e8e8f0;min-height:100vh;}
a{color:inherit;text-decoration:none;}

/* Layout */
.sidebar{position:fixed;left:0;top:0;bottom:0;width:220px;background:#131318;border-right:1px solid #232330;padding:0;z-index:100;display:flex;flex-direction:column;}
.sidebar-logo{padding:20px 20px 16px;font-weight:800;font-size:18px;border-bottom:1px solid #232330;}
.sidebar-logo span{color:#0069ff;}
.sidebar-nav{padding:12px 10px;flex:1;}
.nav-item{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;cursor:pointer;font-size:13px;font-weight:600;color:#9999b0;transition:all .15s;margin-bottom:2px;}
.nav-item:hover,.nav-item.active{background:#1e1e2e;color:#e8e8f0;}
.nav-item.active{color:#0069ff;}
.nav-icon{width:18px;height:18px;flex-shrink:0;}
.sidebar-footer{padding:16px;border-top:1px solid #232330;}

.main{margin-left:220px;padding:24px;min-height:100vh;}
.topbar{display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;}
.topbar-title{font-size:22px;font-weight:800;}
.topbar-meta{font-size:12px;color:#9999b0;}

/* Cards */
.stats-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:14px;margin-bottom:24px;}
.stat-card{background:#131318;border:1px solid #232330;border-radius:18px;padding:18px;transition:border-color .15s;}
.stat-card:hover{border-color:#0069ff44;}
.stat-label{font-size:11px;font-weight:700;color:#9999b0;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;}
.stat-value{font-size:28px;font-weight:800;margin-bottom:2px;}
.stat-sub{font-size:11px;color:#9999b0;}

/* Chart */
.chart-wrap{background:#131318;border:1px solid #232330;border-radius:18px;padding:20px;margin-bottom:24px;}
.chart-title{font-size:14px;font-weight:800;margin-bottom:16px;}
.chart-bars{display:flex;gap:6px;align-items:flex-end;height:120px;}
.chart-bar-wrap{display:flex;flex-direction:column;align-items:center;flex:1;gap:4px;height:100%;}
.chart-bar-inner{width:100%;display:flex;align-items:flex-end;flex:1;}
.chart-bar{width:100%;background:linear-gradient(180deg,#0069ff,#2EC4B6);border-radius:6px 6px 0 0;min-height:3px;transition:height .4s;}
.chart-bar-val{font-size:10px;color:#0069ff;font-weight:700;}
.chart-bar-lbl{font-size:10px;color:#9999b0;}

/* Tables */
.section{background:#131318;border:1px solid #232330;border-radius:18px;margin-bottom:20px;overflow:hidden;}
.section-head{padding:16px 20px;border-bottom:1px solid #232330;display:flex;justify-content:space-between;align-items:center;}
.section-title{font-size:14px;font-weight:800;}
table{width:100%;border-collapse:collapse;}
th{padding:10px 16px;text-align:left;font-size:11px;font-weight:700;color:#9999b0;text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid #232330;}
td{padding:12px 16px;font-size:13px;border-bottom:1px solid #1a1a26;}
tr:last-child td{border-bottom:none;}
tr:hover td{background:#1a1a26;}

/* Tabs */
.tab-btns{display:flex;gap:6px;background:#1a1a26;border-radius:12px;padding:4px;margin-bottom:20px;}
.tab-btn{padding:8px 18px;border-radius:9px;border:none;background:transparent;color:#9999b0;font-size:13px;font-weight:700;cursor:pointer;font-family:inherit;transition:all .15s;}
.tab-btn.active{background:#0069ff;color:#fff;}
.tab-content{display:none;}
.tab-content.active{display:block;}

/* Badge */
.badge{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;border-radius:999px;font-size:11px;font-weight:700;}
.badge-green{background:#10b98122;color:#10b981;}
.badge-blue{background:#3b82f622;color:#3b82f6;}
.badge-gray{background:#6b728022;color:#6b7280;}

.stars{color:#f59e0b;font-size:13px;}

@media(max-width:768px){
  .sidebar{display:none;}
  .main{margin-left:0;padding:16px;}
  .stats-grid{grid-template-columns:repeat(2,1fr);}
}
</style>
</head>
<body>

<div class="sidebar">
  <div class="sidebar-logo">Sheber<span>.kz</span> <span style="font-size:10px;background:#0069ff22;color:#0069ff;padding:2px 8px;border-radius:999px;margin-left:4px;">Admin</span></div>
  <nav class="sidebar-nav">
    <div class="nav-item active" onclick="showTab('overview')">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>
      Обзор
    </div>
    <div class="nav-item" onclick="showTab('orders')">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
      Заказы
    </div>
    <div class="nav-item" onclick="showTab('users')">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      Пользователи
    </div>
    <div class="nav-item" onclick="showTab('masters')">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
      Мастера
    </div>
  </nav>
  <div class="sidebar-footer">
    <a href="home-master.php" style="display:flex;align-items:center;gap:8px;font-size:12px;color:#9999b0;">
      <svg style="width:16px;height:16px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
      Выйти из панели
    </a>
  </div>
</div>

<main class="main">
  <div class="topbar">
    <div class="topbar-title">📊 Панель управления</div>
    <div class="topbar-meta">Sheber.kz • <?= date('d.m.Y H:i') ?></div>
  </div>

  <!-- ══ OVERVIEW ══ -->
  <div id="tab-overview" class="tab-content active">

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-label">👥 Клиенты</div>
        <div class="stat-value" style="color:#3B82F6;"><?= fmtNum($stats['clients'] ?? 0) ?></div>
        <div class="stat-sub">+<?= $stats['users_today'] ?? 0 ?> сегодня</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">🔧 Мастера</div>
        <div class="stat-value" style="color:#10B981;"><?= fmtNum($stats['masters'] ?? 0) ?></div>
        <div class="stat-sub">🟢 <?= $stats['masters_online'] ?? 0 ?> онлайн</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">📋 Заказы всего</div>
        <div class="stat-value" style="color:#F97316;"><?= fmtNum($stats['orders_total'] ?? 0) ?></div>
        <div class="stat-sub">+<?= $stats['orders_today'] ?? 0 ?> сегодня</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">✅ Выполнено</div>
        <div class="stat-value" style="color:#10B981;"><?= fmtNum($stats['orders_done'] ?? 0) ?></div>
        <div class="stat-sub"><?= $stats['orders_total'] ? round(($stats['orders_done']/$stats['orders_total'])*100) : 0 ?>% конверсия</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">⚡ Активные</div>
        <div class="stat-value" style="color:#F59E0B;"><?= fmtNum($stats['orders_active'] ?? 0) ?></div>
        <div class="stat-sub">в процессе</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">💎 Подписки</div>
        <div class="stat-value" style="color:#8B5CF6;"><?= fmtNum($stats['subs_active'] ?? 0) ?></div>
        <div class="stat-sub">активных</div>
      </div>
      <div class="stat-card" style="grid-column:span 2;">
        <div class="stat-label">💰 Оборот (по ценам заказов)</div>
        <div class="stat-value" style="color:#0069ff;font-size:22px;"><?= fmtNum($stats['revenue'] ?? 0) ?> ₸</div>
        <div class="stat-sub">за всё время</div>
      </div>
    </div>

    <!-- Chart -->
    <div class="chart-wrap">
      <div class="chart-title">📈 Заказы за последние 7 дней</div>
      <?php
        $maxCnt = max(array_column($chartDays, 'cnt') ?: [1], 1);
        $dayLabels = ['Вс','Пн','Вт','Ср','Чт','Пт','Сб'];
      ?>
      <div class="chart-bars">
        <?php foreach ($chartDays as $d):
          $pct = max(round(($d['cnt']/$maxCnt)*100), $d['cnt']>0?5:0);
          $dow = $dayLabels[(int)date('w', strtotime($d['day']))];
        ?>
        <div class="chart-bar-wrap">
          <div class="chart-bar-val"><?= $d['cnt']>0 ? $d['cnt'] : '' ?></div>
          <div class="chart-bar-inner">
            <div class="chart-bar" style="height:<?= $pct ?>%;"></div>
          </div>
          <div class="chart-bar-lbl"><?= $dow ?></div>
        </div>
        <?php endforeach; ?>
      </div>
    </div>

  </div>

  <!-- ══ ORDERS ══ -->
  <div id="tab-orders" class="tab-content">
    <div class="section">
      <div class="section-head">
        <div class="section-title">Последние 20 заказов</div>
        <span class="badge badge-blue"><?= count($recentOrders) ?></span>
      </div>
      <table>
        <thead><tr>
          <th>#</th><th>Категория</th><th>Клиент</th><th>Мастер</th><th>Цена</th><th>Статус</th><th>Дата</th>
        </tr></thead>
        <tbody>
        <?php foreach ($recentOrders as $o): ?>
        <tr>
          <td style="color:#9999b0;font-size:12px;">#<?= $o['id'] ?></td>
          <td style="font-weight:700;"><?= htmlspecialchars($o['category']) ?></td>
          <td><?= htmlspecialchars($o['client_name']) ?></td>
          <td><?= htmlspecialchars($o['master_name']) ?></td>
          <td style="font-weight:800;color:#10b981;"><?= fmtNum((float)$o['price']) ?> ₸</td>
          <td><?= statusBadge($o['status']) ?></td>
          <td style="color:#9999b0;font-size:12px;"><?= substr($o['created_at'],0,10) ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>

  <!-- ══ USERS ══ -->
  <div id="tab-users" class="tab-content">
    <div class="section">
      <div class="section-head">
        <div class="section-title">Последние 20 пользователей</div>
        <span class="badge badge-blue"><?= count($recentUsers) ?></span>
      </div>
      <table>
        <thead><tr>
          <th>#</th><th>Имя</th><th>Телефон</th><th>Роль</th><th>Дата</th>
        </tr></thead>
        <tbody>
        <?php foreach ($recentUsers as $u): ?>
        <tr>
          <td style="color:#9999b0;font-size:12px;"><?= $u['id'] ?></td>
          <td style="font-weight:700;"><?= htmlspecialchars($u['name'] ?? '—') ?></td>
          <td style="font-size:12px;color:#9999b0;"><?= htmlspecialchars($u['phone'] ?? '—') ?></td>
          <td>
            <?php if ($u['role']==='master'): ?>
              <span class="badge badge-green">Мастер</span>
            <?php elseif ($u['role']==='client'): ?>
              <span class="badge badge-blue">Клиент</span>
            <?php else: ?>
              <span class="badge badge-gray"><?= htmlspecialchars($u['role']??'—') ?></span>
            <?php endif; ?>
          </td>
          <td style="color:#9999b0;font-size:12px;"><?= substr($u['created_at']??'',0,10) ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>

  <!-- ══ MASTERS ══ -->
  <div id="tab-masters" class="tab-content">
    <div class="section">
      <div class="section-head">
        <div class="section-title">Топ мастеров по заказам</div>
      </div>
      <table>
        <thead><tr>
          <th>#</th><th>Имя</th><th>Телефон</th><th>Заказов</th><th>Рейтинг</th>
        </tr></thead>
        <tbody>
        <?php foreach ($topMasters as $i => $m): ?>
        <tr>
          <td style="color:#9999b0;font-size:12px;"><?= $i+1 ?></td>
          <td style="font-weight:700;"><?= htmlspecialchars($m['name']??'—') ?>
            <?php if ($i === 0): ?><span style="font-size:14px;margin-left:4px;">👑</span><?php endif; ?>
          </td>
          <td style="font-size:12px;color:#9999b0;"><?= htmlspecialchars($m['phone']??'—') ?></td>
          <td style="font-weight:800;color:#0069ff;"><?= (int)$m['orders_cnt'] ?></td>
          <td>
            <span class="stars"><?= str_repeat('★', min(5,(int)round((float)$m['avg_rating']))) ?></span>
            <span style="font-size:12px;color:#9999b0;margin-left:4px;"><?= number_format((float)$m['avg_rating'],1) ?></span>
          </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>

</main>

<script>
function showTab(id) {
  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  document.getElementById('tab-' + id)?.classList.add('active');
  event.currentTarget?.classList.add('active');
}
</script>
</body>
</html>