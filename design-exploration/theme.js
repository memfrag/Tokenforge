(function () {
  const KEY = "tokenforge-theme";
  const root = document.documentElement;
  const saved = localStorage.getItem(KEY);
  if (saved === "light" || saved === "dark") {
    root.setAttribute("data-theme", saved);
  }
  function current() {
    const attr = root.getAttribute("data-theme");
    if (attr) return attr;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }
  function set(mode) {
    root.setAttribute("data-theme", mode);
    localStorage.setItem(KEY, mode);
    document.querySelectorAll("[data-theme-btn]").forEach(btn => {
      btn.setAttribute("aria-pressed", btn.dataset.themeBtn === mode ? "true" : "false");
    });
    const iphone = document.querySelector(".iphone");
    if (iphone && iphone.dataset.iosTheme !== undefined) iphone.dataset.iosTheme = mode;
  }
  window.__tfSetTheme = set;
  document.addEventListener("DOMContentLoaded", () => {
    set(current());
    document.querySelectorAll("[data-theme-btn]").forEach(btn => {
      btn.addEventListener("click", () => set(btn.dataset.themeBtn));
    });
    // Preview pane extras
    const appearanceBtns = document.querySelectorAll("[data-ios-appearance]");
    appearanceBtns.forEach(btn => btn.addEventListener("click", () => {
      appearanceBtns.forEach(b => b.setAttribute("aria-pressed", "false"));
      btn.setAttribute("aria-pressed", "true");
      const iphone = document.querySelector(".iphone");
      if (iphone) iphone.dataset.iosTheme = btn.dataset.iosAppearance;
    }));
    const emphasisToggle = document.querySelector("[data-emphasis-toggle]");
    if (emphasisToggle) {
      emphasisToggle.addEventListener("change", () => {
        const iphone = document.querySelector(".iphone");
        if (iphone) iphone.classList.toggle("emphasis", emphasisToggle.checked);
      });
    }
  });
})();
