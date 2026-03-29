<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

$me = current_user($pdo);
if (!$me) { header('Location: /index.php?login=required'); exit; }
if (($me['role'] ?? '') !== 'master') { header('Location: /index.php?forbidden=1'); exit; }

$lang = lang_get();
?>
<!doctype html>
<html lang="<?= e($lang) ?>" data-theme="<?= e(theme_get()) ?>">
<head>
  <script src="/assets/js/prefs.js"></script>
  <script>Prefs.applyThemeASAP();</script>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Sheber.kz — <?= $lang === 'ru' ? 'Пополнение баланса' : 'Балансты толтыру' ?></title>
  <link rel="icon" type="image/png" sizes="32x32" href="favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/index.css?v=5">
  <style>
    .amount-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:10px; margin-bottom:20px; }
    .amount-btn { padding:14px 8px; border-radius:16px; border:1.5px solid var(--border); background:var(--surface-highlight);
      font-weight:800; font-size:14px; cursor:pointer; color:var(--text-main); transition:all .15s; text-align:center; }
    .amount-btn:hover, .amount-btn.selected { border-color:var(--primary); background:rgba(0,105,255,.1); color:var(--primary); }
    .method-card { display:flex; align-items:center; gap:14px; padding:14px 16px; border-radius:16px;
      border:1.5px solid var(--border); background:var(--surface-highlight); cursor:pointer; margin-bottom:10px; transition:all .15s; }
    .method-card:hover, .method-card.selected { border-color:var(--primary); background:rgba(0,105,255,.08); }
    .method-icon { width:42px; height:42px; border-radius:12px; display:flex; align-items:center; justify-content:center;
      font-size:20px; flex-shrink:0; }
    .history-row { display:flex; justify-content:space-between; align-items:center; padding:12px 0;
      border-bottom:1px solid var(--border); }
    .history-row:last-child { border-bottom:none; }
    .amount-plus { color:var(--success); font-weight:800; }
    .amount-minus { color:var(--danger); font-weight:800; }
  </style>
