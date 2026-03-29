(() => {
  'use strict';

  // ─────────────────────────────────────────
  // i18n
  // ─────────────────────────────────────────
  const I18N = {
    kk: {
      loading:              'Жүктелуде...',
      pageTitle:            'Жазылым',
      planChooseBtn:        'Таңдау',
      planCurrent:          'Ағымдағы жоспар',
      planCurrentBadge:     'Сіздің жоспарыңыз',
      planChangeNext:       'Келесі кезеңде ауысады',
      planScheduled:        'Жоспарланды',
      planActivateBtn:      'Белсендіру',

      planDailyTitle:       'Базалық',
      planDailyDesc:        'Тәулігіне 5 тапсырысқа дейін',
      planDailyF1:          '✓ Тәулігіне 5 тапсырыс',
      planDailyF2:          '✓ Негізгі чат',
      planDailyF3:          '✓ Рейтинг жүйесі',

      planUnlimitedTitle:   'Pro',
      planUnlimitedDesc:    'Шексіз тапсырыстар',
      planUnlimitedF1:      '✓ Шексіз тапсырыстар',
      planUnlimitedF2:      '✓ Басымдылықты көрсету',
      planUnlimitedF3:      '✓ Барлық мүмкіндіктер',

      activeUntil:          'Дейін белсенді:',
      autorenewOn:          'Автожаңарту қосулы',
      autorenewOff:         'Автожаңарту өшірулі',
      autorenewLabel:       'Автожаңарту',
      autorenewDesc:        'Кезең аяқталғанда автоматты түрде жаңартылады',
      cancelAtEnd:          'Кезең аяқталғанда тоқтатылады',
      nextPlan:             'Келесі кезеңде:',
      balance:              'Баланс:',
      insufficientFunds:    'Баланс жеткіліксіз. Қажет:',
      confirmBuy:           'Жазылымды сатып алу?',
      confirmChange:        'Жоспарды ауыстыру?',
      confirmCancel:        'Жазылымды тоқтатасыз ба?',
      success:              'Сәтті!',
      successBuy:           'Жазылым белсендірілді',
      successChange:        'Жоспар жоспарланды',
      successCancel:        'Жазылым тоқтатылды',
      errServerError:       'Сервер қатесі',
      errUnknown:           'Белгісіз қате',
      periodDays:           'күн',
      perPeriod:            '/ кезең',
      cancelSubscription:   'Жазылымнан бас тарту',
      activeOrders:         'Белсенді тапсырыстар:',
      dailyLimit:           'Күнделікті лимит:',
      unlimited:            'шексіз',
    },
    ru: {
      loading:              'Загрузка...',
      pageTitle:            'Подписка',
      planChooseBtn:        'Выбрать',
      planCurrent:          'Текущий план',
      planCurrentBadge:     'Ваш план',
      planChangeNext:       'Изменится в следующем периоде',
      planScheduled:        'Запланировано',
      planActivateBtn:      'Активировать',

      planDailyTitle:       'Базовый',
      planDailyDesc:        'До 5 заказов в день',
      planDailyF1:          '✓ 5 заказов в день',
      planDailyF2:          '✓ Базовый чат',
      planDailyF3:          '✓ Система рейтинга',

      planUnlimitedTitle:   'Pro',
      planUnlimitedDesc:    'Безлимитные заказы',
      planUnlimitedF1:      '✓ Безлимитные заказы',
      planUnlimitedF2:      '✓ Приоритетный показ',
      planUnlimitedF3:      '✓ Все возможности',

      activeUntil:          'Активна до:',
      autorenewOn:          'Автопродление включено',
      autorenewOff:         'Автопродление отключено',
      autorenewLabel:       'Автопродление',
      autorenewDesc:        'Автоматически продлевается по окончании периода',
      cancelAtEnd:          'Отменяется по окончании периода',
      nextPlan:             'Следующий период:',
      balance:              'Баланс:',
      insufficientFunds:    'Недостаточно средств. Нужно:',
      confirmBuy:           'Оформить подписку?',
      confirmChange:        'Сменить план?',
      confirmCancel:        'Отменить подписку?',
      success:              'Готово!',
      successBuy:           'Подписка активирована',
      successChange:        'Смена плана запланирована',
      successCancel:        'Подписка отменена',
      errServerError:       'Ошибка сервера',
      errUnknown:           'Неизвестная ошибка',
      periodDays:           'дн.',
      perPeriod:            '/ период',
      cancelSubscription:   'Отменить подписку',
      activeOrders:         'Активных заказов:',
      dailyLimit:           'Лимит в день:',
      unlimited:            'безлимит',
    },
  };

  const getLang = () => {
    const v = (localStorage.getItem('lang') || 'kk').toLowerCase();
    return v === 'ru' ? 'ru' : 'kk';
  };
  const t = (key) => I18N[getLang()]?.[key] ?? key;
  const esc = (s) => String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  const fmt = (n) => Math.round(Number(n || 0)).toLocaleString('ru-RU');
  const qs = (sel, root = document) => root.querySelector(sel);

  // ─────────────────────────────────────────
  // Toast
  // ─────────────────────────────────────────
  function showToast(msg, duration = 3000) {
    let el = qs('#toast');
    if (!el) { el = document.createElement('div'); el.id = 'toast'; el.className = 'toast'; document.body.appendChild(el); }
    el.textContent = msg;
    el.classList.add('show');
    clearTimeout(el._t);
    el._t = setTimeout(() => el.classList.remove('show'), duration);
  }

  // ─────────────────────────────────────────
  // API
  // ─────────────────────────────────────────
  let CSRF = '';
  async function ensureCsrf() {
    if (CSRF) return CSRF;
    try {
      const r = await fetch('api/csrf.php', { credentials: 'same-origin' });
      const j = await r.json();
      if (j?.ok && j?.data?.csrf_token) CSRF = String(j.data.csrf_token);
    } catch {}
    return CSRF;
  }

  async function apiGet(url) {
    const r = await fetch(url, { credentials: 'same-origin' });
    const d = await r.json().catch(() => null);
    if (!r.ok || !d?.ok) throw new Error(d?.error || 'http_' + r.status);
    return 'data' in d ? d.data : d;
  }

  async function apiPost(url, body) {
    await ensureCsrf();
    const params = new URLSearchParams();
    Object.entries(body || {}).forEach(([k, v]) => params.append(k, String(v ?? '')));
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'X-CSRF-Token': CSRF },
      body: params,
      credentials: 'same-origin',
    });
    const d = await r.json().catch(() => null);
    if (!r.ok || !d?.ok) throw new Error(d?.error || 'http_' + r.status);
    return 'data' in d ? d.data : d;
  }

  // ─────────────────────────────────────────
  // Plan label helpers
  // ─────────────────────────────────────────
  // Maps DB plan index (0=first/cheapest, 1=second...) to i18n prefix
  function planPrefix(idx) {
    return idx === 0 ? 'Daily' : 'Unlimited';
  }

  function buildPlanFeatures(plan, idx) {
    const p = planPrefix(idx);
    const maxD = Number(plan.max_daily_accepts ?? 0);
    const maxA = Number(plan.max_active_orders ?? 0);
    const f1 = maxD > 0
      ? `✓ ${t('dailyLimit')} ${maxD}`
      : `✓ ${t('dailyLimit')} ${t('unlimited')}`;
    const f2 = maxA > 0
      ? `✓ ${t('activeOrders')} ${maxA}`
      : `✓ ${t('activeOrders')} ${t('unlimited')}`;
    const f3 = t(`plan${p}F3`);
    return [f1, f2, f3];
  }

  function planTitle(plan, idx) {
    // Use DB title if it's meaningful, else fall back to i18n
    const dbTitle = String(plan.title || '').trim();
    if (dbTitle && dbTitle.length > 1) return dbTitle;
    return t(`plan${planPrefix(idx)}Title`);
  }

  function planDesc(plan, idx) {
    const maxD = Number(plan.max_daily_accepts ?? 0);
    if (maxD > 0) return getLang() === 'ru' ? `До ${maxD} заказов в день` : `Тәулігіне ${maxD} тапсырысқа дейін`;
    return t(`plan${planPrefix(idx)}Desc`);
  }

  // ─────────────────────────────────────────
  // Render
  // ─────────────────────────────────────────
  function renderPlans(data) {
    const root = qs('#subPlans');
    if (!root) return;

    const { plans = [], subscription: sub = null, me = {} } = data;
    const balance = Number(me?.balance ?? 0);
    const isActive = !!(sub?.is_active);
    const currentPlanId = sub ? Number(sub.plan_id) : 0;
    const nextPlanId = sub ? Number(sub.next_plan_id ?? 0) : 0;
    const cancelAtEnd = sub ? Number(sub.cancel_at_period_end ?? 0) === 1 : false;

    // current subscription info bar
    let infoHtml = '';
    if (isActive && sub) {
      const endsDate = sub.ends_at ? sub.ends_at.slice(0, 10) : '';
      const autoRenewLabel = sub.auto_renew ? t('autorenewOn') : t('autorenewOff');
      const cancelNote = cancelAtEnd ? `<span style="color:var(--danger);"> • ${esc(t('cancelAtEnd'))}</span>` : '';
      const nextNote = nextPlanId
        ? `<div class="txt-sm" style="margin-top:4px;opacity:.8;">${esc(t('nextPlan'))} <b>${esc(plans.find(p=>Number(p.id)===nextPlanId)?.title || nextPlanId)}</b></div>`
        : '';
      infoHtml = `
        <div class="card" style="margin-bottom:16px; padding:14px 16px; border:1px solid var(--primary); border-radius:16px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;">
            <div style="font-weight:800;font-size:14px;">${esc(sub.title || t('planCurrent'))}</div>
            <span style="background:var(--primary);color:#fff;font-size:11px;font-weight:700;padding:3px 10px;border-radius:999px;">${esc(t('planCurrentBadge'))}</span>
          </div>
          <div class="txt-sm" style="opacity:.8;">${esc(t('activeUntil'))} <b>${esc(endsDate)}</b> ${cancelNote}</div>
          <div class="txt-sm" style="opacity:.7;margin-top:2px;">${esc(autoRenewLabel)}</div>
          ${nextNote}
          <div class="txt-sm" style="margin-top:6px;opacity:.7;">${esc(t('balance'))} <b>${esc(fmt(balance))} ₸</b></div>
        </div>`;
    } else {
      infoHtml = `
        <div class="card" style="margin-bottom:16px;padding:12px 16px;border-radius:16px;opacity:.8;">
          <div class="txt-sm">${esc(t('balance'))} <b>${esc(fmt(balance))} ₸</b></div>
        </div>`;
    }

    // plan cards
    const planCards = plans.map((plan, idx) => {
      const pid = Number(plan.id);
      const price = Number(plan.price ?? 0);
      const days = Number(plan.period_days ?? 30);
      const isCurrent = isActive && pid === currentPlanId && !cancelAtEnd;
      const isScheduled = nextPlanId === pid;
      const features = buildPlanFeatures(plan, idx);
      const title = planTitle(plan, idx);
      const desc = planDesc(plan, idx);

      let btnLabel, btnAction, btnStyle = '';
      if (isCurrent) {
        btnLabel = t('planCurrent');
        btnAction = `cancelSub()`;
        btnStyle = 'background:var(--surface-highlight);color:var(--text-sec);border:1px solid var(--border);font-size:12px;';
      } else if (isScheduled) {
        btnLabel = `${t('planScheduled')} ✓`;
        btnAction = '';
        btnStyle = 'background:var(--surface-highlight);color:var(--primary);border:1px solid var(--primary);pointer-events:none;';
      } else {
        btnLabel = isActive ? t('planChangeNext') : t('planActivateBtn');
        btnAction = `choosePlan(${pid}, ${price})`;
        btnStyle = 'background:var(--primary);color:#fff;';
      }

      const cardBorder = isCurrent ? 'border:2px solid var(--primary);' : 'border:1px solid var(--border);';

      return `
        <div class="card sub-plan-card" style="${cardBorder} border-radius:20px; padding:20px; margin-bottom:14px; position:relative;">
          ${isCurrent ? `<div style="position:absolute;top:14px;right:14px;background:var(--primary);color:#fff;font-size:10px;font-weight:800;padding:3px 10px;border-radius:999px;">${esc(t('planCurrentBadge'))}</div>` : ''}
          ${isScheduled ? `<div style="position:absolute;top:14px;right:14px;background:rgba(46,196,182,.15);color:#2EC4B6;font-size:10px;font-weight:800;padding:3px 10px;border-radius:999px;">${esc(t('planScheduled'))}</div>` : ''}
          <div style="font-weight:800;font-size:17px;margin-bottom:4px;">${esc(title)}</div>
          <div class="txt-sm" style="opacity:.7;margin-bottom:10px;">${esc(desc)}</div>
          <div style="font-size:26px;font-weight:900;color:var(--primary);margin-bottom:2px;">${esc(fmt(price))} ₸</div>
          <div class="txt-sm" style="opacity:.6;margin-bottom:14px;">${esc(days)} ${esc(t('periodDays'))} ${esc(t('perPeriod'))}</div>
          <div style="display:flex;flex-direction:column;gap:5px;margin-bottom:16px;">
            ${features.map(f => `<div class="txt-sm" style="opacity:.85;">${esc(f)}</div>`).join('')}
          </div>
          <button class="cta-btn" onclick="${esc(btnAction)}" style="${btnStyle} margin:0; width:100%; justify-content:center;"
            ${!btnAction ? 'disabled' : ''}>
            ${esc(btnLabel)}
          </button>
        </div>`;
    });

    // cancel button (shown if active and not already canceling)
    const cancelBtn = isActive && !cancelAtEnd ? `
      <div style="text-align:center;margin-top:8px;margin-bottom:20px;">
        <button class="txt-sm" onclick="cancelSub()" style="background:none;border:none;color:var(--danger);cursor:pointer;opacity:.8;text-decoration:underline;">
          ${esc(t('cancelSubscription'))}
        </button>
      </div>` : '';

    root.innerHTML = infoHtml + planCards.join('') + cancelBtn;
  }

  // ─────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────
  let _state = null; // cached API response

  async function load() {
    const root = qs('#subPlans');
    if (root) root.innerHTML = `<div class="txt-sm" style="opacity:.75;text-align:center;padding:20px;">${t('loading')}</div>`;
    const errEl = qs('#subErr');
    if (errEl) errEl.style.display = 'none';

    try {
      _state = await apiGet('api/subscription_status.php');
      renderPlans(_state);
      syncAutoRenewToggle();
    } catch (e) {
      if (root) root.innerHTML = '';
      if (errEl) { errEl.textContent = t('errServerError') + ': ' + e.message; errEl.style.display = 'block'; }
    }
  }

  function syncAutoRenewToggle() {
    const toggle = qs('#autoRenewSwitch');
    const desc = qs('#autoRenewDesc');
    if (!toggle || !_state) return;
    const sub = _state.subscription;
    const isOn = sub ? (Number(sub.auto_renew ?? 1) === 1 && Number(sub.cancel_at_period_end ?? 0) === 0) : false;
    toggle.checked = isOn;
    if (desc) desc.textContent = isOn ? t('autorenewOn') : t('autorenewOff');
  }

  window.choosePlan = async function (planId, price) {
    const balance = Number(_state?.me?.balance ?? 0);
    const isActive = !!_state?.subscription?.is_active;
    const confirmMsg = isActive ? t('confirmChange') : t('confirmBuy');

    if (!isActive && balance < price) {
      showToast(`${t('insufficientFunds')} ${fmt(price)} ₸`);
      return;
    }

    if (!confirm(confirmMsg)) return;

    try {
      const result = await apiPost('api/subscription_buy.php', { plan_id: planId });
      if (result?.scheduled) {
        showToast(t('successChange'));
      } else {
        showToast(t('successBuy'));
      }
      await load();
    } catch (e) {
      const msg = e.message === 'insufficient_funds'
        ? `${t('insufficientFunds')} ${fmt(price)} ₸`
        : e.message === 'already_active' ? t('planCurrent')
        : t('errServerError');
      showToast(msg);
    }
  };

  window.cancelSub = async function () {
    if (!confirm(t('confirmCancel'))) return;
    try {
      await apiPost('api/subscription_cancel.php', {});
      showToast(t('successCancel'));
      await load();
    } catch (e) {
      showToast(t('errServerError') + ': ' + e.message);
    }
  };

  // autorenew toggle
  document.addEventListener('DOMContentLoaded', () => {
    const toggle = qs('#autoRenewSwitch');
    const desc = qs('#autoRenewDesc');
    if (toggle) {
      toggle.addEventListener('change', async () => {
        const wantOn = toggle.checked;
        try {
          if (wantOn) {
            // resume: just buy current plan again or use resume endpoint if exists
            await apiPost('api/subscription_resume.php', {});
          } else {
            await apiPost('api/subscription_cancel.php', {});
          }
          if (desc) desc.textContent = wantOn ? t('autorenewOn') : t('autorenewOff');
          showToast(wantOn ? t('autorenewOn') : t('autorenewOff'));
          await load();
        } catch (e) {
          // revert
          toggle.checked = !wantOn;
          showToast(t('errServerError') + ': ' + e.message);
        }
      });
    }

    // apply i18n to static elements
    const i18nEl = qs('#subI18n');
    const lang = i18nEl?.dataset?.lang || getLang();

    const arLabel = qs('.sub-autorenew-label');
    const arDesc = qs('.sub-autorenew-desc');
    if (arLabel) arLabel.textContent = t('autorenewLabel');
    if (arDesc) arDesc.textContent = t('autorenewDesc');

    load();
  });
})();