(() => {
  function qs(sel){ return document.querySelector(sel); }

  function syncUI(){
    // theme toggle (checkbox)
    const cb = qs("#themeToggle");
    if (cb) cb.checked = (window.Prefs && Prefs.getTheme) ? (Prefs.getTheme() === "dark") : (document.documentElement.getAttribute("data-theme")==="dark");

    // language buttons
    const lang = (window.Prefs && Prefs.getLang) ? Prefs.getLang() : "ru";
    const kkBtn = qs("#lang-kk");
    const ruBtn = qs("#lang-ru");
    if (kkBtn) kkBtn.classList.toggle("active", lang === "kk");
    if (ruBtn) ruBtn.classList.toggle("active", lang === "ru");
  }

  document.addEventListener("DOMContentLoaded", () => {
    // bind theme
    const cb = qs("#themeToggle");
    if (cb) {
      cb.addEventListener("change", () => {
        if (window.Prefs && Prefs.applyTheme) Prefs.applyTheme(cb.checked ? "dark" : "light");
      });
    }

    // bind lang
    const kkBtn = qs("#lang-kk");
    if (kkBtn) kkBtn.addEventListener("click", (e)=>{ e.preventDefault(); if (window.Prefs) Prefs.setLang("kk"); });
    const ruBtn = qs("#lang-ru");
    if (ruBtn) ruBtn.addEventListener("click", (e)=>{ e.preventDefault(); if (window.Prefs) Prefs.setLang("ru"); });

    syncUI();
  });

  // re-sync after history navigation
  window.addEventListener("pageshow", syncUI);
})();
