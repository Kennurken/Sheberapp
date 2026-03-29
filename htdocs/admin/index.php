<?php
declare(strict_types=1);
require __DIR__ . '/../init.php';
require_admin();

$tab = (string)($_GET['tab'] ?? 'users');
$tab = in_array($tab, ['users','orders','complaints'], true) ? $tab : 'users';
$csrf = csrf_token();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $tok = (string)($_POST['csrf_token'] ?? '');
  if (!csrf_check($tok)) { http_response_code(419); echo 'CSRF'; exit; }

  $action = (string)($_POST['action'] ?? '');
  if ($action === 'toggle_block') {
    $uid = (int)($_POST['user_id'] ?? 0);
    if ($uid > 0) {
      $pdo->prepare('UPDATE users SET is_blocked = IF(COALESCE(is_blocked,0)=1,0,1) WHERE id = ?')->execute([$uid]);
    }
    header('Location: /admin/index.php?tab=users'); exit;
  }
  if ($action === 'complaint_status') {
    $cid = (int)($_POST['complaint_id'] ?? 0);
    $status = (string)($_POST['status'] ?? 'open');
    if ($cid > 0 && in_array($status, ['open','resolved'], true)) {
      $pdo->prepare('UPDATE complaints SET status = ? WHERE id = ?')->execute([$status, $cid]);
    }
    header('Location: /admin/index.php?tab=complaints'); exit;
  }
}

function dt(?string $v): string { return $v ? e($v) : '<span style="opacity:.35">—</span>'; }

// Stats
$totalUsers   = (int)$pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$totalMasters = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='master'")->fetchColumn();
$totalOrders  = (int)$pdo->query("SELECT COUNT(*) FROM orders")->fetchColumn();
$openComplaints = 0;
try { $openComplaints = (int)$pdo->query("SELECT COUNT(*) FROM complaints WHERE status='open'")->fetchColumn(); } catch(Throwable){}
?>
<!doctype html>
<html lang="ru" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Admin — Sheber.kz</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/index.css?v=20">
  <script>
    (function(){
      try { var t=localStorage.getItem('theme'); if(t==='light'||t==='dark') document.documentElement.setAttribute('data-theme',t); } catch(e){}
    })();
  </script>
  <style>
    body { min-height: 100vh; }
    .adm-layout { display: flex; min-height: 100vh; }

    /* Sidebar */
    .adm-sidebar {
      width: 220px; flex-shrink: 0;
      background: var(--surface);
      border-right: 1px solid var(--border);
      padding: 24px 16px;
      display: flex; flex-direction: column;
      position: fixed; top:0; left:0; bottom:0;
      z-index: 10;
    }
    .adm-logo { font-size:18px; font-weight:900; letter-spacing:-0.5px; margin-bottom:28px; padding:0 4px; }
    .adm-logo .dot { color: var(--primary); }
    .adm-nav { display:flex; flex-direction:column; gap:3px; flex:1; }
    .adm-nav-item {
      display:flex; align-items:center; gap:10px;
      padding:10px 12px; border-radius:var(--radius-md);
      text-decoration:none; color:var(--text-sec);
      font-size:13px; font-weight:700;
      transition: background .16s, color .16s;
    }
    .adm-nav-item:hover { background:var(--surface-highlight); color:var(--text-main); }
    .adm-nav-item.active { background:var(--primary-dim); color:var(--primary); }
    .adm-nav-item svg { width:16px; height:16px; fill:none; stroke:currentColor; stroke-width:2; flex-shrink:0; }
    .adm-nav-badge { margin-left:auto; min-width:18px; height:18px; padding:0 5px; background:var(--danger); border-radius:999px; font-size:10px; font-weight:800; color:#fff; display:flex; align-items:center; justify-content:center; }

    .adm-bottom { margin-top:auto; }
    .adm-logout { display:flex; align-items:center; gap:10px; padding:10px 12px; border-radius:var(--radius-md); text-decoration:none; color:var(--danger); font-size:13px; font-weight:700; transition:background .16s; }
    .adm-logout:hover { background:var(--danger-dim); }
    .adm-logout svg { width:16px; height:16px; fill:none; stroke:currentColor; stroke-width:2; }

    /* Main content */
    .adm-main { margin-left:220px; flex:1; padding:28px 28px 48px; max-width:1100px; }

    /* Stats row */
    .adm-stats { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; margin-bottom:24px; }
    .adm-stat { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius-lg); padding:16px 18px; box-shadow:var(--shadow-card); }
    .adm-stat-val { font-size:28px; font-weight:900; letter-spacing:-1px; line-height:1.1; }
    .adm-stat-lbl { font-size:11px; color:var(--text-sec); font-weight:700; text-transform:uppercase; letter-spacing:0.5px; margin-top:4px; }

    /* Table card */
    .adm-card { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius-xl); box-shadow:var(--shadow-card); overflow:hidden; }
    .adm-card-head { padding:18px 20px 14px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; }
    .adm-card-head .h3 { margin:0; }

    table  { width:100%; border-collapse:collapse; }
    th, td { padding:11px 14px; border-bottom:1px solid var(--border); text-align:left; vertical-align:middle; }
    th     { font-size:11px; font-weight:700; color:var(--text-sec); text-transform:uppercase; letter-spacing:0.5px; background:var(--surface-2); }
    tbody tr:last-child td { border-bottom:none; }
    tbody tr:hover td { background:var(--surface-2); }

    /* Inline form */
    .adm-form { display:inline-flex; gap:5px; }

    /* Responsive */
    @media(max-width:768px){
      .adm-sidebar { display:none; }
      .adm-main    { margin-left:0; padding:16px; }
      .adm-stats   { grid-template-columns:repeat(2,1fr); }
    }
  </style>
