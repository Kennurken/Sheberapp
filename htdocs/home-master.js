(() => {
  const qs = (sel, root = document) => root.querySelector(sel);
  const qsa = (sel, root = document) => Array.from(root.querySelectorAll(sel));

  const STORAGE = {
    user: "sheber_user",
    theme: "theme",
    lang: "lang",
    activeTab: "sheber_active_tab",
  };

  const I18N = {
    kk: {
      accept: "Қабылдау",
      activeMode: "Белсенді режим",
      addressAfterAccept: "мекен-жай қабылдағаннан кейін ашылады",
      aiPlaceholder: "Сұрағыңызды жазыңыз...",
      aiTitle: "Sheber AI",
      aiWelcomeHtml: "Сәлем! Мен Sheber.kz AI көмекшісімін.<br><br>Клиентпен дау туындады ма әлде бағалау бойынша сұрақ бар ма?",
      all: "Барлығы",
      balance: "Баланс",
      canAcceptOrders: "Сіз қазір тапсырыс қабылдай аласыз",
      chatSub: "Клиенттермен чат",
      chatsEmpty: "Чаттар жоқ",
      chatsLoading: "Чаттар жүктелуде...",
      darkMode: "Түнгі режим",
      distanceLabel: "Қашықтық:",
      heroSub: "Бүгін жұмысқа дайынсыз ба?",
      history: "Тарих",
      home: "Басты бет",
      language: "Тіл",
      loading: "Жүктелуде...",
      messages: "Хабарламалар",
      nearbyOrders: "Жақын маңдағы тапсырыстар",
      newOrders: "Жаңа тапсырыстар",
      noOrders: "Әзірге тапсырыс жоқ",
      orderChatClosed: "Бұл тапсырыс үшін чат жабық",
      orderChatInputPlaceholder: "Хабарлама жазыңыз...",
      ordersFeed: "Тапсырыстар таспасы",
      pageTitle: "Sheber.kz | Мастер кабинеті",
      pePhonePh: '+7 (___) ___-__-__',
      peProfessionPh: 'Сантехник, электрик, тазалаушы...',
      peSaveBtn: 'Сақтау',
      peTitle: 'Профильді өңдеу',
      reviewTitle: 'Клиент туралы пікір',
      services: "Тапсырыстар",
      settings: "Баптаулар",
      settingsSub: "Қосымша параметрлер",
      sidebarVersion: '  MILI-TECH - SHBER.KZ',
      statBonus: "Тапсырыс",
      statOrder: "Табыс",
      statRating: "Рейтинг",
      status: "Статус",
      subscribe: "Оформить",
      subscription: "Подписка",
      subscriptionActiveUntilPrefix: "Действует до: ",
      subscriptionBtnActive: "Продлить / Изменить",
      subscriptionInactiveDesc: "Тапсырыс қабылдау үшін жазылыңыз",
      subscriptionInactiveTitle: "Подписка не активна",
      switchToClient: 'Клиентке өту',
      switchToMaster: 'Мастер болу',
      toastChatOpenFail: "Чат ашылмады",
      toastDefault: "OK",
      toastFinishFail: "Қате: аяқталмады",
      toastFinishedMine: "Тапсырыс аяқталды (сіз жақтан)",
      toastMessageNotSent: "Хабарлама жіберілмеді",
      toastNoNewMessages: "Жаңа хабарламалар жоқ",
      toastOrderAccepted: "Тапсырыс қабылданды",
      toastOrderAcceptFail: "Қате: тапсырыс қабылданбады",
      toastPayHistory: "Төлем тарихы ашылуда...",
      toastRestModeOn: "Демалыс режимі қосылды",
      toastStatusChanged: "Статус ауыстырылды",
      toastSubLoadFail: "Статус жүктелмеді",
      toastSubscriptionRequired: "Подписка керек: тапсырысты қабылдау үшін жазылыңыз",
      toastActiveOrdersLimit: "Лимит: белсенді тапсырыстар саны толды",
      yourAccount: "Сіздің шотыңыз",
      openInMaps: "Картада ашу",
      doneClient: "Клиент",
      doneMaster: "Шебер",
      doneDone: "готово",
      doneWait: "ожидает",
      status_new: "Жаңа",
      status_in_progress: "Жұмыста",
      status_completed: "Аяқталды",
      status_cancelled: "Бас тартылды",
      // BUG FIX: добавлены пропущенные ключи (data-i18n в home-master.php)
      masterReadyQ: "Бүгін жұмысқа дайынсыз ба?",
      chartTitle: "📊 Табыс",
      chartWeek: "Апта",
      chartMonth: "Ай",
    },
    ru: {
      accept: "Принять",
      activeMode: "Активный режим",
      addressAfterAccept: "адрес откроется после принятия",
      aiPlaceholder: "Напишите вопрос...",
      aiTitle: "Sheber AI",
      aiWelcomeHtml: "Привет! Я AI-помощник Sheber.kz.<br><br>Есть спор с клиентом или вопрос по оценке/отзыву?",
      all: "Все",
      balance: "Баланс",
      canAcceptOrders: "Вы можете принимать заказы",
      chatSub: "Чат с клиентами",
      chatsEmpty: "Чатов нет",
      chatsLoading: "Загрузка чатов...",
      darkMode: "Тёмный режим",
      distanceLabel: "Расстояние:",
      heroSub: "Готовы к работе сегодня?",
      history: "История",
      home: "Главная",
      language: "Язык",
      loading: "Загрузка...",
      messages: "Сообщения",
      nearbyOrders: "Заказы рядом",
      newOrders: "Новые заказы",
      noOrders: "Пока нет заказов",
      orderChatClosed: "Чат закрыт для этого заказа",
      orderChatInputPlaceholder: "Напишите сообщение...",
      ordersFeed: "Лента заказов",
      pageTitle: "Sheber.kz | Кабинет мастера",
      profile: "Личный кабинет",
      profileSub: "Рейтинг и отзывы",
      rating: "Рейтинг",
      reviews: "Отзывы",
      searchPlaceholder: "Поиск...",
      services: "Заказы",
      settings: "Настройки",
      settingsSub: "Дополнительные параметры",
      sidebarVersion: '  MILI-TECH - SHBER.KZ',
      statBonus: "Заказы",
      statOrder: "Доход",
      statRating: "Рейтинг",
      status: "Статус",
      subscribe: "Оформить",
      subscription: "Подписка",
      subscriptionActiveUntilPrefix: "Действует до: ",
      subscriptionBtnActive: "Продлить / Изменить",
      subscriptionInactiveDesc: "Чтобы принимать заказы, оформите подписку",
      subscriptionInactiveTitle: "Подписка не активна",
      switchToClient: 'Стать клиентом',
      switchToMaster: 'Стать мастером',
      toastChatOpenFail: "Не удалось открыть чат",
      toastDefault: "OK",
      toastFinishFail: "Не удалось завершить",
      toastFinishedMine: "Заказ завершён (с вашей стороны)",
      toastMessageNotSent: "Сообщение не отправлено",
      toastNoNewMessages: "Нет новых сообщений",
      toastOrderAccepted: "Заказ принят",
      toastOrderAcceptFail: "Ошибка: заказ не принят",
      toastPayHistory: "Открываем историю платежей...",
      toastRestModeOn: "Режим отдыха включён",
      toastStatusChanged: "Статус изменён",
      toastSubLoadFail: "Не удалось загрузить статус",
      toastSubscriptionRequired: "Нужна подписка: чтобы принять заказ, оформите подписку",
      toastActiveOrdersLimit: "Лимит активных заказов исчерпан",
      yourAccount: "Ваш счёт",
      openInMaps: "Открыть на карте",
      doneClient: "Клиент",
      doneMaster: "Мастер",
      doneDone: "готово",
      doneWait: "ожидает",
      months: 'мес.',
      monthsLong: 'месяцев',

      statusNew: 'Новый',
      statusInProgress: 'В работе',
      statusCompleted: 'Завершено',
      status_cancelled: "Отменено",
      // BUG FIX: добавлены пропущенные ключи (data-i18n в home-master.php)
      masterReadyQ: "Готовы работать сегодня?",
      chartTitle: "📊 Заработок",
      chartWeek: "Неделя",
      chartMonth: "Месяц",
    },
  };

  function getLang() {
    const v = (localStorage.getItem(STORAGE.lang) || "kk").toLowerCase();
    return v === "ru" ? "ru" : "kk";
  }

  function t(key) {
    return I18N[getLang()]?.[key] ?? key;
  }

  // simple templating: tr("hello", {name:"A"}) -> replaces {name}
  function tr(key, vars = null) {
    let s = String(t(key));
    if (vars && typeof vars === "object") {
      Object.entries(vars).forEach(([k, v]) => {
        s = s.replaceAll(`{${k}}`, String(v));
      });
    }
    return s;
  }

  function applyTranslations() {
    // text
    qsa("[data-key]").forEach((el) => {
      const key = el.dataset.key;
      const val = I18N[getLang()]?.[key];
      if (val) el.textContent = val;
    });

    // legacy support: data-i18n -> treat as key
    qsa("[data-i18n]").forEach((el) => {
      const key = el.dataset.i18n;
      const val = I18N[getLang()]?.[key];
      if (val) el.textContent = val;
    });

    // html
    qsa("[data-html-key]").forEach((el) => {
      const key = el.dataset.htmlKey;
      const val = I18N[getLang()]?.[key];
      if (val) el.innerHTML = val;
    });

    // placeholder
    qsa("[data-ph-key]").forEach((el) => {
      const key = el.dataset.phKey;
      const val = I18N[getLang()]?.[key];
      if (val) el.placeholder = val;
    });

    // title=""
    qsa("[data-title-key]").forEach((el) => {
      const key = el.dataset.titleKey;
      const val = I18N[getLang()]?.[key];
      if (val) el.title = val;
    });

    // page title
    if (I18N[getLang()]?.pageTitle) document.title = t("pageTitle");
  }

  function showToast(message, timeout = 2200) {
    const toast = qs("#toast");
    if (!toast) return;
    toast.textContent = String(message);
    toast.classList.add("show");
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => toast.classList.remove("show"), timeout);
  }

  function syncThemeToggle() {
    const html = document.documentElement;
    const saved = localStorage.getItem(STORAGE.theme);
    const theme = saved || html.getAttribute("data-theme") || "dark";
    html.setAttribute("data-theme", theme);

    const cb = qs("#themeToggle");
    if (cb) cb.checked = theme === "dark";
  }

  function toggleTheme() {
    const html = document.documentElement;
    const cur = html.getAttribute("data-theme") || "dark";
    const next = cur === "dark" ? "light" : "dark";
    html.setAttribute("data-theme", next);
    localStorage.setItem(STORAGE.theme, next);
    syncThemeToggle();
  }

  function setLanguage(lang) {
    const normalized = (lang || "").toLowerCase() === "ru" ? "ru" : "kk";
    localStorage.setItem(STORAGE.lang, normalized);

    const kkBtn = qs("#lang-kk");
    const ruBtn = qs("#lang-ru");
    if (kkBtn) kkBtn.classList.toggle("active", normalized === "kk");
    if (ruBtn) ruBtn.classList.toggle("active", normalized === "ru");

    applyTranslations();
    // refresh lists to rebuild status labels in correct language
    loadMasterOrders().catch(() => { });
    loadMasterChats().catch(() => { });
    loadMasterReviews().catch(() => { });
    loadSubscriptionStatus().catch(() => { });
    loadUser(); // refresh role/spec label
  }

  function toggleMenu() {
    const sidebar = qs("#sidebar");
    const overlay = qs("#overlay");
    if (sidebar) sidebar.classList.toggle("active");
    if (overlay) overlay.classList.toggle("active");
  }

  function toggleAIChat() {
    const modal = qs("#aiModal");
    if (!modal) return;
    modal.classList.toggle("active");
  }

  function setTab(tabName) {
    const target = String(tabName || "home").toLowerCase();
    qsa(".tab-content").forEach((el) => el.classList.toggle("active", el.id === "tab-" + target));
    qsa(".nav-btn").forEach((el) => el.classList.toggle("active", el.id === "nav-" + target));

    try { localStorage.setItem(STORAGE.activeTab, target); } catch { }

    window.scrollTo(0, 0);

    if (target === "messages") loadMasterChats().catch(() => { });
    if (target === "courses" || target === "home") loadMasterOrders().catch(() => { });
  }

  function primaryAction() {
    showToast(t("toastStatusChanged"));
  }

  function getLocalUser() {
    try { return JSON.parse(localStorage.getItem(STORAGE.user) || "null"); } catch { return null; }
  }

  function loadUser() {
    const u = getLocalUser();
    const lang = getLang();

    const name = u?.name || (lang === "ru" ? "Мастер" : "Шебер");
    const city = u?.city || (lang === "ru" ? "Город" : "Қала");
    const roleLabel = (lang === "ru" ? "Мастер" : "Шебер");
    const spec = u?.profession || u?.spec || roleLabel;

    const initial = String(name).trim().charAt(0).toUpperCase() || "M";
    const avUrl = String(u?.avatar_url || "");
    const avColor = String(u?.avatar_color || "#2EC4B6");

    const $ = (id) => document.getElementById(id);

    const greet = $("greetingH1");
    if (greet) greet.textContent = ` ${name}!`;

    const profileName = $("profileName");
    if (profileName) profileName.textContent = name;

    const sideName = $("sideName");
    if (sideName) sideName.textContent = name;

    const profileRole = $("profileRole");
    if (profileRole) profileRole.textContent = `${spec} • ${city}`;

    const sideRole = $("sideRole");
    if (sideRole) sideRole.textContent = `${spec} • ${city}`;

    const applyAvatar = (el) => {
      if (!el) return;
      el.style.background = avColor;
      if (avUrl) {
        el.style.backgroundImage = `url('${avUrl}')`;
        el.style.backgroundSize = "cover";
        el.style.backgroundPosition = "center";
        el.textContent = "";
      } else {
        el.style.backgroundImage = "";
        el.textContent = initial;
      }
    };

    applyAvatar($("profileAvatar"));
    applyAvatar($("sideAvatar"));
  }

  function logout() {
    localStorage.removeItem(STORAGE.user);
    window.location.href = "logout.php";
  }

  async function switchRole(targetRole) {
    try {
      const u = getLocalUser();

      // In home-master.js, the user is typically already a master, 
      // so switching to 'client' doesn't require a profession prompt.
      // If we ever allow switching to master here for some reason, 
      // we just do it directly. We don't have the profession modal in home-master.php.

      await apiPost("api/role_switch.php", { target_role: targetRole, profession: "" });

      if (u) {
        u.role = targetRole;
        localStorage.setItem(STORAGE.user, JSON.stringify(u));
      }

      if (targetRole === 'client') {
        window.location.href = 'index.php';
      } else {
        window.location.href = 'home-master.php';
      }
    } catch (e) {
      showToast(e.message || "Failed to switch role");
    }
  }

  // =========================
  // API helpers + CSRF
  // =========================
  // BUG FIX: Читаем токен сразу из <meta name="csrf-token"> вместо отдельного запроса.
  let CSRF_TOKEN = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';

  async function ensureCsrf() {
    if (CSRF_TOKEN) return CSRF_TOKEN;
    try {
      const res = await fetch("api/csrf.php", { credentials: "same-origin" });
      const j = await res.json();
      if (res.ok && j && j.ok && j.data && j.data.csrf_token) CSRF_TOKEN = String(j.data.csrf_token);
    } catch { }
    return CSRF_TOKEN;
  }

  async function apiGet(url) {
    const res = await fetch(url, { credentials: "same-origin" });
    let data = null;
    try { data = await res.json(); } catch { }
    if (!res.ok || !data || data.ok === false) {
      const err = (data && data.error) ? data.error : ("http_" + res.status);
      throw new Error(err);
    }
    // compatibility: either {ok:true,data:{...}} or {ok:true,...}
    return (data && typeof data === "object" && "data" in data) ? data.data : data;
  }

  async function apiPost(url, bodyObj) {
    await ensureCsrf();
    const params = new URLSearchParams();
    Object.entries(bodyObj || {}).forEach(([k, v]) => params.append(k, String(v ?? "")));

    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "X-CSRF-Token": CSRF_TOKEN,
      },
      body: params,
      credentials: "same-origin",
    });

    let data = null;
    try { data = await res.json(); } catch { }
    if (!res.ok || !data || data.ok === false) {
      const err = (data && data.error) ? data.error : ("http_" + res.status);
      throw new Error(err);
    }
    return (data && typeof data === "object" && "data" in data) ? data.data : data;
  }

  function esc(s) {
    return String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;" }[c]));
  }

  function fmtMoney(n) {
    const v = Number(n || 0);
    return Math.round(v).toLocaleString("ru-RU");
  }



  // Yandex Maps deep link (no API key required)
  // - If GPS exists: opens map centered on coordinates with a marker
  // - Else if address exists: opens search by address text
  function buildYandexMapsLink(addr, lat, lng) {
    const hasGps = Number.isFinite(lat) && Number.isFinite(lng);
    if (hasGps) {
      const ll = `${lng},${lat}`;           // Yandex expects "lng,lat"
      const pt = `${lng},${lat},pm2rdm`;    // marker
      return `https://yandex.kz/maps/?ll=${encodeURIComponent(ll)}&z=16&pt=${encodeURIComponent(pt)}`;
    }
    const a = String(addr || "").trim();
    return a ? `https://yandex.kz/maps/?text=${encodeURIComponent(a)}` : "";
  }
  function statusLabel(st) {
    const s = String(st || "new");
    const key = "status_" + s;
    return I18N[getLang()]?.[key] || s;
  }

  // =========================
  // Subscription + balance
  // =========================
  async function loadSubscriptionStatus() {
    const tEl = qs("#subTitle");
    const dEl = qs("#subDesc");
    const bEl = qs("#subBtnText");
    if (!tEl || !dEl || !bEl) return;
    const ru = getLang() === 'ru';
    try {
      const s = await apiGet("api/subscription_status.php");
      const balEl = qs("#masterBalance");
      const balVal = Number(s?.me?.balance ?? 0);
      if (balEl) balEl.textContent = `${fmtMoney(balVal)} ₸`;

      const sub = s?.subscription || null;
      const isActive = !!(sub && sub.is_active);
      const onboardingEl = qs("#onboardingBanner");

      if (isActive) {
        if (onboardingEl) onboardingEl.style.display = "none";
        tEl.textContent = String(sub.title || t("subscription"));
        const endsRaw = String(sub.ends_at || "");
        const endsDate = endsRaw ? new Date(endsRaw).toLocaleDateString(ru ? "ru-RU" : "kk-KZ", {day:"numeric",month:"long"}) : "";
        dEl.innerHTML = `✅ ${ru ? "Активна до" : "Белсенді"} <b>${endsDate}</b>`;
        dEl.style.color = "var(--success, #22C55E)";
        const autoRenew = sub.auto_renew && !sub.cancel_at_period_end;
        const renewHint = qs("#subRenewHint");
        if (renewHint) {
          renewHint.textContent = autoRenew
            ? (ru ? "🔄 Автопродление включено" : "🔄 Автоұзарту қосылды")
            : (ru ? "⚠️ Автопродление выключено" : "⚠️ Автоұзарту өшірулі");
          renewHint.style.display = "";
        }
        bEl.textContent = t("subscriptionBtnActive");
      } else {
        if (onboardingEl) { renderOnboarding(onboardingEl, balVal > 0, ru); onboardingEl.style.display = ""; }
        tEl.textContent = ru ? "Подписка не активна" : "Жазылым белсенді емес";
        dEl.innerHTML = ru ? "Без подписки вы <b>не можете</b> принимать заказы" : "Жазылымсыз тапсырыс <b>қабылдай алмайсыз</b>";
        dEl.style.color = "var(--danger, #EF4444)";
        const renewHint = qs("#subRenewHint");
        if (renewHint) renewHint.style.display = "none";
        bEl.textContent = ru ? "🔓 Оформить подписку" : "🔓 Жазылымды рәсімдеу";
      }
    } catch {
      tEl.textContent = t("subscription");
      dEl.textContent = t("toastSubLoadFail");
      bEl.textContent = t("subscribe");
    }
  }

  function renderOnboarding(el, hasBalance, ru) {
    const steps = [
      { done: true,        icon: "✅", ru: "Зарегистрировались",   kk: "Тіркелдіңіз",            desc_ru: "Аккаунт мастера создан",               desc_kk: "Шебер аккаунты жасалды",          action: null },
      { done: hasBalance,  icon: hasBalance ? "✅" : "2️⃣", ru: "Пополните баланс", kk: "Балансты толтырыңыз", desc_ru: hasBalance ? "Баланс пополнен" : "Нажмите «Пополнить баланс» и пополните счёт", desc_kk: hasBalance ? "Баланс толтырылды" : "«Балансты толтыру» басыңыз", action: hasBalance ? null : "payment-master.php" },
      { done: false,       icon: "3️⃣", ru: "Оформите подписку",   kk: "Жазылымды рәсімдеңіз",   desc_ru: "Выберите план и начните принимать заказы", desc_kk: "Тариф таңдап тапсырыс қабылдаңыз", action: "subscription-master.php" },
    ];
    el.innerHTML = `
      <div class="card" style="margin-bottom:16px;padding:16px;border:1.5px solid var(--primary);background:rgba(0,105,255,0.06);">
        <div class="h3" style="margin-bottom:4px;">🚀 ${ru ? "Как начать принимать заказы" : "Тапсырыс қабылдауды бастау"}</div>
        <div class="txt-sm" style="opacity:.7;margin-bottom:14px;">${ru ? "Выполните 3 шага:" : "3 қадамды орындаңыз:"}</div>
        ${steps.map((s, i) => `
          <div style="display:flex;gap:12px;align-items:flex-start;${i < steps.length - 1 ? "margin-bottom:8px;" : ""}">
            <div style="font-size:20px;flex-shrink:0;margin-top:2px;">${s.icon}</div>
            <div style="flex:1;">
              <div style="font-weight:700;font-size:14px;${s.done ? "opacity:.5;text-decoration:line-through;" : ""}">${esc(ru ? s.ru : s.kk)}</div>
              <div class="txt-sm" style="opacity:.65;">${esc(ru ? s.desc_ru : s.desc_kk)}</div>
              ${!s.done && s.action ? `<a href="${s.action}" class="txt-sm" style="color:var(--primary);font-weight:700;text-decoration:none;">→ ${ru ? "Перейти" : "Өту"}</a>` : ""}
            </div>
          </div>
          ${i < steps.length - 1 ? `<div style="margin-left:26px;margin:4px 0 8px;border-left:2px dashed var(--border);height:10px;"></div>` : ""}
        `).join("")}
      </div>`;
  }

  function openSubscription() {
    window.location.href = "subscription-master.php";
  }

  // =========================
  // Master stats + reviews
  // =========================
  async function loadMasterStats() {
    try {
      const s = await apiGet("api/master_stats.php");
      const earnings = Number(s?.earnings_total || 0);
      const completed = Number(s?.completed_orders || 0);
      const avg = Number(s?.avg_rating || 0);

      const p1 = qs("#pProgress");
      if (p1) p1.textContent = fmtMoney(earnings);

      const p2 = qs("#pAccuracy");
      if (p2) p2.textContent = (avg > 0 ? avg.toFixed(1) : "0.0");

      const p3 = qs("#pStreak");
      if (p3) p3.textContent = String(completed);
    } catch { }
  }

  function stars(r) {
    const n = Math.max(0, Math.min(5, Math.round(Number(r) || 0)));
    return "★★★★★".slice(0, n) + "☆☆☆☆☆".slice(0, 5 - n);
  }

  async function loadMasterReviews() {
    const root = qs("#masterReviews");
    if (!root) return;
    root.textContent = t("loading");

    try {
      const payload = await apiGet("api/reviews_list.php?limit=10");
      const arr = Array.isArray(payload) ? payload : (Array.isArray(payload?.reviews) ? payload.reviews : []);

      if (arr.length === 0) {
        root.innerHTML = `<div class="txt-sm" style="opacity:.75;">${getLang() === "ru" ? "Пока нет отзывов" : "Әзірге пікір жоқ"}</div>`;
        return;
      }

      root.innerHTML = arr.map(r => {
        const name = r?.client_name || (getLang() === "ru" ? "Клиент" : "Клиент");
        const rating = Number(r?.rating || 0);
        const body = String(r?.body || "").trim();
        const dt = String(r?.created_at || "").slice(0, 16).replace("T", " ");
        return `
          <div style="padding:10px 0; border-bottom:1px solid var(--border);">
            <div style="display:flex; justify-content:space-between; gap:10px;">
              <div style="font-weight:800;">${esc(name)}</div>
              <div class="txt-sm" style="opacity:.8;">${esc(dt)}</div>
            </div>
            <div class="txt-sm" style="margin:4px 0 6px 0;">${esc(stars(rating))}</div>
            ${body ? `<div class="txt-sm" style="opacity:.85;">${esc(body)}</div>` : ""}
          </div>
        `;
      }).join("");
    } catch {
      root.innerHTML = `<div class="txt-sm" style="opacity:.75;">${getLang() === "ru" ? "Ошибка: отзывы не загружены" : "Қате: пікірлер жүктелмеді"}</div>`;
    }
  }

  // =========================
  // Orders feed (master)
  // =========================
  async function acceptOrder(orderId) {
    try {
      await apiPost("api/orders_accept.php", { order_id: orderId });
      showToast(t("toastOrderAccepted"));
      await loadMasterOrders();
      await loadMasterChats();
    } catch (e) {
      const code = String(e.message || "");
      if (code === "subscription_required") {
        showToast(t("toastSubscriptionRequired"));
        setTimeout(() => { window.location.href = "subscription-master.php"; }, 650);
        return;
      }
      if (code === "active_orders_limit") {
        showToast(t("toastActiveOrdersLimit"));
        return;
      }
      showToast(t("toastOrderAcceptFail"));
    }
  }

  function statusBadgeHtml(st) {
    const ru = getLang() === 'ru';
    const cfg = {
      new:         { color:'#F59E0B', bg:'rgba(245,158,11,0.13)', label: ru ? '🟡 Новый'     : '🟡 Жаңа'          },
      in_progress: { color:'#3B82F6', bg:'rgba(59,130,246,0.13)', label: ru ? '🔵 В работе'  : '🔵 Жұмыста'       },
      completed:   { color:'#22C55E', bg:'rgba(34,197,94,0.13)',  label: ru ? '✅ Завершено' : '✅ Аяқталды'      },
      cancelled:   { color:'#EF4444', bg:'rgba(239,68,68,0.13)',  label: ru ? '❌ Отменено'  : '❌ Бас тартылды'  },
    };
    const c = cfg[st] || { color:'var(--text-sec)', bg:'var(--surface-highlight)', label: st };
    return `<span style="display:inline-flex;align-items:center;padding:4px 10px;border-radius:999px;background:${c.bg};color:${c.color};font-size:12px;font-weight:700;border:1px solid ${c.color}33;">${c.label}</span>`;
  }

  function statusHintHtml(st) {
    const ru = getLang() === 'ru';
    const hints = {
      new:         ru ? 'Нажмите «Принять» чтобы взять этот заказ'   : '«Қабылдау» батырмасын басыңыз',
      in_progress: ru ? 'Заказ принят — свяжитесь с клиентом в чате' : 'Тапсырыс қабылданды — чатта сөйлесіңіз',
      completed:   ru ? 'Заказ завершён'                               : 'Тапсырыс аяқталды',
      cancelled:   ru ? 'Заказ отменён'                                : 'Тапсырыс бас тартылды',
    };
    return hints[st] || '';
  }

  function renderOrderCard(o) {
    const id = Number(o?.id || 0);
    const ru = getLang() === 'ru';
    const title = o?.service_title || (ru ? 'Заказ' : 'Тапсырыс');
    const price = (o?.price !== null && o?.price !== undefined && String(o.price) !== '') ? `${esc(o.price)} ₸` : '';
    const st = String(o?.status || 'new');
    const addr = o?.address || '';
    const client = o?.client_name || 'Клиент';
    const phone = o?.client_phone || o?.guest_phone || '';
    const desc = o?.description || '';

    const addrLine = st === 'new'
      addr ? `<span>📍 ${esc(addr)}</span>` : `<span style="opacity:.45;">${ru?'Адрес не указан':'Мекен-жай жоқ'}</span>`;

    const actionBtn = st === 'new'
      ? `<button class="cta-btn" style="margin-top:12px;background:var(--primary);" onclick="acceptOrder(${id})">⚡ ${esc(ru ? 'Принять заказ' : 'Тапсырысты қабылдау')}</button>`
      : `<button class="cta-btn" style="margin-top:12px;background:var(--surface-highlight);color:var(--text-main);border:1px solid var(--border);" onclick="openOrderChat(${id})">💬 ${esc(ru ? 'Открыть чат' : 'Чатты ашу')}</button>`;

    const hint = statusHintHtml(st);
    return `
      <div class="card" style="padding:16px;margin-bottom:12px;border:1px solid var(--border);">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:10px;margin-bottom:10px;">
          <div style="min-width:0;flex:1;">
            <div class="h3" style="margin-bottom:4px;">${esc(title)}</div>
            <div class="txt-sm" style="opacity:.8;margin-bottom:6px;">👤 ${esc(client)}</div>
            ${phone ? `<div class="txt-sm" style="margin-bottom:4px;">☎ ${esc(phone)}</div>` : ''}
            ${addrLine ? `<div class="txt-sm" style="margin-bottom:4px;">${addrLine}</div>` : ''}
            ${desc ? `<div class="txt-sm" style="opacity:.7;margin-top:4px;">${esc(desc.slice(0,100))}${desc.length>100?'…':''}</div>` : ''}
          </div>
          <div style="text-align:right;flex-shrink:0;">
            ${price ? `<div style="font-weight:900;font-size:18px;color:var(--primary);">${esc(price)}</div>` : ''}
            <div style="margin-top:6px;">${statusBadgeHtml(st)}</div>
          </div>
        </div>
        ${hint ? `<div class="txt-sm" style="opacity:.7;margin-bottom:8px;padding:8px 12px;background:var(--surface-highlight);border-radius:10px;">💡 ${esc(hint)}</div>` : ''}
        ${actionBtn}
      </div>
    `;
  }


  function renderOrderRow(o) {
    const id = Number(o?.id || 0);
    const ru = getLang() === 'ru';
    const title = o?.service_title || (ru ? 'Заказ' : 'Тапсырыс');
    const price = (o?.price !== null && o?.price !== undefined && String(o.price) !== '') ? `${esc(o.price)} ₸` : '';
    const st = String(o?.status || 'new');
    const addr = o?.address || '';

    const meta = st === 'new'
      addr ? `📍 ${esc(addr)}` : `<span style="opacity:.45;">${ru?'Адрес не указан':'Мекен-жай жоқ'}</span>`;

    return `
      <div class="list-item" onclick="openOrderChat(${id})" style="gap:12px;align-items:center;">
        <div style="flex:1;min-width:0;">
          <div class="h3" style="font-size:14px;margin-bottom:3px;">${esc(title)}</div>
          <div class="txt-sm" style="opacity:.7;">${meta}${price ? ` • <b style="color:var(--primary);">${esc(price)}</b>` : ''}</div>
        </div>
        <div style="flex-shrink:0;">${statusBadgeHtml(st)}</div>
      </div>
    `;
  }

  async function loadMasterOrders() {
    const homeRoot = qs("#masterOrdersHome");
    const homePh = qs("#masterOrdersHomePlaceholder");
    const coursesRoot = qs("#masterOrdersCourses");
    const coursesPh = qs("#masterOrdersCoursesPlaceholder");

    if (homeRoot) homeRoot.innerHTML = "";
    if (coursesRoot) coursesRoot.innerHTML = "";

    try {
      const orders = await apiGet("api/orders_feed.php");
      const arr = Array.isArray(orders) ? orders : [];

      const top = arr.slice(0, 3);
      if (homeRoot) {
        homeRoot.innerHTML = top.length === 0
          ? `<div class="txt-sm" style="opacity:.75; text-align:center; padding:10px 4px;">${esc(t("noOrders"))}</div>`
          : top.map(renderOrderRow).join("");
      }

      if (coursesRoot) {
        coursesRoot.innerHTML = arr.length === 0
          ? `<div class="txt-sm" style="opacity:.75; text-align:center; padding:10px 4px;">${esc(t("noOrders"))}</div>`
          : arr.map(renderOrderCard).join("");
      }

      if (homePh) homePh.style.display = "none";
      if (coursesPh) coursesPh.style.display = "none";
    } catch {
      // leave placeholders
    }
  }

  // =========================
  // Chats per order
  // =========================
  const CHAT_STATE = {
    currentOrderId: 0,
    lastMsgId: 0,
    pollTimer: null,
    currentOrder: null,
  };

  const MAP_STATE = {
    map: null,
    marker: null,
    lastKey: "",
  };

  function renderOrderInfo(order) {
    const txt = qs("#orderInfoText");
    const mapWrap = qs("#orderMapWrap");
    const mapHint = qs("#orderMapHint");
    if (!txt) return;

    const st = String(order?.status || "new");
    const price = (order?.price !== null && order?.price !== undefined && String(order.price) !== "") ? `${esc(order.price)} ₸` : "";
    const addr = order?.address ? String(order.address) : "";
    const lat = (order?.client_lat !== null && order?.client_lat !== undefined) ? Number(order.client_lat) : NaN;
    const lng = (order?.client_lng !== null && order?.client_lng !== undefined) ? Number(order.client_lng) : NaN;

    const clientDone = Number(order?.client_done || 0) === 1;
    const masterDone = Number(order?.master_done || 0) === 1;

    const doneLine = `${t("doneClient")}: ${clientDone ? t("doneDone") : t("doneWait")} • ${t("doneMaster")}: ${masterDone ? t("doneDone") : t("doneWait")}`;

    if (st === "new") {
      txt.innerHTML =
        `<b>${esc(order?.service_title || (getLang() === "ru" ? "Заказ" : "Тапсырыс"))}</b>${price ? ` • ${esc(price)}` : ""}<br>` +
        `📍 <b>${addr ? esc(addr) : (getLang()==="ru"?"Адрес не указан":"Мекен-жай жоқ")}</b><br>` +
        `<span class="txt-sm" style="opacity:.75;">${esc(doneLine)}</span>`;
      if (mapWrap) mapWrap.style.display = "none";
      return;
    }

    const mapLink = buildYandexMapsLink(addr, lat, lng);
    txt.innerHTML =
      `<b>${esc(order?.service_title || (getLang() === "ru" ? "Заказ" : "Тапсырыс"))}</b>${price ? ` • ${esc(price)}` : ""}<br>` +
      `${addr ? `${esc(t("addressLabel"))} <b>${esc(addr)}</b>` : `${esc(t("addressLabel"))} —`}<br>` +
      `<span class="txt-sm" style="opacity:.75;">${esc(doneLine)}</span>` +
      `${mapLink ? `<br><a href="${mapLink}" target="_blank" style="color:var(--primary); font-weight:700; text-decoration:none;">${esc(t("openInMaps"))}</a>` : ""}`;

    if (mapWrap) {
      if (Number.isFinite(lat) && Number.isFinite(lng) && window.L) {
        mapWrap.style.display = "block";
        if (mapHint) mapHint.textContent = `GPS: ${lat.toFixed(5)}, ${lng.toFixed(5)}`;
        initOrderMap(lat, lng);
      } else {
        mapWrap.style.display = "none";
      }
    }
  }

  function initOrderMap(lat, lng) {
    const el = qs("#orderMap");
    if (!el || !window.L) return;

    const key = `${lat},${lng}`;
    if (MAP_STATE.map && MAP_STATE.lastKey === key) {
      try { MAP_STATE.map.invalidateSize(); } catch { }
      return;
    }
    MAP_STATE.lastKey = key;

    if (MAP_STATE.map) {
      try { MAP_STATE.map.remove(); } catch { }
      MAP_STATE.map = null;
      MAP_STATE.marker = null;
    }
    el.innerHTML = "";

    const map = L.map(el, { zoomControl: true }).setView([lat, lng], 16);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "&copy; OpenStreetMap",
    }).addTo(map);
    const marker = L.marker([lat, lng]).addTo(map);

    MAP_STATE.map = map;
    MAP_STATE.marker = marker;

    setTimeout(() => { try { map.invalidateSize(); } catch { } }, 60);
  }

  function toggleOrderChat(forceOpen) {
    const modal = qs("#orderChatModal");
    if (!modal) return;
    if (forceOpen === true) modal.classList.add("active");
    else if (forceOpen === false) modal.classList.remove("active");
    else modal.classList.toggle("active");
  }

  function closeOrderChat() {
    toggleOrderChat(false);
    if (CHAT_STATE.pollTimer) {
      clearInterval(CHAT_STATE.pollTimer);
      CHAT_STATE.pollTimer = null;
    }
    CHAT_STATE.currentOrderId = 0;
    CHAT_STATE.currentOrder = null;
    CHAT_STATE.lastMsgId = 0;
    const cont = qs("#orderChatContainer");
    if (cont) cont.innerHTML = "";
  }

  async function openOrderChat(orderId) {
    const oid = Number(orderId || 0);
    if (oid <= 0) return;

    CHAT_STATE.currentOrderId = oid;
    CHAT_STATE.lastMsgId = 0;

    const cont = qs("#orderChatContainer");
    if (cont) cont.innerHTML = "";

    toggleOrderChat(true);

    try {
      const order = await apiGet("api/order_get.php?order_id=" + encodeURIComponent(String(oid)));
      CHAT_STATE.currentOrder = order;

      const title = order?.service_title || "Чат";
      const otherName = order?.client_name || (getLang() === "ru" ? "Клиент" : "Клиент");
      const st = String(order?.status || "new");

      const hTitle = qs("#orderChatTitle");
      const hSub = qs("#orderChatSub");
      if (hTitle) hTitle.textContent = title;
      if (hSub) hSub.innerHTML = `${esc(otherName)} • <span class="status-text st-${esc(st)}">${esc(statusLabel(st))}</span>`;

      const accBtn = qs("#orderAcceptBtn");
      if (accBtn) accBtn.style.display = (st === "new") ? "inline-flex" : "none";

      const finBtn = qs("#orderFinishBtn");
      const masterDone = Number(order?.master_done || 0) === 1;
      if (finBtn) finBtn.style.display = (st === "in_progress" && !masterDone) ? "inline-flex" : "none";

      renderOrderInfo(order);
      await fetchOrderMessages(true);

      if (CHAT_STATE.pollTimer) clearInterval(CHAT_STATE.pollTimer);
      CHAT_STATE.pollTimer = setInterval(() => {
        fetchOrderMessages(false).catch(() => { });
      }, 2000);

      const inp = qs("#orderChatInput");
      const sendBtn = qs("#orderSendBtn");
      const chatClosed = (st === "completed" || st === "cancelled");
      if (inp) {
        inp.disabled = chatClosed;
        inp.placeholder = chatClosed ? t("orderChatClosed") : t("orderChatInputPlaceholder");
        inp.onkeydown = (e) => {
          if (e.key === "Enter") {
            e.preventDefault();
            sendOrderMessage();
          }
        };
        if (!chatClosed) inp.focus();
      }
      if (sendBtn) sendBtn.disabled = chatClosed;
    } catch {
      showToast(t("toastChatOpenFail"));
      closeOrderChat();
    }
  }

  async function finishCurrentOrder() {
    const oid = CHAT_STATE.currentOrderId;
    if (!oid) return;
    try {
      await apiPost("api/order_finish.php", { order_id: oid });
      showToast(t("toastFinishedMine"));
      await openOrderChat(oid);
      await loadMasterOrders();
      await loadMasterChats();
      await loadMasterStats();
    } catch {
      showToast(t("toastFinishFail"));
    }
  }

  async function fetchOrderMessages(scrollToEnd) {
    const oid = CHAT_STATE.currentOrderId;
    if (!oid) return;

    const url = "api/messages_list.php?order_id=" + encodeURIComponent(String(oid)) +
      "&after_id=" + encodeURIComponent(String(CHAT_STATE.lastMsgId || 0));
    const data = await apiGet(url);

    const me = Number(data?.me || 0);
    const msgs = Array.isArray(data?.messages) ? data.messages : [];
    if (msgs.length === 0) return;

    const cont = qs("#orderChatContainer");
    if (!cont) return;

    msgs.forEach((m) => {
      const id = Number(m?.id || 0);
      if (id > CHAT_STATE.lastMsgId) CHAT_STATE.lastMsgId = id;

      const sender = Number(m?.sender_id || 0);
      const body = String(m?.body || "");

      const div = document.createElement("div");
      div.className = `chat-bubble ${sender === me ? "chat-user" : "chat-ai"}`;
      div.textContent = body;
      cont.appendChild(div);
    });

    if (scrollToEnd) cont.scrollTop = cont.scrollHeight;
  }

  async function sendOrderMessage() {
    const st = String(CHAT_STATE.currentOrder?.status || "new");
    if (st === "completed" || st === "cancelled") {
      showToast(t("orderChatClosed"));
      return;
    }

    const inp = qs("#orderChatInput");
    const text = String(inp?.value || "").trim();
    if (!text) return;

    const oid = CHAT_STATE.currentOrderId;
    if (!oid) return;

    if (inp) inp.value = "";

    try {
      await apiPost("api/messages_send.php", { order_id: oid, body: text });
      await fetchOrderMessages(true);
      await loadMasterChats();
    } catch {
      showToast(t("toastMessageNotSent"));
    }
  }

  async function acceptCurrentOrder() {
    const oid = CHAT_STATE.currentOrderId;
    if (!oid) return;

    try {
      await apiPost("api/orders_accept.php", { order_id: oid });
      showToast(t("toastOrderAccepted"));

      await openOrderChat(oid);
      await loadMasterOrders();
      await loadMasterChats();
    } catch (e) {
      const code = String(e.message || "");
      if (code === "subscription_required") {
        showToast(t("toastSubscriptionRequired"));
        setTimeout(() => { window.location.href = "subscription-master.php"; }, 650);
        return;
      }
      if (code === "active_orders_limit") {
        showToast(t("toastActiveOrdersLimit"));
        return;
      }
      showToast(t("toastOrderAcceptFail"));
    }
  }

  function timeHHMM(ts) {
    if (!ts) return "";
    const d = new Date(String(ts).replace(" ", "T"));
    if (Number.isNaN(d.getTime())) return "";
    const hh = String(d.getHours()).padStart(2, "0");
    const mm = String(d.getMinutes()).padStart(2, "0");
    return `${hh}:${mm}`;
  }

  function renderChatRow(o) {
    const id = Number(o?.id || 0);
    const ru = getLang() === 'ru';
    const client = o?.client_name || 'Клиент';
    const phone = o?.client_phone || o?.guest_phone || '';
    const clientAvatarUrl = String(o?.client_avatar_url || '');
    const clientAvatarColor = String(o?.client_avatar_color || '#2a2a2a');
    const title = o?.service_title || (ru ? 'Заказ' : 'Тапсырыс');
    const last = o?.last_message ? String(o.last_message) : '';
    const tm = timeHHMM(o?.last_message_at || o?.updated_at || o?.created_at);
    const st = String(o?.status || 'new');
    const price = o?.price ? `${esc(o.price)} ₸` : '';
    const preview = last || (o?.address ? String(o.address) : '');
    const stCfg = {
      new:         { color:'#F59E0B', label: ru ? 'Новый'    : 'Жаңа'          },
      in_progress: { color:'#3B82F6', label: ru ? 'В работе' : 'Жұмыста'       },
      completed:   { color:'#22C55E', label: ru ? 'Завершено': 'Аяқталды'      },
      cancelled:   { color:'#EF4444', label: ru ? 'Отменено' : 'Бас тартылды'  },
    };
    const sc = stCfg[st] || { color:'var(--text-sec)', label: st };
    const avatarStyle = clientAvatarUrl
      ? `background-image:url('${esc(clientAvatarUrl)}');background-size:cover;background-position:center;background-color:${esc(clientAvatarColor)};`
      : `background-image:url('https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(client)}');background-color:${esc(clientAvatarColor)};`;
    return `
      <div class="msg-item" onclick="openOrderChat(${id})" style="align-items:center;">
        <div class="msg-av" style="${avatarStyle}"></div>
        <div class="msg-content" style="flex:1;min-width:0;">
          <div class="msg-top">
            <div class="msg-name" style="font-weight:700;">${esc(client)}</div>
            <div class="msg-time">${esc(tm)}</div>
          </div>
          <div class="txt-sm" style="opacity:.8;margin-bottom:3px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
            📋 ${esc(title)}${price ? ` • <b>${esc(price)}</b>` : ''}
          </div>
          <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">
            <div class="msg-text" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;flex:1;opacity:.7;">${esc(preview || sc.label)}</div>
            <span style="flex-shrink:0;padding:3px 8px;border-radius:999px;font-size:11px;font-weight:700;color:${sc.color};background:${sc.color}18;border:1px solid ${sc.color}33;">${sc.label}</span>
          </div>
        </div>
      </div>
    `;
  }

  async function loadMasterChats() {
    const root = qs("#masterChats");
    const ph = qs("#masterChatsPlaceholder");
    if (root) root.innerHTML = "";

    try {
      const orders = await apiGet("api/orders_feed.php");
      const arr = Array.isArray(orders) ? orders : [];
      if (!root) return;

      if (arr.length === 0) {
        root.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:10px 4px;">${esc(t("chatsEmpty"))}</div>`;
      } else {
        root.innerHTML = arr.map(renderChatRow).join("");
      }
      if (ph) ph.style.display = "none";
    } catch {
      if (root) root.innerHTML = `<div class="txt-sm" style="opacity:.75; text-align:center; padding:10px 4px;">${getLang() === "ru" ? "Ошибка: чаты не загружены" : "Қате: чаттар жүктелмеді"}</div>`;
    }
  }

  // =========================
  // AI chat (Gemini)
  // =========================
  // NOTE: Keeping user's existing approach. In production, do this server-side.
  const API_KEY = "AIzaSyAD9hW22ophF6fCIOa_7CPAiM6fIap-ye8";
  const MODEL = "gemini-2.5-flash";
  const ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}`;

  let chatHistory = [
    { role: "model", parts: [{ text: "Сәлем! Шебер іздеп жатырсыз ба? Қандай көмек керек?" }] }
  ];

  function appendBubble(who, text) {
    const container = qs("#chatContainer");
    if (!container) return;
    const div = document.createElement("div");
    div.className = `chat-bubble ${who === "user" ? "chat-user" : "chat-ai"}`;
    div.textContent = String(text || "");
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
  }

  async function sendMessage() {
    const input = qs("#chatInput");
    if (!input) return;
    const text = String(input.value || "").trim();
    if (!text) return;

    appendBubble("user", text);
    input.value = "";

    try {
      const response = await fetch(ENDPOINT, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [...chatHistory, { role: "user", parts: [{ text }] }]
        })
      });

      const data = await response.json().catch(() => null);
      const aiText = data?.candidates?.[0]?.content?.parts?.map(p => p.text).join("") ||
        (getLang() === "ru" ? "Извините, сейчас не могу ответить." : "Кешіріңіз, қазір жауап бере алмаймын.");

      chatHistory = [...chatHistory, { role: "user", parts: [{ text }] }, { role: "model", parts: [{ text: aiText }] }];
      appendBubble("ai", aiText);
    } catch (err) {
      console.error(err);
      appendBubble("ai", getLang() === "ru" ? "Ошибка сети." : "Желі қатесі.");
    }
  }


  // =========================
  // Profile edit (master)
  // =========================
  function openProfileEdit() {
    const modal = qs("#profileEditModal");
    const overlay = qs("#profileEditOverlay");
    if (modal) modal.classList.add("active");
    if (overlay) overlay.classList.add("active");

    // Prefill from localStorage + existing DOM
    const u = getLocalUser() || {};
    const setVal = (id, v) => { const el = qs(id); if (el) el.value = (v ?? ""); };

    setVal("#peName", u.name || qs("#profileName")?.textContent || "");
    setVal("#peCity", u.city || "");
    setVal("#peProfession", u.profession || "");
    setVal("#peExperience", String(u.experience ?? 0));
    setVal("#pePhone", u.phone || "");
    setVal("#peBio", u.bio || "");
    setVal("#peAvatarColor", u.avatar_color || "#2EC4B6");

    pickAvatarColor(String(u.avatar_color || "#2EC4B6"));

    const bio = qs("#peBio");
    const cnt = qs("#peBioCount");
    if (bio && cnt) cnt.textContent = bio.value.length + "/500";
    if (bio && cnt) {
      bio.oninput = () => { cnt.textContent = bio.value.length + "/500"; };
    }
  }

  function closeProfileEdit() {
    const modal = qs("#profileEditModal");
    const overlay = qs("#profileEditOverlay");
    if (modal) modal.classList.remove("active");
    if (overlay) overlay.classList.remove("active");
  }

  function pickAvatarColor(color) {
    const inp = qs("#peAvatarColor");
    if (inp) inp.value = color;

    const prev = qs("#avPreview");
    if (prev) prev.style.background = color;

    qsa(".av-dot").forEach((d) => {
      d.classList.toggle("selected", d.dataset.color === color);
    });
  }

  async function uploadAvatarFile(input) {
    if (!input || !input.files || input.files.length === 0) return;
    const file = input.files[0];

    if (file.size > 5 * 1024 * 1024) {
      showToast(getLang() === "ru" ? "Файл слишком большой (макс 5мб)" : "Файл тым үлкен (макс 5мб)");
      input.value = "";
      return;
    }

    const formData = new FormData();
    formData.append("avatar", file);

    try {
      await ensureCsrf();
      const response = await fetch("api/avatar_upload.php", {
        method: "POST",
        headers: { "X-CSRF-Token": CSRF_TOKEN },
        body: formData,
        credentials: "same-origin",
      });
      const res = await response.json().catch(() => null);

      if (response.ok && res && res.ok) {
        showToast(getLang() === "ru" ? "Аватар обновлён!" : "Аватар жаңартылды!");
        const data = res.data || {};
        const avatarUrl = String(data.avatar_url || data.avatarUrl || "");

        const u = getLocalUser() || {};
        const next = { ...u, avatar_url: avatarUrl };
        localStorage.setItem(STORAGE.user, JSON.stringify(next));

        // update DOM
        loadUser();

        // update modal preview
        const prev = qs("#avPreview");
        if (prev && avatarUrl) {
          prev.style.backgroundImage = `url('${avatarUrl}')`;
          prev.style.backgroundSize = "cover";
          prev.style.backgroundPosition = "center";
          const tEl = qs("#avPreviewText");
          if (tEl) tEl.textContent = "";
        }
      } else {
        showToast((getLang() === "ru" ? "Ошибка: " : "Қате: ") + (res?.error || ("http_" + response.status)));
      }
    } catch (e) {
      console.error(e);
      showToast(getLang() === "ru" ? "Ошибка: не удалось загрузить аватар" : "Қате: Аватар жүктелмеді");
    }

    input.value = "";
  }

  async function profileEditSubmit(ev) {
    ev.preventDefault();

    const btn = qs("#profileSaveBtn");
    if (btn) { btn.disabled = true; btn.style.opacity = "0.7"; }

    const payload = {
      name: String(qs("#peName")?.value || "").trim(),
      city: String(qs("#peCity")?.value || "").trim(),
      profession: String(qs("#peProfession")?.value || "").trim(),
      experience: String(parseInt(String(qs("#peExperience")?.value || "0"), 10) || 0),
      phone: String(qs("#pePhone")?.value || "").trim(),
      bio: String(qs("#peBio")?.value || "").trim(),
      avatar_color: String(qs("#peAvatarColor")?.value || "#2EC4B6"),
    };

    if (!payload.name) {
      showToast(getLang() === "ru" ? "Введите имя" : "Атыңызды енгізіңіз");
      if (btn) { btn.disabled = false; btn.style.opacity = ""; }
      return;
    }

    try {
      const data = await apiPost("api/profile_update.php", payload);

      const u = getLocalUser() || {};
      const next = {
        ...u,
        name: data?.name || payload.name,
        city: data?.city || payload.city,
        profession: data?.profession || payload.profession,
        experience: data?.experience ?? payload.experience,
        phone: data?.phone || payload.phone,
        bio: data?.bio || payload.bio,
        avatar_color: data?.avatar_color || payload.avatar_color,
        avatar_url: data?.avatar_url || u.avatar_url || "",
      };

      localStorage.setItem(STORAGE.user, JSON.stringify(next));
      loadUser();

      // profession line in profile tab (if exists)
      const profEl = qs("#profileProfession");
      if (profEl) {
        if (next.profession) {
          profEl.style.display = "";
          const ex = parseInt(String(next.experience || "0"), 10) || 0;
          profEl.textContent = next.profession + (ex > 0 ? (" • " + ex + (getLang() === "ru" ? " лет" : " жыл")) : "");
        } else {
          profEl.style.display = "none";
          profEl.textContent = "";
        }
      }

      closeProfileEdit();
      showToast(getLang() === "ru" ? "✅ Профиль сохранён" : "✅ Профиль сақталды");
    } catch (e) {
      showToast(getLang() === "ru" ? "Не удалось сохранить" : "Сақталмады");
    } finally {
      if (btn) { btn.disabled = false; btn.style.opacity = ""; }
    }
  }

  // =========================
  // INIT
  // =========================
  document.addEventListener("DOMContentLoaded", () => {
    syncThemeToggle();

    setLanguage(getLang());
    applyTranslations();

    // ensure AI welcome html filled if present
    const aiWelcome = qs('[data-html-key="aiWelcomeHtml"]');
    if (aiWelcome) aiWelcome.innerHTML = t("aiWelcomeHtml");

    // show loading placeholders
    const chatsPh = qs("#masterChatsPlaceholder");
    if (chatsPh) {
      // keep original text but translate if we can
      chatsPh.textContent = t("chatsLoading");
    }

    // bind search placeholder
    const courseSearch = qs("#courseSearch");
    if (courseSearch) {
      courseSearch.addEventListener("input", () => {
        // optional: could filter already rendered orders - keep simple
      });
    }

    const chatInput = qs("#chatInput");
    if (chatInput) {
      chatInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          e.preventDefault();
          sendMessage();
        }
      });
    }

    loadUser();

    loadSubscriptionStatus().catch(() => { });
    loadMasterStats().catch(() => { });
    loadMasterOrders().catch(() => { });
    loadMasterChats().catch(() => { });
    loadMasterReviews().catch(() => { });

    clearInterval(window.__ordersPoll);
    window.__ordersPoll = setInterval(() => loadMasterOrders().catch(() => {}), 8000);

    clearInterval(window.__statsPoll);
    window.__statsPoll = setInterval(() => loadMasterStats().catch(() => {}), 20000);

    clearInterval(window.__pushPoll);
    window.__pushPoll = setInterval(() => pollPushNotifications(), 10000);

    // New features init
    initPush();
    loadEarningsChart('week').catch(() => {});
    loadPortfolio().catch(() => {});

    const savedTab = localStorage.getItem(STORAGE.activeTab) || "home";
    setTab(savedTab);
  });

  // =========================
  // expose globals for inline onclick
  // =========================
  window.t = t;
  window.tr = tr;

  window.showToast = showToast;
  window.toggleTheme = toggleTheme;
  window.setLanguage = setLanguage;
  window.toggleMenu = toggleMenu;
  window.toggleAIChat = toggleAIChat;
  window.setTab = setTab;
  window.primaryAction = primaryAction;
  window.logout = logout;
  window.switchRole = switchRole;

  window.openSubscription = openSubscription;

  window.openProfileEdit = openProfileEdit;
  window.closeProfileEdit = closeProfileEdit;
  window.pickAvatarColor = pickAvatarColor;
  window.uploadAvatarFile = uploadAvatarFile;
  window.profileEditSubmit = profileEditSubmit;

  window.loadMasterOrders = loadMasterOrders;
  window.loadMasterChats = loadMasterChats;
  window.loadMasterStats = loadMasterStats;
  window.loadMasterReviews = loadMasterReviews;

  window.acceptOrder = acceptOrder;

  window.openOrderChat = openOrderChat;
  window.closeOrderChat = closeOrderChat;
  window.sendOrderMessage = sendOrderMessage;
  window.acceptCurrentOrder = acceptCurrentOrder;
  window.finishCurrentOrder = finishCurrentOrder;

  window.sendMessage = sendMessage;

  // ═══════════════════════════════════════════════════════
  // 🟢 ONLINE / OFFLINE
  // ═══════════════════════════════════════════════════════
  let _isOnline = false;
  function renderOnlineToggle(isOnline) {
    _isOnline = !!isOnline;
    const btn = qs('#onlineToggleBtn'), dot = qs('#onlineDot'), lbl = qs('#onlineLabel');
    if (!btn) return;
    if (_isOnline) {
      btn.style.background='rgba(46,196,182,.15)'; btn.style.borderColor='#2EC4B6';
      if (dot){dot.style.background='#2EC4B6';dot.style.boxShadow='0 0 0 3px rgba(46,196,182,.25)';}
      if (lbl) lbl.textContent = getLang()==='ru'?'Онлайн':'Белсенді';
    } else {
      btn.style.background='var(--surface-highlight)'; btn.style.borderColor='var(--border)';
      if (dot){dot.style.background='var(--text-sec)';dot.style.boxShadow='none';}
      if (lbl) lbl.textContent = getLang()==='ru'?'Не в сети':'Офлайн';
    }
  }
  async function toggleOnlineStatus() {
    try {
      const res = await apiPost('api/master_status_toggle.php', {});
      renderOnlineToggle(Number(res?.is_online ?? res?.data?.is_online) === 1);
      showToast(_isOnline ? (getLang()==='ru'?'Онлайн':'Белсенді') : (getLang()==='ru'?'Не в сети':'Офлайн'));
    } catch(e) { showToast(e.message); }
  }

  // ═══════════════════════════════════════════════════════
  // 📊 EARNINGS CHART
  // ═══════════════════════════════════════════════════════
  async function loadEarningsChart(period) {
    const root = qs('#earningsChart'), totEl = qs('#chartTotalEarnings'), ordEl = qs('#chartTotalOrders');
    if (!root) return;
    ['week','month'].forEach(p => {
      const b = qs('#chartBtn-'+p); if(!b) return;
      if(p===period){b.style.background='var(--primary)';b.style.color='#fff';b.style.borderColor='var(--primary)';}
      else{b.style.background='var(--surface-highlight)';b.style.color='var(--text-sec)';b.style.borderColor='var(--border)';}
    });
    root.innerHTML=`<div style="text-align:center;padding:20px;opacity:.5;font-size:13px;">Жүктелуде...</div>`;
    try {
      const data = await apiGet('api/master_earnings_chart.php?period='+period);
      if(totEl) totEl.textContent = fmtMoney(data.total_earnings)+' ₸';
      if(ordEl) ordEl.textContent = data.total_orders+' '+(getLang()==='ru'?'выполнено':'аяқталды');
      const chart = data.chart||[];
      if(!chart.length){root.innerHTML=`<div style="text-align:center;padding:20px;opacity:.4;font-size:13px;">${getLang()==='ru'?'Нет данных':'Деректер жоқ'}</div>`;return;}
      const maxE = Math.max(...chart.map(d=>d.earnings),1);
      const dayNames = getLang()==='ru'?['Пн','Вт','Ср','Чт','Пт','Сб','Вс']:['Дс','Сс','Ср','Бс','Жм','Сн','Жк'];
      root.innerHTML=`<div style="display:flex;gap:4px;align-items:flex-end;padding:4px 0;">`+
        chart.map(d=>{
          const pct=Math.max(Math.round((d.earnings/maxE)*100),d.earnings>0?5:0);
          const dt=new Date(d.day+'T00:00:00');
          const lbl=period==='week'?dayNames[dt.getDay()===0?6:dt.getDay()-1]:`${dt.getDate()}.${String(dt.getMonth()+1).padStart(2,'0')}`;
          return `<div style="display:flex;flex-direction:column;align-items:center;flex:1;gap:4px;">
            <div style="font-size:9px;opacity:.6;color:var(--primary);font-weight:700;">${d.earnings>0?fmtMoney(d.earnings):''}</div>
            <div style="width:100%;background:var(--surface-highlight);border-radius:6px;height:72px;display:flex;align-items:flex-end;">
              <div style="width:100%;height:${pct}%;background:linear-gradient(180deg,#0069ff,#2EC4B6);border-radius:6px 6px 0 0;transition:height .4s;min-height:${pct>0?3:0}px;"></div>
            </div>
            <div style="font-size:10px;opacity:.65;font-weight:600;">${esc(lbl)}</div>
          </div>`;
        }).join('')+`</div>`;
    } catch { root.innerHTML=`<div style="text-align:center;padding:20px;opacity:.4;">—</div>`; }
  }

  // ═══════════════════════════════════════════════════════
  // 🏆 MASTER LEVEL
  // ═══════════════════════════════════════════════════════
  const LEVELS=[
    {id:'newbie',min:0,max:5,emoji:'🌱',color:'#8B5CF6'},
    {id:'rising',min:5,max:15,emoji:'⚡',color:'#F97316'},
    {id:'pro',min:15,max:30,emoji:'🔥',color:'#EF4444'},
    {id:'expert',min:30,max:60,emoji:'💎',color:'#0EA5E9'},
    {id:'legend',min:60,max:Infinity,emoji:'👑',color:'#F59E0B'},
  ];
  const LEVEL_NAMES={
    ru:{newbie:'Новичок',rising:'Развивающийся',pro:'Профессионал',expert:'Эксперт',legend:'Легенда'},
    kk:{newbie:'Жаңадан бастаушы',rising:'Дамып келе жатқан',pro:'Кәсіби',expert:'Сарапшы',legend:'Аңыз'},
  };
  function renderMasterLevel(completed, avgRating) {
    const root = qs('#masterLevelCard');
    if (!root) return;
    const n = Number(completed || 0);
    const avg = Number(avgRating || 0);
    const lang = getLang();
    const ru = lang === 'ru';
    const lv = LEVELS.slice().reverse().find(l => n >= l.min) || LEVELS[0];
    const nextLv = LEVELS[LEVELS.findIndex(l => l.id === lv.id) + 1] || null;
    const isLegend = lv.id === 'legend';
    const pct = isLegend ? 100 : Math.min(100, Math.round(((n - lv.min) / (lv.max - lv.min)) * 100));
    const remaining = isLegend ? 0 : lv.max - n;
    const lvName = LEVEL_NAMES[lang][lv.id];
    const nextName = nextLv ? LEVEL_NAMES[lang][nextLv.id] : null;

    const LEVEL_PERKS = {
      ru: { newbie:['Доступ к новым заказам','Базовый профиль'], rising:['Приоритет в выдаче','Метка «Набирает рейтинг»'], pro:['Топ-3 в поиске','Метка «Профессионал»','Скидка 10% на подписку'], expert:['Топ выдача','Метка «Эксперт»','Скидка 20% на подписку'], legend:['🥇 Место #1 в поиске','Метка «Легенда»','Скидка 30% на подписку'] },
      kk: { newbie:['Жаңа тапсырыстарға қол жеткізу','Базалық профиль'], rising:['Іздеуде артықшылық','«Рейтинг жинауда» белгісі'], pro:['Іздеуде ТОП-3','«Кәсіби» белгісі','Жазылымға 10% жеңілдік'], expert:['Іздеуде ТОП','«Сарапшы» белгісі','Жазылымға 20% жеңілдік'], legend:['🥇 Іздеуде #1','«Аңыз» белгісі','Жазылымға 30% жеңілдік'] }
    };

    const motivate = () => {
      if (isLegend) return ru ? 'Вы на вершине!' : 'Сіз шыңдасыз!';
      if (remaining === 1) return ru ? 'Ещё 1 заказ до следующего уровня!' : '1 тапсырыс қалды!';
      if (pct >= 80) return ru ? `Почти! Осталось ${remaining}` : `Жақын! ${remaining} қалды`;
      if (pct >= 50) return ru ? `Полпути до "${nextName}"!` : `"${nextName}"-ға жарты жол!`;
      return ru ? `${remaining} заказов до "${nextName}"` : `"${nextName}"-ға ${remaining} тапсырыс`;
    };

    const ACHIEVEMENTS = [
      { emoji:'🎯', ru:'Первый заказ',  kk:'Бірінші тапсырыс', done: n >= 1 },
      { emoji:'⭐', ru:'5 заказов',     kk:'5 тапсырыс',       done: n >= 5 },
      { emoji:'💬', ru:'Рейтинг 4.0+', kk:'Рейтинг 4.0+',    done: avg >= 4.0 },
      { emoji:'🔥', ru:'15 заказов',    kk:'15 тапсырыс',      done: n >= 15 },
      { emoji:'💎', ru:'Рейтинг 4.8+', kk:'Рейтинг 4.8+',    done: avg >= 4.8 },
      { emoji:'👑', ru:'30 заказов',    kk:'30 тапсырыс',      done: n >= 30 },
    ];

    const perks = LEVEL_PERKS[lang][lv.id] || [];

    root.innerHTML = `
      <div style="display:flex;align-items:center;gap:14px;margin-bottom:14px;">
        <div style="width:56px;height:56px;border-radius:18px;background:${lv.color}22;border:2px solid ${lv.color};display:flex;align-items:center;justify-content:center;font-size:28px;flex-shrink:0;box-shadow:0 0 18px ${lv.color}44;">${lv.emoji}</div>
        <div style="flex:1;min-width:0;">
          <div style="font-weight:900;font-size:18px;color:${lv.color};">${esc(lvName)}</div>
          <div class="txt-sm" style="opacity:.7;margin-top:2px;">${n} ${ru ? 'заказов' : 'тапсырыс'} &nbsp;•&nbsp; ⭐ ${avg > 0 ? avg.toFixed(1) : '—'}</div>
        </div>
        ${avg >= 4.8 && n >= 10 ? '<div style="background:#F59E0B22;color:#F59E0B;font-size:10px;font-weight:800;padding:4px 10px;border-radius:999px;border:1px solid #F59E0B;flex-shrink:0;">⭐ TOP</div>' : ''}
      </div>
      <div style="margin-bottom:14px;">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
          <div class="txt-sm" style="font-weight:700;opacity:.85;">${esc(motivate())}</div>
          <div class="txt-sm" style="font-weight:800;color:${lv.color};">${pct}%</div>
        </div>
        <div style="background:var(--surface-highlight);border-radius:999px;height:10px;overflow:hidden;">
          <div id="lvProgressBar" style="height:100%;width:0%;background:linear-gradient(90deg,${lv.color},${lv.color}bb);border-radius:999px;transition:width .8s cubic-bezier(.4,0,.2,1);"></div>
        </div>
        ${nextLv
          ? `<div style="display:flex;justify-content:space-between;margin-top:5px;"><div class="txt-sm" style="opacity:.45;">${esc(lvName)}</div><div class="txt-sm" style="opacity:.45;">${esc(nextName)} ${nextLv.emoji}</div></div>`
          : `<div class="txt-sm" style="color:${lv.color};font-weight:700;margin-top:4px;">🏆 ${ru ? 'Максимальный уровень!' : 'Максималды деңгей!'}</div>`}
      </div>
      <div style="background:${lv.color}11;border:1px solid ${lv.color}33;border-radius:14px;padding:12px;margin-bottom:14px;">
        <div class="txt-sm" style="font-weight:800;margin-bottom:8px;color:${lv.color};">✦ ${ru ? 'Привилегии вашего уровня' : 'Деңгейіңіздің артықшылықтары'}</div>
        ${perks.map(p => `<div class="txt-sm" style="display:flex;align-items:center;gap:8px;margin-bottom:5px;opacity:.9;"><span style="color:${lv.color};">✓</span> ${esc(p)}</div>`).join('')}
      </div>
      <div class="txt-sm" style="font-weight:800;opacity:.7;margin-bottom:10px;">🏅 ${ru ? 'Достижения' : 'Жетістіктер'}</div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;">
        ${ACHIEVEMENTS.map(a => `
          <div style="display:flex;flex-direction:column;align-items:center;gap:4px;padding:10px 8px;border-radius:14px;background:${a.done ? lv.color + '18' : 'var(--surface-highlight)'};border:1px solid ${a.done ? lv.color + '55' : 'var(--border)'};opacity:${a.done ? '1' : '0.35'};transition:opacity .3s;">
            <span style="font-size:22px;">${a.emoji}</span>
            <span style="font-size:10px;font-weight:700;text-align:center;line-height:1.3;">${ru ? a.ru : a.kk}</span>
          </div>`).join('')}
      </div>`;

    requestAnimationFrame(() => {
      const bar = qs('#lvProgressBar');
      if (bar) setTimeout(() => { bar.style.width = pct + '%'; }, 60);
    });
  }
  const _origLoadMasterStats = loadMasterStats;
  async function loadMasterStats() {
    try {
      const s = await apiGet("api/master_stats.php");
      const earnings=Number(s?.earnings_total||0), completed=Number(s?.completed_orders||0), avg=Number(s?.avg_rating||0);
      const p1=qs("#pProgress"); if(p1) p1.textContent=fmtMoney(earnings);
      const p2=qs("#pAccuracy"); if(p2) p2.textContent=avg>0?avg.toFixed(1):"0.0";
      const p3=qs("#pStreak");   if(p3) p3.textContent=String(completed);
      renderMasterLevel(completed, avg);
    } catch {}
  }

  // ═══════════════════════════════════════════════════════
  // 🔔 PUSH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════
  let _pushBannerTimer=null;
  function initPush() {
    if('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(()=>{});
    if('Notification' in window && Notification.permission==='default') setTimeout(()=>Notification.requestPermission(),3000);
  }
  async function pollPushNotifications() {
    if(document.hidden) return;
    try {
      const items = await apiGet('api/push_poll.php');
      (Array.isArray(items)?items:[]).forEach(item=>showPushBanner(String(item.title||'Sheber.kz'),String(item.body||''),String(item.url||'')));
    } catch {}
  }
  function showPushBanner(title,body,url) {
    try{const ctx=new(window.AudioContext||window.webkitAudioContext)();const osc=ctx.createOscillator(),gain=ctx.createGain();osc.connect(gain);gain.connect(ctx.destination);osc.frequency.setValueAtTime(880,ctx.currentTime);osc.frequency.exponentialRampToValueAtTime(440,ctx.currentTime+0.15);gain.gain.setValueAtTime(0.25,ctx.currentTime);gain.gain.exponentialRampToValueAtTime(0.001,ctx.currentTime+0.3);osc.start();osc.stop(ctx.currentTime+0.3);}catch{}
    let banner=qs('#pushBanner');
    if(!banner){banner=document.createElement('div');banner.id='pushBanner';banner.style.cssText='position:fixed;top:16px;left:50%;transform:translateX(-50%) translateY(-120px);background:var(--surface);border:1px solid var(--border);border-radius:18px;padding:12px 16px;max-width:340px;width:90%;z-index:9999;box-shadow:0 8px 32px rgba(0,0,0,.35);cursor:pointer;transition:transform .35s cubic-bezier(.34,1.56,.64,1);display:flex;gap:10px;align-items:center;';document.body.appendChild(banner);}
    banner.onclick=()=>{if(url)window.location.href=url;hidePushBanner();};
    banner.innerHTML=`<div style="width:36px;height:36px;border-radius:12px;background:linear-gradient(135deg,#0069ff,#2EC4B6);display:flex;align-items:center;justify-content:center;flex-shrink:0;"><svg viewBox="0 0 24 24" style="width:18px;height:18px;" fill="none" stroke="#fff" stroke-width="2.5"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg></div><div style="flex:1;min-width:0;"><div style="font-weight:800;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${esc(title)}</div><div class="txt-sm" style="opacity:.8;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${esc(body)}</div></div><button onclick="event.stopPropagation();hidePushBanner();" style="background:none;border:none;color:var(--text-sec);cursor:pointer;font-size:18px;padding:2px 4px;">×</button>`;
    requestAnimationFrame(()=>{banner.style.transform='translateX(-50%) translateY(0)';});
    clearTimeout(_pushBannerTimer); _pushBannerTimer=setTimeout(hidePushBanner,5000);
    if(document.hidden&&'Notification' in window&&Notification.permission==='granted'){try{new Notification(title,{body,icon:'/favicon.png'});}catch{}}
  }
  function hidePushBanner(){const b=qs('#pushBanner');if(b)b.style.transform='translateX(-50%) translateY(-120px)';}

  // ═══════════════════════════════════════════════════════
  // 🗺️ ORDERS MAP
  // ═══════════════════════════════════════════════════════
  let _ordersMap=null,_mapMarkers=[],_masterMarker=null,_masterPos=null,_mapRefreshTimer=null;

  function _distanceM(lat1,lng1,lat2,lng2){
    const R=6371000,dLat=(lat2-lat1)*Math.PI/180,dLng=(lng2-lng1)*Math.PI/180;
    const a=Math.sin(dLat/2)**2+Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLng/2)**2;
    return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));
  }

  async function initOrdersMap() {
    const el=qs('#ordersMapContainer'); if(!el||!window.L) return;
    if(_ordersMap){_ordersMap.invalidateSize();await loadOrdersOnMap();return;}
    _ordersMap=L.map('ordersMapContainer',{zoomControl:true}).setView([43.238,76.945],13);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© OpenStreetMap',maxZoom:19}).addTo(_ordersMap);

    // GPS мастера — постоянное отслеживание
    if(navigator.geolocation){
      navigator.geolocation.watchPosition(pos=>{
        const lat=pos.coords.latitude,lng=pos.coords.longitude;
        _masterPos={lat,lng};
        _ordersMap.setView([lat,lng],14);
        // Маркер мастера — синяя точка
        const masterIcon=L.divIcon({className:'',html:`
          <div style="position:relative;width:20px;height:20px;">
            <div style="position:absolute;inset:0;background:var(--primary,#0069ff);border-radius:50%;border:3px solid #fff;box-shadow:0 2px 8px rgba(0,105,255,.5);z-index:2;"></div>
            <div style="position:absolute;inset:-6px;background:rgba(0,105,255,.2);border-radius:50%;animation:masterPulse 2s infinite;"></div>
          </div>`,iconSize:[20,20],iconAnchor:[10,10]});
        if(_masterMarker) _masterMarker.setLatLng([lat,lng]);
        else { _masterMarker=L.marker([lat,lng],{icon:masterIcon,zIndexOffset:1000}).addTo(_ordersMap); _masterMarker.bindPopup(getLang()==='ru'?'Вы здесь':'Сіз осындасыз'); }
        loadOrdersOnMap();
      },()=>{loadOrdersOnMap();},{enableHighAccuracy:true,maximumAge:10000});
    } else { await loadOrdersOnMap(); }

    // Автообновление каждые 15 сек
    if(_mapRefreshTimer) clearInterval(_mapRefreshTimer);
    _mapRefreshTimer=setInterval(()=>loadOrdersOnMap().catch(()=>{}),15000);
  }

  async function loadOrdersOnMap() {
    if(!_ordersMap) return;
    try {
      const orders=await apiGet('api/orders_feed.php?limit=100');
      const arr=Array.isArray(orders)?orders:[];
      _mapMarkers.forEach(m=>_ordersMap.removeLayer(m));_mapMarkers=[];
      const newOrders=arr.filter(o=>String(o.status)==='new');
      const cnt=qs('#mapOrdersCount');if(cnt)cnt.textContent=newOrders.length;

      let nearbyCount=0;
      newOrders.forEach(o=>{
        const lat=parseFloat(o.client_lat),lng=parseFloat(o.client_lng);
        if(!isFinite(lat)||!isFinite(lng)) return;

        const dist=_masterPos?Math.round(_distanceM(_masterPos.lat,_masterPos.lng,lat,lng)):null;
        const isNearby=dist!==null&&dist<=1000;
        if(isNearby) nearbyCount++;

        const distLabel=dist!==null?(dist<1000?`${dist}м`:`${(dist/1000).toFixed(1)}км`):'';
        const pulse=isNearby?`<div style="position:absolute;inset:-10px;background:rgba(255,80,0,.15);border-radius:50%;animation:nearbyPulse 1.2s infinite;"></div>`:'';

        const icon=L.divIcon({className:'',html:`
          <div style="position:relative;display:inline-flex;flex-direction:column;align-items:center;">
            ${pulse}
            <div style="background:${isNearby?'linear-gradient(135deg,#ff5000,#ff9500)':'linear-gradient(135deg,#0069ff,#2EC4B6)'};color:#fff;font-size:11px;font-weight:800;padding:6px 10px;border-radius:999px;box-shadow:0 3px 14px ${isNearby?'rgba(255,80,0,.5)':'rgba(0,105,255,.4)'};white-space:nowrap;border:2px solid #fff;position:relative;z-index:1;">
              ${isNearby?'🔥 ':''}${fmtMoney(Number(o.price||0))} ₸${distLabel?`<span style="opacity:.8;font-size:9px;margin-left:4px;">${distLabel}</span>`:''}
            </div>
          </div>`,iconAnchor:[0,0]});

        const marker=L.marker([lat,lng],{icon}).addTo(_ordersMap);
        marker.bindPopup(`
          <div style="min-width:180px;font-family:Manrope,sans-serif;">
            <div style="font-weight:800;margin-bottom:4px;">${esc(String(o.service_title||'Заказ'))}</div>
            <div style="font-size:12px;opacity:.8;margin-bottom:4px;">📍 ${esc(String(o.address||''))}</div>
            ${distLabel?`<div style="font-size:12px;color:${isNearby?'#ff5000':'#0069ff'};font-weight:700;margin-bottom:6px;">📏 ${distLabel} от вас</div>`:''}
            <div style="font-weight:700;color:#0069ff;font-size:15px;margin-bottom:8px;">${fmtMoney(Number(o.price||0))} ₸</div>
            <button onclick="openOrderChat&&openOrderChat(${Number(o.id)});this.closest('.leaflet-popup').querySelector('.leaflet-popup-close-button')?.click();" style="width:100%;padding:8px;background:#0069ff;color:#fff;border:none;border-radius:8px;font-weight:700;cursor:pointer;">⚡ ${getLang()==='ru'?'Принять':'Қабылдау'}</button>
          </div>`);
        _mapMarkers.push(marker);
      });

      // Уведомление если рядом есть заказы
      const nearbyBadge=qs('#nearbyOrdersBadge');
      if(nearbyBadge){
        nearbyBadge.textContent=nearbyCount>0?`🔥 ${nearbyCount} ${getLang()==='ru'?'рядом':'жақын'}`:'';
        nearbyBadge.style.display=nearbyCount>0?'inline-block':'none';
      }
    } catch {}
  }
  function switchOrdersView(view) {
    const lv=qs('#ordersListView'),mv=qs('#ordersMapView'),bl=qs('#viewBtnList'),bm=qs('#viewBtnMap');
    if(!lv||!mv) return;
    if(view==='map'){lv.style.display='none';mv.style.display='block';if(bl){bl.style.background='transparent';bl.style.color='var(--text-sec)';}if(bm){bm.style.background='var(--primary)';bm.style.color='#fff';}setTimeout(()=>initOrdersMap().catch(()=>{}),100);}
    else{mv.style.display='none';lv.style.display='block';if(bl){bl.style.background='var(--primary)';bl.style.color='#fff';}if(bm){bm.style.background='transparent';bm.style.color='var(--text-sec)';}}
  }

  // ═══════════════════════════════════════════════════════
  // 💬 CHAT EXTRAS — фото, голос
  // ═══════════════════════════════════════════════════════
  let _mediaRecorder=null,_audioChunks=[],_isRecording=false,_recordTimer=null;
  async function sendChatImage(input) {
    const file=input?.files?.[0];if(!file) return;
    const oid=CHAT_STATE?.currentOrderId;if(!oid) return;
    showToast(getLang()==='ru'?'Отправка...':'Жіберілуде...');
    try{
      await ensureCsrf();
      const fd=new FormData();fd.append('order_id',String(oid));fd.append('type','image');fd.append('file',file);fd.append('body','');
      const r=await fetch('api/messages_send.php',{method:'POST',headers:{'X-CSRF-Token':CSRF_TOKEN},body:fd,credentials:'same-origin'});
      const d=await r.json().catch(()=>null);
      if(!d?.ok) throw new Error(d?.error||'send_failed');
      input.value='';await fetchOrderMessages(true);
    }catch(e){showToast(e.message);}
  }
  async function toggleVoiceRecord(btn) {
    if(_isRecording){_mediaRecorder?.stop();return;}
    try{
      const stream=await navigator.mediaDevices.getUserMedia({audio:true});
      _audioChunks=[];_mediaRecorder=new MediaRecorder(stream);
      _mediaRecorder.ondataavailable=e=>{if(e.data.size>0)_audioChunks.push(e.data);};
      _mediaRecorder.onstop=async()=>{stream.getTracks().forEach(t=>t.stop());_isRecording=false;clearInterval(_recordTimer);if(btn)btn.style.background='';const blob=new Blob(_audioChunks,{type:'audio/webm'});if(blob.size>500)await sendVoiceMessage(blob);};
      _mediaRecorder.start();_isRecording=true;
      if(btn){btn.style.background='#ef4444';let s=0;_recordTimer=setInterval(()=>{s++;if(s>=60)_mediaRecorder?.stop();},1000);}
    }catch{showToast(getLang()==='ru'?'Нет доступа к микрофону':'Микрофонға рұқсат жоқ');}
  }
  async function sendVoiceMessage(blob) {
    const oid=CHAT_STATE?.currentOrderId;if(!oid) return;
    try{
      await ensureCsrf();
      const fd=new FormData();fd.append('order_id',String(oid));fd.append('type','voice');fd.append('file',blob,'voice.webm');fd.append('body','');
      const r=await fetch('api/messages_send.php',{method:'POST',headers:{'X-CSRF-Token':CSRF_TOKEN},body:fd,credentials:'same-origin'});
      const d=await r.json().catch(()=>null);
      if(!d?.ok) throw new Error(d?.error||'send_failed');
      await fetchOrderMessages(true);
    }catch(e){showToast(e.message);}
  }
  function toggleVoicePlay(btn,url) {
    if(btn._audio&&!btn._audio.paused){btn._audio.pause();return;}
    const audio=btn._audio||new Audio(url);btn._audio=audio;
    const wrap=btn.closest('[data-msg-id]'),mid=wrap?.dataset?.msgId;
    const prog=mid?qs(`#vprog-${mid}`):null,dur=mid?qs(`#vdur-${mid}`):null;
    audio.ontimeupdate=()=>{if(prog&&audio.duration)prog.style.width=`${(audio.currentTime/audio.duration)*100}%`;if(dur){const s=Math.floor(audio.currentTime);dur.textContent=`${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}`;}};
    audio.onended=()=>{btn.innerHTML='▶';if(prog)prog.style.width='0%';};
    audio.play().catch(()=>{});btn.innerHTML='⏸';
  }

  // ═══════════════════════════════════════════════════════
  // 🖼️ PORTFOLIO
  // ═══════════════════════════════════════════════════════
  async function loadPortfolio() {
    const root=qs('#portfolioGrid');if(!root) return;
    root.innerHTML=`<div style="opacity:.5;font-size:12px;padding:8px;">Жүктелуде...</div>`;
    try{
      const photos=await apiGet('api/portfolio_photos.php');
      const cnt=qs('#portfolioCount');if(cnt)cnt.textContent=`${photos.length}/12`;
      if(!photos.length){root.innerHTML=`<div style="grid-column:1/-1;text-align:center;padding:16px;opacity:.5;font-size:13px;">${getLang()==='ru'?'Нет фото работ':'Жұмыс фотолары жоқ'}</div>`;return;}
      root.innerHTML=photos.map(p=>`<div style="position:relative;border-radius:12px;overflow:hidden;aspect-ratio:1;background:var(--surface-highlight);">
        <img src="${esc(p.url)}" style="width:100%;height:100%;object-fit:cover;display:block;" loading="lazy">
        <button onclick="deletePortfolioPhoto(${p.id})" style="position:absolute;top:5px;right:5px;background:rgba(0,0,0,.6);border:none;border-radius:50%;width:24px;height:24px;color:#fff;cursor:pointer;font-size:14px;line-height:1;">×</button>
        ${p.caption?`<div style="position:absolute;bottom:0;left:0;right:0;background:linear-gradient(transparent,rgba(0,0,0,.7));padding:6px 8px;font-size:10px;color:#fff;font-weight:600;">${esc(p.caption)}</div>`:''}
      </div>`).join('');
    }catch{const r=qs('#portfolioGrid');if(r)r.innerHTML='';}
  }
  async function deletePortfolioPhoto(id) {
    if(!confirm(getLang()==='ru'?'Удалить фото?':'Фотоны жою?')) return;
    try{await ensureCsrf();await fetch('api/portfolio_photos.php',{method:'DELETE',headers:{'Content-Type':'application/x-www-form-urlencoded','X-CSRF-Token':CSRF_TOKEN},body:`photo_id=${id}`,credentials:'same-origin'});await loadPortfolio();}
    catch(e){showToast(e.message);}
  }
  async function uploadPortfolioPhoto(input) {
    const file=input?.files?.[0];if(!file) return;
    const caption=qs('#portfolioCaptionInput')?.value?.trim()||'';
    showToast(getLang()==='ru'?'Загрузка...':'Жүктелуде...');
    try{
      await ensureCsrf();
      const fd=new FormData();fd.append('photo',file);fd.append('caption',caption);
      const r=await fetch('api/portfolio_photos.php',{method:'POST',headers:{'X-CSRF-Token':CSRF_TOKEN},body:fd,credentials:'same-origin'});
      const d=await r.json().catch(()=>null);
      if(!d?.ok) throw new Error(d?.error||'upload_failed');
      if(qs('#portfolioCaptionInput'))qs('#portfolioCaptionInput').value='';
      input.value='';await loadPortfolio();
    }catch(e){showToast(e.message);}
  }

  // ── Exports ──────────────────────────────────────────────
  window.toggleOnlineStatus   = toggleOnlineStatus;
  window.loadEarningsChart    = loadEarningsChart;
  window.loadPortfolio        = loadPortfolio;
  window.uploadPortfolioPhoto = uploadPortfolioPhoto;
  window.deletePortfolioPhoto = deletePortfolioPhoto;
  window.hidePushBanner       = hidePushBanner;
  window.toggleVoicePlay      = toggleVoicePlay;
  window.toggleVoiceRecord    = toggleVoiceRecord;
  window.sendChatImage        = sendChatImage;
  window.loadOrdersOnMap      = loadOrdersOnMap;
  window.switchOrdersView     = switchOrdersView;
})();