</head>
<body data-page="payment-master">
<div class="app-container">

  <!-- Header -->
  <header class="header">
    <div class="brand">
      <a href="home-master.php" class="menu-btn" style="padding:0;margin-right:4px;text-decoration:none;color:var(--text-main);">
        <svg viewBox="0 0 24 24" stroke="currentColor" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:24px;height:24px;">
          <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
      </a>
      <span style="font-weight:800;font-size:16px;">Sheber<span style="color:#0069ff">.kz</span></span>
    </div>
    <div class="txt-sm" style="font-weight:700;color:var(--text-sec);"><?= $lang === 'ru' ? 'Касса' : 'Касса' ?></div>
  </header>

  <!-- Balance card -->
  <div class="card ent-card" style="margin-bottom:20px;">
    <div class="tag" style="background:rgba(46,196,182,0.15);color:#2EC4B6;"><?= $lang === 'ru' ? 'Текущий баланс' : 'Ағымдағы баланс' ?></div>
    <div class="h1" style="margin:8px 0 4px;" id="currentBalance">
      <?= e(number_format((float)($me['balance'] ?? 0), 0, '.', ' ')) ?> ₸
    </div>
    <div class="txt-sm" style="opacity:.7;"><?= $lang === 'ru' ? 'Доступно для оплаты подписки' : 'Жазылымды төлеуге қолжетімді' ?></div>
  </div>

  <!-- Top-up section -->
  <div class="h3" style="margin-bottom:14px;"><?= $lang === 'ru' ? 'Пополнить баланс' : 'Баланс толтыру' ?></div>

  <!-- Quick amounts -->
  <div class="amount-grid" id="amountGrid">
    <?php foreach ([500,1000,2000,3000,5000,10000] as $a): ?>
    <button class="amount-btn" onclick="selectAmount(<?= $a ?>)"><?= number_format($a,0,'.',' ') ?> ₸</button>
    <?php endforeach; ?>
  </div>

  <!-- Custom amount -->
  <div style="margin-bottom:20px;">
    <input type="number" id="customAmount" class="auth-input" min="100" max="500000" step="100"
      placeholder="<?= $lang === 'ru' ? 'Другая сумма...' : 'Басқа сома...' ?>"
      oninput="onCustomAmount(this.value)" style="font-size:16px;font-weight:700;">
  </div>

  <!-- Payment methods -->
  <div class="h3" style="margin-bottom:14px;"><?= $lang === 'ru' ? 'Способ оплаты' : 'Төлем әдісі' ?></div>

  <div id="methodsList">
    <div class="method-card selected" onclick="selectMethod('kaspi')" id="method-kaspi">
      <div class="method-icon" style="background:#FF0000;">💳</div>
      <div style="flex:1;">
        <div style="font-weight:800;font-size:14px;">Kaspi Pay</div>
        <div class="txt-sm" style="opacity:.7;"><?= $lang === 'ru' ? 'Онлайн оплата' : 'Онлайн төлем' ?></div>
      </div>
      <div id="check-kaspi" style="color:var(--primary);font-size:18px;">✓</div>
    </div>

    <div class="method-card" onclick="selectMethod('card')" id="method-card">
      <div class="method-icon" style="background:linear-gradient(135deg,#667eea,#764ba2);">💳</div>
      <div style="flex:1;">
        <div style="font-weight:800;font-size:14px;"><?= $lang === 'ru' ? 'Банковская карта' : 'Банк картасы' ?></div>
        <div class="txt-sm" style="opacity:.7;">Visa / Mastercard</div>
      </div>
      <div id="check-card" style="color:transparent;font-size:18px;">✓</div>
    </div>

    <div class="method-card" onclick="selectMethod('transfer')" id="method-transfer">
      <div class="method-icon" style="background:linear-gradient(135deg,#11998e,#38ef7d);">🏦</div>
      <div style="flex:1;">
        <div style="font-weight:800;font-size:14px;"><?= $lang === 'ru' ? 'Перевод' : 'Аудару' ?></div>
        <div class="txt-sm" style="opacity:.7;"><?= $lang === 'ru' ? 'Банковский перевод' : 'Банк аударымы' ?></div>
      </div>
      <div id="check-transfer" style="color:transparent;font-size:18px;">✓</div>
    </div>
  </div>

  <!-- Summary -->
  <div class="card" style="margin-top:20px;padding:16px;background:var(--surface-highlight);border:1px solid var(--border);">
    <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
      <div class="txt-sm" style="opacity:.7;"><?= $lang === 'ru' ? 'Сумма' : 'Сома' ?></div>
      <div style="font-weight:800;" id="summaryAmount">—</div>
    </div>
    <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
      <div class="txt-sm" style="opacity:.7;"><?= $lang === 'ru' ? 'Комиссия' : 'Комиссия' ?></div>
      <div class="txt-sm" style="color:var(--success);font-weight:700;">0 ₸</div>
    </div>
    <div style="height:1px;background:var(--border);margin-bottom:8px;"></div>
    <div style="display:flex;justify-content:space-between;">
      <div style="font-weight:800;"><?= $lang === 'ru' ? 'Итого' : 'Барлығы' ?></div>
      <div style="font-weight:800;color:var(--primary);font-size:18px;" id="summaryTotal">—</div>
    </div>
  </div>

  <button class="cta-btn" style="margin-top:16px;" id="payBtn" onclick="initiatePayment()" disabled>
    <svg viewBox="0 0 24 24" style="width:18px;height:18px;" fill="none" stroke="currentColor" stroke-width="2">
      <rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>
    </svg>
    <span id="payBtnText"><?= $lang === 'ru' ? 'Выберите сумму' : 'Соманы таңдаңыз' ?></span>
  </button>

  <!-- Transaction history -->
  <div style="margin-top:28px;">
    <div class="h3" style="margin-bottom:14px;"><?= $lang === 'ru' ? 'История операций' : 'Операциялар тарихы' ?></div>
    <div class="card" style="padding:16px;" id="txHistory">
      <div class="txt-sm" style="opacity:.6;text-align:center;padding:12px;"><?= $lang === 'ru' ? 'Загрузка...' : 'Жүктелуде...' ?></div>
    </div>
  </div>

