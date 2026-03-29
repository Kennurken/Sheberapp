(() => {
  const STORAGE = { theme: "theme", lang: "lang" };

  function setCookie(name, value, days = 365) {
    try {
      const maxAge = days * 24 * 60 * 60;
      document.cookie = `${encodeURIComponent(name)}=${encodeURIComponent(value)}; Max-Age=${maxAge}; Path=/; SameSite=Lax`;
    } catch (_) {}
  }

  function getLang() {
    const ls = (() => { try { return localStorage.getItem(STORAGE.lang); } catch(_) { return null; } })();
    const normalized = (ls || document.documentElement.getAttribute("lang") || "ru").toLowerCase();
    return normalized === "ru" ? "ru" : "kk";
  }

  function setLang(lang, opts = {}) {
    const normalized = (lang || "").toLowerCase() === "ru" ? "ru" : "kk";
    try { localStorage.setItem(STORAGE.lang, normalized); } catch(_) {}
    setCookie("lang", normalized);

    // translate in-place (SPA)
    if (typeof window.applyI18n === "function") window.applyI18n(document);

    // sync server session for PHP-rendered pages
    if (opts.reload !== false) {
      const url = new URL(window.location.href);
      url.searchParams.set("lang", normalized);
      window.location.href = url.toString();
    }
  }

  function getTheme() {
    const ls = (() => { try { return localStorage.getItem(STORAGE.theme); } catch(_) { return null; } })();
    const normalized = (ls || document.documentElement.getAttribute("data-theme") || "light").toLowerCase();
    return normalized === "dark" ? "dark" : "light";
  }

  function applyTheme(theme) {
    const t = (theme === "light") ? "light" : "dark";
    document.documentElement.setAttribute("data-theme", t);
    try { localStorage.setItem(STORAGE.theme, t); } catch(_) {}
    setCookie("theme", t);
  }

  function toggleTheme() {
    applyTheme(getTheme() === "dark" ? "light" : "dark");
  }

  // Apply theme ASAP (prevents flash). Safe to call in <head>.
  function applyThemeASAP() {
    try {
      const t = localStorage.getItem(STORAGE.theme);
      if (t === "dark" || t === "light") {
        document.documentElement.setAttribute("data-theme", t);
      }
    } catch (_) {}
  }

  window.Prefs = { getLang, setLang, getTheme, applyTheme, toggleTheme, applyThemeASAP };
})();
