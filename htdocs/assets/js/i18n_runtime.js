(() => {
  function dict(lang) {
    const l = (lang || "").toLowerCase() === "ru" ? "ru" : "kk";
    return (window.I18N && window.I18N[l]) ? window.I18N[l] : {};
  }

  function tr(key, lang) {
    const d = dict(lang);
    if (key && d && Object.prototype.hasOwnProperty.call(d, key)) return d[key];
    // fallback to RU if missing
    const dr = (window.I18N && window.I18N.ru) ? window.I18N.ru : {};
    if (key && dr && Object.prototype.hasOwnProperty.call(dr, key)) return dr[key];
    return key || "";
  }

  function applyOne(el, lang) {
    if (!(el instanceof Element)) return;

    const key = el.getAttribute("data-i18n");
    if (key) el.textContent = tr(key, lang);

    const htmlKey = el.getAttribute("data-i18n-html");
    if (htmlKey) el.innerHTML = tr(htmlKey, lang);

    const phKey = el.getAttribute("data-i18n-placeholder");
    if (phKey && "placeholder" in el) el.placeholder = tr(phKey, lang);

    const titleKey = el.getAttribute("data-i18n-title");
    if (titleKey) el.title = tr(titleKey, lang);

    const valKey = el.getAttribute("data-i18n-value");
    if (valKey && "value" in el) el.value = tr(valKey, lang);

    const ariaKey = el.getAttribute("data-i18n-aria");
    if (ariaKey) el.setAttribute("aria-label", tr(ariaKey, lang));
  }

  function applyI18n(root = document) {
    const lang = (window.Prefs && window.Prefs.getLang) ? window.Prefs.getLang() : ((document.documentElement.getAttribute("lang") || "ru").toLowerCase() === "ru" ? "ru" : "kk");
    document.documentElement.setAttribute("lang", lang);

    // Translate root itself if needed
    if (root instanceof Element) applyOne(root, lang);

    const nodes = (root || document).querySelectorAll("[data-i18n],[data-i18n-html],[data-i18n-placeholder],[data-i18n-title],[data-i18n-value],[data-i18n-aria]");
    nodes.forEach(n => applyOne(n, lang));
  }

  window.applyI18n = applyI18n;
  window.tr = tr;

  document.addEventListener("DOMContentLoaded", () => {
    applyI18n(document);
  });
})();