</div>

<div id="toast" class="toast"></div>

<!-- Payment modal -->
<div id="payModal" style="display:none;position:fixed;inset:0;z-index:999;background:rgba(0,0,0,.6);align-items:flex-end;justify-content:center;">
  <div style="background:var(--surface);border-radius:24px 24px 0 0;padding:24px 20px 40px;width:100%;max-width:480px;animation:slideUp .3s ease;">
    <div class="h3" style="margin-bottom:4px;" id="modalTitle">Kaspi Pay</div>
    <div class="txt-sm" style="opacity:.7;margin-bottom:20px;" id="modalDesc">Перейдите в приложение Kaspi</div>
    <div id="modalContent"></div>
    <button class="cta-btn" style="margin-top:16px;background:var(--surface-highlight);color:var(--text-main);border:1px solid var(--border);" onclick="closePayModal()">
      <?= $lang === 'ru' ? 'Закрыть' : 'Жабу' ?>
    </button>
  </div>
</div>

<script>
const LANG = '<?= e($lang) ?>';
const fmt = n => Math.round(Number(n||0)).toLocaleString('ru-RU');

let _amount = 0;
let _method = 'kaspi';

function selectAmount(n) {
  _amount = n;
  document.querySelectorAll('.amount-btn').forEach(b => b.classList.remove('selected'));
  event.target.classList.add('selected');
  document.getElementById('customAmount').value = '';
  updateSummary();
}

function onCustomAmount(v) {
  _amount = parseInt(v) || 0;
  document.querySelectorAll('.amount-btn').forEach(b => b.classList.remove('selected'));
  updateSummary();
}

function selectMethod(m) {
  _method = m;
  ['kaspi','card','transfer'].forEach(k => {
    document.getElementById('method-' + k)?.classList.remove('selected');
    const chk = document.getElementById('check-' + k);
    if (chk) chk.style.color = 'transparent';
  });
  document.getElementById('method-' + m)?.classList.add('selected');
  const c = document.getElementById('check-' + m);
  if (c) c.style.color = 'var(--primary)';
}

function updateSummary() {
  const amEl = document.getElementById('summaryAmount');
  const totEl = document.getElementById('summaryTotal');
  const btn = document.getElementById('payBtn');
  const btnTxt = document.getElementById('payBtnText');
  if (_amount >= 100) {
    const s = fmt(_amount) + ' ₸';
    if (amEl) amEl.textContent = s;
    if (totEl) totEl.textContent = s;
    if (btn) btn.disabled = false;
    if (btnTxt) btnTxt.textContent = (LANG === 'ru' ? 'Оплатить ' : 'Төлеу ') + s;
  } else {
    if (amEl) amEl.textContent = '—';
    if (totEl) totEl.textContent = '—';
    if (btn) btn.disabled = true;
    if (btnTxt) btnTxt.textContent = LANG === 'ru' ? 'Выберите сумму' : 'Соманы таңдаңыз';
  }
}

