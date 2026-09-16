(function () {
  "use strict";

  const STYLE_ID = "maranatha-settings-final-style";
  const APK_URL = "/downloads/MARANATHA.apk";
  const VERSION = "1.2.4";

  function injectStyles() {
    if (document.getElementById(STYLE_ID)) return;

    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `
      .ms-wrap{
        display:grid;
        gap:22px;
        padding:4px 0 12px;
        font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","Segoe UI",Roboto,Arial,sans-serif;
        color:#18181b;
      }

      .ms-section-title{
        margin:0 10px 8px;
        color:#6f7278;
        font-size:12px;
        line-height:16px;
        font-weight:650;
        letter-spacing:0;
        text-transform:none;
      }

      .ms-box{
        overflow:hidden;
        background:#fff;
        border:0;
        border-radius:15px;
        box-shadow:0 1px 2px rgba(0,0,0,.025);
      }

      .ms-row{
        width:100%;
        min-height:54px;
        display:flex;
        align-items:center;
        gap:10px;
        padding:8px 13px;
        border:0;
        border-bottom:1px solid #f0f0f2;
        background:#fff;
        text-align:left;
        color:#17171a;
        -webkit-tap-highlight-color:transparent;
      }

      .ms-row:last-child{
        border-bottom:0;
      }

      button.ms-row{
        cursor:pointer;
      }

      button.ms-row:active{
        background:#f7f7f8;
      }

      .ms-icon{
        width:30px;
        height:30px;
        flex:0 0 30px;
        display:grid;
        place-items:center;
        border-radius:9px;
        background:#f6f6f7;
        color:#252529;
      }

      .ms-icon svg{
        width:16px;
        height:16px;
        stroke-width:1.8;
      }

      .ms-copy{
        flex:1;
        min-width:0;
        display:flex;
        flex-direction:column;
        justify-content:center;
      }

      .ms-name{
        display:block;
        color:#1c1c1e;
        font-size:13.5px;
        line-height:18px;
        font-weight:600;
        letter-spacing:-.08px;
      }

      .ms-desc{
        display:block;
        margin-top:1px;
        color:#8a8a90;
        font-size:10.5px;
        line-height:14px;
        font-weight:400;
      }

      .ms-value{
        flex:0 0 auto;
        max-width:105px;
        overflow:hidden;
        text-overflow:ellipsis;
        white-space:nowrap;
        color:#737378;
        background:transparent;
        padding:0;
        font-size:11px;
        line-height:15px;
        font-weight:500;
      }

      .ms-value.active{
        color:#1f9d55;
      }

      .ms-arrow{
        width:18px;
        height:24px;
        flex:0 0 18px;
        display:grid;
        place-items:center;
        color:#c2c2c7;
      }

      .ms-arrow svg{
        width:14px;
        height:14px;
        stroke-width:1.8;
      }

      .ms-toggle{
        position:relative;
        width:42px;
        height:24px;
        flex:0 0 42px;
        border:0;
        border-radius:999px;
        padding:2px;
        background:#d8d9dd;
        cursor:pointer;
        transition:background .18s ease;
      }

      .ms-toggle span{
        display:block;
        width:20px;
        height:20px;
        border-radius:50%;
        background:#fff;
        box-shadow:0 1px 3px rgba(0,0,0,.22);
        transition:transform .18s ease;
      }

      .ms-toggle.on{
        background:#34c759;
      }

      .ms-toggle.on span{
        transform:translateX(18px);
      }

      .ms-download{
        background:#fff!important;
        color:#17171a!important;
      }

      .ms-download .ms-name{
        color:#1c1c1e!important;
      }

      .ms-download .ms-desc{
        color:#8a8a90!important;
        opacity:1!important;
      }

      .ms-download .ms-icon{
        background:#f6f6f7!important;
        color:#252529!important;
      }

      .ms-download .ms-arrow{
        color:#c2c2c7!important;
      }

      .ms-version{
        padding:1px 12px 5px;
        text-align:center;
        color:#a0a0a6;
        font-size:9.5px;
        line-height:14px;
        font-weight:400;
      }

      @media (max-width:380px){
        .ms-wrap{gap:18px}
        .ms-row{min-height:52px;padding:8px 11px}
        .ms-name{font-size:13px}
        .ms-desc{font-size:10px}
      }

      html.maranatha-reduce-motion *,
      html.maranatha-reduce-motion *::before,
      html.maranatha-reduce-motion *::after{
        animation-duration:.001ms!important;
        animation-iteration-count:1!important;
        transition-duration:.001ms!important;
        scroll-behavior:auto!important;
      }
    `;
    document.head.appendChild(style);
  }
  function icon(path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + path + '</svg>';
  }

  function render() {
    injectStyles();

    const reduceMotion =
      localStorage.getItem("maranatha_reduce_motion") === "1";

    const nativeApp =
      typeof window.FlutterAudio !== "undefined";

    let notificationText = "\u00C0 v\u00E9rifier";

    if (nativeApp) {
      notificationText = "Android";
    } else if ("Notification" in window) {
      const labels = {
        granted: "Autoris\u00E9es",
        denied: "Bloqu\u00E9es",
        default: "\u00C0 autoriser"
      };

      notificationText =
        labels[Notification.permission] || "\u00C0 v\u00E9rifier";
    } else {
      notificationText = "Non disponible";
    }

    const chevron =
      icon('<path d="m9 18 6-6-6-6"/>');

    return `
      <div class="ms-wrap">

        <section>
          <div class="ms-section-title">G\u00E9n\u00E9ral</div>

          <div class="ms-box">

            <button class="ms-row" id="ms-notifications" type="button">
              <span class="ms-icon">
                ${icon('<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">Notifications</span>
              </span>

              <span class="ms-value">${notificationText}</span>
              <span class="ms-arrow">${chevron}</span>
            </button>


          </div>
        </section>


        <section>
          <div class="ms-section-title">R\u00E9veil &amp; audio</div>

          <div class="ms-box">

            <div class="ms-row">
              <span class="ms-icon">
                ${icon('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">R\u00E9veil Maranatha</span>
              </span>

              <span class="ms-value active">Automatique</span>
            </div>

            <div class="ms-row">
              <span class="ms-icon">
                ${icon('<path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">Audio en arri\u00E8re-plan</span>
              </span>

              <span class="ms-value active">Actif</span>
            </div>

          </div>
        </section>


        <section>
          <div class="ms-section-title">Compte</div>

          <div class="ms-box">

            <button class="ms-row" id="ms-profile" type="button">
              <span class="ms-icon">
                ${icon('<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">Mon profil</span>
              </span>

              <span class="ms-arrow">${chevron}</span>
            </button>

          </div>
        </section>


        <section>
          <div class="ms-section-title">Application</div>

          <div class="ms-box">

            <button class="ms-row ms-download" id="ms-download" type="button">
              <span class="ms-icon">
                ${icon('<path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">T\u00E9l\u00E9charger l\u2019application</span>
              </span>

              <span class="ms-arrow">${chevron}</span>
            </button>

            <button class="ms-row" id="ms-privacy" type="button">
              <span class="ms-icon">
                ${icon('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">Confidentialit\u00E9 et donn\u00E9es</span>
              </span>

              <span class="ms-arrow">${chevron}</span>
            </button>

            <button class="ms-row" id="ms-about" type="button">
              <span class="ms-icon">
                ${icon('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>')}
              </span>

              <span class="ms-copy">
                <span class="ms-name">\u00C0 propos de Maranatha</span>
              </span>

              <span class="ms-arrow">${chevron}</span>
            </button>

          </div>
        </section>


        <div class="ms-version">
          MARANATHA &mdash; version ${VERSION}<br>
          Communaut\u00E9 des \u00C9glises Missionnaires Maranatha
        </div>

      </div>
    `;
  }
  function showToast(message) {
    const toast =
      document.getElementById("m-toast");
    if (!toast) {
      window.alert(message);
      return;
    }
    toast.textContent = message;
    toast.classList.add("show");
    clearTimeout(window.__MARANATHA_SETTINGS_TOAST__);
    window.__MARANATHA_SETTINGS_TOAST__ = setTimeout(function () {
      toast.classList.remove("show");
    }, 2400);
  }

  function applyMotionPreference() {
    document.documentElement.classList.toggle(
      "maranatha-reduce-motion",
      localStorage.getItem("maranatha_reduce_motion") === "1"
    );
  }

  async function requestNotifications() {
    if (typeof window.FlutterAudio !== "undefined") {
      showToast("Dans l’application Android, les notifications sont gérées par les autorisations du téléphone.");
      return;
    }

    if (!("Notification" in window)) {
      showToast("Les notifications ne sont pas disponibles dans ce navigateur.");
      return;
    }

    if (Notification.permission === "denied") {
      showToast("Les notifications sont bloquées. Autorisez-les dans les paramètres du navigateur.");
      return;
    }

    try {
      await Notification.requestPermission();
      const value = document.getElementById("ms-notification-value");
      if (value) {
        value.textContent =
          Notification.permission === "granted"
            ? "Autorisées"
            : "À autoriser";
      }
    } catch (_) {
      showToast("Impossible de demander l’autorisation des notifications.");
    }
  }

  async function downloadApp() {
    const button = document.getElementById("ms-download");
    const original = button ? button.querySelector(".ms-name") : null;
    if (original) original.textContent = "Vérification de l’APK...";

    try {
      const response = await fetch(APK_URL, {
        method: "HEAD",
        cache: "no-store"
      });

      if (!response.ok) {
        throw new Error("APK_NOT_FOUND");
      }

      const link = document.createElement("a");
      link.href = APK_URL;
      link.download = "MARANATHA.apk";
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (_) {
      showToast("L’APK n’est pas encore présent dans public/downloads/MARANATHA.apk.");
    } finally {
      if (original) original.textContent = "Télécharger l’application";
    }
  }

  function showAbout() {
    const body = document.getElementById("m-sheet-body");
    if (!body) return;

    body.innerHTML = `
      <div class="m-card">
        <h3 class="m-card-title">MARANATHA</h3>
        <div class="m-card-text">
          Application de la Communauté des Églises Missionnaires Maranatha.
          Elle regroupe les prédications, le programme, la Bible, les dons,
          les témoignages et les informations de la communauté.
        </div>
        <div class="m-card-meta">Version ${VERSION}</div>
      </div>
      <button class="m-secondary" id="ms-about-back" type="button" style="width:100%;margin-top:10px">Retour aux paramètres</button>
    `;

    const back = document.getElementById("ms-about-back");
    if (back) {
      back.addEventListener("click", function () {
        body.innerHTML = render();
        bind();
      });
    }
  }

  function bind() {
    injectStyles();
    applyMotionPreference();

    const profile = document.getElementById("ms-profile");
    if (profile) {
      profile.addEventListener("click", function () {
        const close = document.getElementById("m-sheet-close");
        if (close) close.click();
        if (
          window.MaranathaHome &&
          typeof window.MaranathaHome.profile === "function"
        ) {
          window.MaranathaHome.profile();
        } else if (typeof window.ouvrirProfilFinal === "function") {
          window.ouvrirProfilFinal();
        }
      });
    }

    const notifications = document.getElementById("ms-notifications");
    if (notifications) {
      notifications.addEventListener("click", requestNotifications);
    }

    const motion = document.getElementById("ms-motion");
    if (motion) {
      motion.addEventListener("click", function () {
        const enabled =
          localStorage.getItem("maranatha_reduce_motion") === "1";
        localStorage.setItem(
          "maranatha_reduce_motion",
          enabled ? "0" : "1"
        );
        applyMotionPreference();
        motion.classList.toggle("on", !enabled);
        motion.setAttribute("aria-pressed", String(!enabled));
      });
    }

    const download = document.getElementById("ms-download");
    if (download) {
      download.addEventListener("click", downloadApp);
    }

    const privacy = document.getElementById("ms-privacy");
    if (privacy) {
      privacy.addEventListener("click", function () {
        window.open("/politique-confidentialite", "_blank", "noopener");
      });
    }

    const about = document.getElementById("ms-about");
    if (about) {
      about.addEventListener("click", showAbout);
    }
  }

  window.MaranathaSettings = {
    render,
    bind,
    applyMotionPreference
  };

  injectStyles();
  applyMotionPreference();
})();