</head>
<body>
<div class="adm-layout">

  <!-- ── Sidebar ───────────────────────────────────────── -->
  <aside class="adm-sidebar">
    <div class="adm-logo">Sheber<span class="dot">.kz</span></div>

    <nav class="adm-nav">
      <a class="adm-nav-item <?= $tab==='users'?'active':'' ?>" href="/admin/index.php?tab=users">
        <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        Пользователи
      </a>
      <a class="adm-nav-item <?= $tab==='orders'?'active':'' ?>" href="/admin/index.php?tab=orders">
        <svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        Заказы
      </a>
      <a class="adm-nav-item <?= $tab==='complaints'?'active':'' ?>" href="/admin/index.php?tab=complaints">
        <svg viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
        Жалобы
        <?php if ($openComplaints > 0): ?>
          <span class="adm-nav-badge"><?= $openComplaints ?></span>
        <?php endif; ?>
      </a>
    </nav>

    <div class="adm-bottom">
      <a class="adm-logout" href="/admin/logout.php">
        <svg viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Выйти
      </a>
    </div>
  </aside>

  <!-- ── Main ──────────────────────────────────────────── -->
  <main class="adm-main">

    <!-- Page title -->
    <div style="margin-bottom:20px;">
      <div class="h2">
        <?php if ($tab==='users'): ?>Пользователи
        <?php elseif($tab==='orders'): ?>Заказы
        <?php else: ?>Жалобы<?php endif; ?>
      </div>
      <div class="txt-sm mt-8" style="opacity:.6;">Sheber.kz · Admin panel</div>
    </div>

    <!-- Stats -->
    <div class="adm-stats">
      <div class="adm-stat">
        <div class="adm-stat-val"><?= $totalUsers ?></div>
        <div class="adm-stat-lbl">Пользователей</div>
      </div>
      <div class="adm-stat">
        <div class="adm-stat-val"><?= $totalMasters ?></div>
        <div class="adm-stat-lbl">Мастеров</div>
      </div>
      <div class="adm-stat">
        <div class="adm-stat-val"><?= $totalOrders ?></div>
        <div class="adm-stat-lbl">Заказов</div>
      </div>
      <div class="adm-stat">
        <div class="adm-stat-val" style="color:<?= $openComplaints>0?'var(--danger)':'var(--text-main)' ?>"><?= $openComplaints ?></div>
        <div class="adm-stat-lbl">Жалоб открыто</div>
      </div>
    </div>

    <!-- Table card -->
    <div class="adm-card">

      <?php if ($tab === 'users'): ?>
        <?php
          $st = $pdo->query("SELECT id,name,email,role,city,created_at,COALESCE(balance,0) AS balance,COALESCE(is_blocked,0) AS is_blocked,last_seen FROM users ORDER BY id DESC LIMIT 500");
          $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
        ?>
        <div class="adm-card-head">
          <div class="h3">Все пользователи</div>
          <span class="tag"><?= count($rows) ?> записей</span>
        </div>
        <div style="overflow-x:auto;">
          <table>
            <thead>
              <tr><th>ID</th><th>Имя</th><th>Email</th><th>Роль</th><th>Город</th><th>Баланс</th><th>Статус</th><th>Зарег.</th><th></th></tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r):
              $online  = !empty($r['last_seen']) && (time()-strtotime((string)$r['last_seen'])) <= 120;
              $blocked = (int)($r['is_blocked']??0) === 1;
            ?>
              <tr>
                <td style="font-size:12px;color:var(--text-muted);font-weight:700;">#<?= (int)$r['id'] ?></td>
                <td>
                  <div style="font-weight:700;font-size:13px;"><?= e($r['name']??'') ?></div>
                  <?php if ($blocked): ?><span class="tag tag-danger" style="margin-top:3px;">BLOCK</span><?php endif; ?>
                </td>
                <td style="font-size:12px;color:var(--text-sec);"><?= e($r['email']??'') ?></td>
                <td>
                  <span class="adm-badge <?= (string)($r['role']??'')==='master'?'role-master':'role-client' ?>">
                    <?= e($r['role']??'') ?>
                  </span>
                </td>
                <td style="font-size:13px;"><?= e($r['city']??'') ?></td>
                <td style="font-weight:700;font-size:13px;"><?= number_format((int)($r['balance']??0)) ?> ₸</td>
                <td>
                  <?php if ($online): ?>
                    <span class="adm-badge status-online">● online</span>
                  <?php else: ?>
                    <span style="font-size:12px;color:var(--text-muted);">—</span>
                  <?php endif; ?>
                </td>
                <td style="font-size:11px;color:var(--text-muted);"><?= $r['created_at'] ? date('d.m.y', strtotime($r['created_at'])) : '—' ?></td>
                <td>
                  <form method="post" class="adm-form">
                    <input type="hidden" name="csrf_token" value="<?= e($csrf) ?>">
                    <input type="hidden" name="action" value="toggle_block">
                    <input type="hidden" name="user_id" value="<?= (int)$r['id'] ?>">
                    <button class="adm-btn <?= $blocked?'ok':'danger' ?>" type="submit">
                      <?= $blocked ? '✓ Разблок' : '✕ Блок' ?>
                    </button>
                  </form>
                </td>
              </tr>
            <?php endforeach; ?>
            </tbody>
          </table>
        </div>

      <?php elseif ($tab === 'orders'): ?>
        <?php
          $st = $pdo->query("
            SELECT o.id,o.status,o.price,o.created_at,o.accepted_at,o.completed_at,
                   c.name AS client_name, m.name AS master_name
            FROM orders o
            LEFT JOIN users c ON c.id=o.client_id
            LEFT JOIN users m ON m.id=o.master_id
            ORDER BY o.id DESC LIMIT 500
          ");
          $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
        ?>
        <div class="adm-card-head">
          <div class="h3">Все заказы</div>
          <span class="tag"><?= count($rows) ?> записей</span>
        </div>
        <div style="overflow-x:auto;">
          <table>
            <thead>
              <tr><th>ID</th><th>Статус</th><th>Цена</th><th>Клиент</th><th>Мастер</th><th>Создан</th><th>Принят</th><th>Завершён</th></tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $r):
              $statusClass = match((string)($r['status']??'')) {
                'new'       => '',
                'active'    => 'role-master',
                'completed' => 'status-online',
                default     => ''
              };
            ?>
              <tr>
                <td style="font-size:12px;color:var(--text-muted);font-weight:700;">#<?= (int)$r['id'] ?></td>
                <td><span class="adm-badge <?= $statusClass ?>"><?= e($r['status']??'') ?></span></td>
                <td style="font-weight:700;"><?= number_format((int)($r['price']??0)) ?> ₸</td>
                <td style="font-size:13px;"><?= e($r['client_name']??'—') ?></td>
                <td style="font-size:13px;"><?= e($r['master_name']??'—') ?></td>
                <td style="font-size:11px;color:var(--text-muted);"><?= $r['created_at'] ? date('d.m.y H:i', strtotime($r['created_at'])) : '—' ?></td>
                <td style="font-size:11px;color:var(--text-muted);"><?= dt($r['accepted_at']??null) ?></td>
                <td style="font-size:11px;color:var(--text-muted);"><?= dt($r['completed_at']??null) ?></td>
              </tr>
            <?php endforeach; ?>
            </tbody>
          </table>
        </div>

      <?php else: ?>
        <?php
          $rows = [];
          try {
            $st = $pdo->query("SELECT id,order_id,from_user_id,against_user_id,reason,body,status,created_at FROM complaints ORDER BY id DESC LIMIT 500");
            $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
          } catch(Throwable){}
        ?>
        <div class="adm-card-head">
          <div class="h3">Жалобы</div>
          <?php if ($openComplaints > 0): ?>
            <span class="tag tag-danger"><?= $openComplaints ?> открытых</span>
          <?php endif; ?>
        </div>

        <?php if (!$rows): ?>
          <div class="empty-state" style="padding:40px 20px;">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
            <div class="empty-title">Жалоб нет</div>
            <div class="empty-desc">Или таблица complaints ещё не создана.</div>
          </div>
        <?php else: ?>
          <div style="overflow-x:auto;">
            <table>
              <thead>
                <tr><th>ID</th><th>Заказ</th><th>От</th><th>На</th><th>Причина</th><th>Текст</th><th>Статус</th><th>Дата</th><th></th></tr>
              </thead>
              <tbody>
              <?php foreach ($rows as $r):
                $isOpen = (string)($r['status']??'open') === 'open';
              ?>
                <tr>
                  <td style="font-size:12px;color:var(--text-muted);font-weight:700;">#<?= (int)$r['id'] ?></td>
                  <td style="font-size:12px;">#<?= (int)($r['order_id']??0) ?></td>
                  <td style="font-size:12px;">#<?= (int)($r['from_user_id']??0) ?></td>
                  <td style="font-size:12px;">#<?= (int)($r['against_user_id']??0) ?></td>
                  <td><span class="adm-badge"><?= e($r['reason']??'') ?></span></td>
                  <td style="max-width:280px;font-size:13px;line-height:1.45;white-space:pre-wrap;overflow-wrap:anywhere;"><?= e($r['body']??'') ?></td>
                  <td>
                    <span class="adm-badge <?= $isOpen?'status-blocked':'status-online' ?>">
                      <?= $isOpen ? 'open' : 'resolved' ?>
                    </span>
                  </td>
                  <td style="font-size:11px;color:var(--text-muted);white-space:nowrap;"><?= $r['created_at'] ? date('d.m.y H:i', strtotime($r['created_at'])) : '—' ?></td>
                  <td>
                    <form method="post" class="adm-form">
                      <input type="hidden" name="csrf_token" value="<?= e($csrf) ?>">
                      <input type="hidden" name="action" value="complaint_status">
                      <input type="hidden" name="complaint_id" value="<?= (int)$r['id'] ?>">
                      <?php if ($isOpen): ?>
                        <button class="adm-btn ok" type="submit" name="status" value="resolved">✓ Resolve</button>
                      <?php else: ?>
                        <button class="adm-btn" type="submit" name="status" value="open">↺ Reopen</button>
                      <?php endif; ?>
                    </form>
                  </td>
                </tr>
              <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php endif; ?>

      <?php endif; ?>

    </div><!-- /.adm-card -->

  </main>
</div>
</body>
</html>