function initiatePayment() {
  if (_amount < 100) return;
  const modal = document.getElementById('payModal');
  const title = document.getElementById('modalTitle');
  const desc  = document.getElementById('modalDesc');
  const cont  = document.getElementById('modalContent');

  if (_method === 'kaspi') {
    if (title) title.textContent = 'Kaspi Pay';
    if (desc) desc.textContent = LANG === 'ru' ? 'Перейдите по ссылке для оплаты' : 'Төлем сілтемесіне өтіңіз';
    if (cont) cont.innerHTML = `
      <div style="background:var(--surface-highlight);border-radius:16px;padding:20px;text-align:center;margin-bottom:12px;">
        <div style="font-size:40px;margin-bottom:8px;">📱</div>
        <div style="font-weight:800;font-size:18px;margin-bottom:4px;">${fmt(_amount)} ₸</div>
        <div class="txt-sm" style="opacity:.7;">sheber.kz@kaspi</div>
      </div>
      <a href="https://kaspi.kz/pay/sheber" target="_blank" class="cta-btn" style="text-decoration:none;display:flex;">
        ${LANG === 'ru' ? 'Открыть Kaspi' : 'Kaspi ашу'}
      </a>`;
  } else if (_method === 'card') {
    if (title) title.textContent = LANG === 'ru' ? 'Банковская карта' : 'Банк картасы';
    if (desc) desc.textContent = 'Visa / Mastercard';
    if (cont) cont.innerHTML = `
      <div style="background:linear-gradient(135deg,#667eea,#764ba2);border-radius:16px;padding:20px;color:#fff;margin-bottom:14px;">
        <div style="font-size:24px;letter-spacing:3px;margin-bottom:8px;">•••• •••• •••• ••••</div>
        <div style="font-size:13px;opacity:.8;">Тестовый режим — интеграция с Stripe/Cloudpayments</div>
      </div>
      <div class="txt-sm" style="opacity:.6;text-align:center;">${LANG === 'ru' ? 'Функция в разработке' : 'Функция әзірленуде'}</div>`;
  } else {
    if (title) title.textContent = LANG === 'ru' ? 'Банковский перевод' : 'Банк аударымы';
    if (desc) desc.textContent = '';
    if (cont) cont.innerHTML = `
      <div style="background:var(--surface-highlight);border-radius:16px;padding:16px;margin-bottom:12px;">
        <div class="txt-sm" style="opacity:.7;margin-bottom:6px;">${LANG === 'ru' ? 'Реквизиты' : 'Деректемелер'}</div>
        <div style="font-weight:800;margin-bottom:4px;">ТОО "Sheber Technologies"</div>
        <div class="txt-sm">БИН: 240140012345</div>
        <div class="txt-sm">ИИК: KZ00000000000000000</div>
        <div class="txt-sm">БИК: KCJBKZKX</div>
        <div class="txt-sm" style="margin-top:8px;color:var(--primary);font-weight:700;">${LANG === 'ru' ? 'Назначение' : 'Мақсаты'}: ID<?= (int)$me['id'] ?> +${fmt(_amount)}₸</div>
      </div>`;
  }

  if (modal) { modal.style.display = 'flex'; }
}

function closePayModal() {
  const modal = document.getElementById('payModal');
  if (modal) modal.style.display = 'none';
}

// Load transaction history
async function loadHistory() {
  const root = document.getElementById('txHistory');
  if (!root) return;
  try {
    const r = await fetch('api/payment_history.php', { credentials: 'same-origin' });
    const d = await r.json().catch(() => null);
    const rows = Array.isArray(d?.data) ? d.data : [];
    if (rows.length === 0) {
      root.innerHTML = `<div class="txt-sm" style="opacity:.6;text-align:center;padding:12px;">${LANG === 'ru' ? 'Операций нет' : 'Операциялар жоқ'}</div>`;
      return;
    }
    root.innerHTML = rows.map(tx => {
      const sign = Number(tx.amount) >= 0 ? '+' : '';
      const cls  = Number(tx.amount) >= 0 ? 'amount-plus' : 'amount-minus';
      const date = String(tx.created_at || '').slice(0,10);
      return `<div class="history-row">
        <div>
          <div style="font-weight:700;font-size:14px;">${tx.description || '—'}</div>
          <div class="txt-sm" style="opacity:.6;">${date}</div>
        </div>
        <div class="${cls}">${sign}${fmt(tx.amount)} ₸</div>
      </div>`;
    }).join('');
  } catch {
    root.innerHTML = `<div class="txt-sm" style="opacity:.5;text-align:center;padding:12px;">—</div>`;
  }
}

// Show toast
function showToast(msg) {
  let el = document.getElementById('toast');
  if (!el) return;
  el.textContent = msg;
  el.classList.add('show');
  setTimeout(() => el.classList.remove('show'), 3000);
}

loadHistory();
</script>
</body>
</html>