(function () {
  const HOME_IMG = "/branding/home-brand.png";

  function isHome() {
    const p = (location.pathname || "/").toLowerCase();
    return p === "/" || p.endsWith("/index.html");
  }

  function applyBrand() {
    if (!isHome()) return;

    const all = Array.from(document.images || []);
    const existing = all.find(img => {
      const hay = [
        img.id || "",
        img.className || "",
        img.alt || "",
        img.getAttribute("src") || ""
      ].join(" ").toLowerCase();

      return /logo|maranatha|brand|church|eglise/.test(hay);
    });

    if (existing && !existing.dataset.maranathaFinalBrand) {
      existing.src = HOME_IMG;
      existing.dataset.maranathaFinalBrand = "1";
      existing.style.objectFit = "contain";
      existing.style.maxWidth = existing.style.maxWidth || "220px";
      existing.style.height = "auto";
      return;
    }

    if (!document.getElementById("maranatha-final-home-brand")) {
      const wrap = document.createElement("div");
      wrap.id = "maranatha-final-home-brand";
      wrap.style.cssText =
        "width:100%;display:flex;justify-content:center;align-items:center;" +
        "padding:16px 12px 8px;box-sizing:border-box;background:transparent;";

      const img = document.createElement("img");
      img.src = HOME_IMG;
      img.alt = "Eglise CEMM Maranatha";
      img.style.cssText =
        "display:block;width:min(210px,58vw);height:auto;object-fit:contain;";

      wrap.appendChild(img);
      document.body.insertBefore(wrap, document.body.firstChild);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", applyBrand, { once: true });
  } else {
    applyBrand();
  }

  // Utile si la page charge l'interface dynamiquement.
  const observer = new MutationObserver(() => applyBrand());
  observer.observe(document.documentElement, { childList: true, subtree: true });

  window.addEventListener("popstate", applyBrand);
  window.addEventListener("hashchange", applyBrand);
})();
