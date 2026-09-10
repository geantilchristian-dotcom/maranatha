(function () {
  "use strict";

  const STYLE_ID = "maranatha-settings-final-style";
  const APK_URL = "/downloads/MARANATHA.apk";
  const VERSION = "1.2.0";

  function injectStyles() {
    if (document.getElementById(STYLE_ID)) return;

    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `
      .ms-wrap{display:grid;gap:14px}
      .ms-section-title{
        margin:2px 3px 7px;color:#7b8493;font-size:10px;
        font-weight:900;letter-spacing:.7px;text-transform:uppercase;
      }
      .ms-box{
        overflow:hidden;background:#fff;border:1px solid #e4e8ee;
        border-radius:17px;box-shadow:0 4px 13px rgba(15,23,42,.04);
      }
      .ms-row{
        width:100%;min-height:58px;display:flex;align-items:center;gap:11px;
        padding:10px 13px;border:0;border-bottom:1px solid #edf0f4;
        background:#fff;text-align:left;color:#172033;
      }
      .ms-row:last-child{border-bottom:0}
      button.ms-row{cursor:pointer}
      button.ms-row:active{background:#faf3f5}
      .ms-icon{
        width:36px;height:36px;flex:0 0 36px;display:grid;place-items:center;
        border-radius:11px;background:#fff0f2;color:#a5001a;
      }
      .ms-icon svg{width:19px;height:19px}
      .ms-copy{flex:1;min-width:0}
      .ms-name{font-size:12px;font-weight:900;color:#18202c}
      .ms-desc{margin-top:2px;font-size:9.5px;line-height:1.35;color:#828c9c}
      .ms-value{
        flex:0 0 auto;padding:5px 8px;border-radius:20px;
        background:#edf8f2;color:#137348;font-size:9px;font-weight:900;
      }
      .ms-arrow{flex:0 0 auto;color:#a0a8b4;font-size:21px;line-height:1}
      .ms-toggle{
        width:44px;height:25px;flex:0 0 44px;border:0;border-radius:20px;
        padding:3px;background:#d8dde4;cursor:pointer;
      }
      .ms-toggle span{
        display:block;width:19px;height:19px;border-radius:50%;
        background:#fff;box-shadow:0 1px 4px rgba(0,0,0,.18);transition:.18s;
      }
      .ms-toggle.on{background:#b50024}
      .ms-toggle.on span{transform:translateX(19px)}
      .ms-download{
        background:linear-gradient(135deg,#850018,#d9183b)!important;
        color:#fff!important;
      }
      .ms-download .ms-name,.ms-download .ms-desc{color:#fff}
      .ms-download .ms-desc{opacity:.78}
      .ms-download .ms-icon{
        background:rgba(255,255,255,.15);color:#fff;
      }
      .ms-download .ms-arrow{color:#fff}
      .ms-version{
        padding:4px 0 2px;text-align:center;color:#939aa6;
        font-size:9px;line-height:1.45;
      }
      html.maranatha-reduce-motion *,html.maranatha-reduce-motion *::before,
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

    let notificationText = "À vérifier";
    if (nativeApp) {
      notificationText = "Android";
    } else if ("Notification" in window) {
      const labels = {
        granted: "Autorisées",
        denied: "Bloquées",
        default: "À autoriser"
      };
      notificationText = labels[Notification.permission] || "À vérifier";
    } else {
      notificationText = "Non disponible";
    }

    return `
      <div class="ms-wrap">

        <div>
          <div class="ms-section-title">Compte</div>
          <div class="ms-box">
            <button class="ms-row" id="ms-profile" type="button">
              <span class="ms-icon">${icon('<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Mon profil</span>
                <span class="ms-desc">Nom, téléphone, e-mail et informations du compte</span>
              </span>
              <span class="ms-arrow">›</span>
            </button>
          </div>
        </div>

        <div>
          <div class="ms-section-title">Notifications et réveil</div>
          <div class="ms-box">
            <button class="ms-row" id="ms-notifications" type="button">
              <span class="ms-icon">${icon('<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Notifications</span>
                <span class="ms-desc">Autorisation pour recevoir les annonces Maranatha</span>
              </span>
              <span class="ms-value" id="ms-notification-value">${notificationText}</span>
            </button>

            <div class="ms-row">
              <span class="ms-icon">${icon('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Réveil Maranatha</span>
                <span class="ms-desc">Les horaires sont programmés par l’administration de l’église</span>
              </span>
              <span class="ms-value">Automatique</span>
            </div>

            <div class="ms-row">
              <span class="ms-icon">${icon('<path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Audio en arrière-plan</span>
                <span class="ms-desc">Le système audio existant reste inchangé</span>
              </span>
              <span class="ms-value">Actif</span>
            </div>
          </div>
        </div>

        <div>
          <div class="ms-section-title">Affichage</div>
          <div class="ms-box">
            <div class="ms-row">
              <span class="ms-icon">${icon('<path d="M4 4h16v12H4z"/><path d="M8 20h8"/><path d="M12 16v4"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Réduire les animations</span>
                <span class="ms-desc">Diminue les mouvements de l’interface</span>
              </span>
              <button class="ms-toggle ${reduceMotion ? "on" : ""}" id="ms-motion" type="button" aria-pressed="${reduceMotion ? "true" : "false"}"><span></span></button>
            </div>
          </div>
        </div>

        <div>
          <div class="ms-section-title">Application</div>
          <div class="ms-box">
            <button class="ms-row ms-download" id="ms-download" type="button">
              <span class="ms-icon">${icon('<path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Télécharger l’application</span>
                <span class="ms-desc">Installer la version Android de Maranatha</span>
              </span>
              <span class="ms-arrow">›</span>
            </button>

            <button class="ms-row" id="ms-privacy" type="button">
              <span class="ms-icon">${icon('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">Confidentialité et données</span>
                <span class="ms-desc">Consulter la politique de confidentialité</span>
              </span>
              <span class="ms-arrow">›</span>
            </button>

            <button class="ms-row" id="ms-about" type="button">
              <span class="ms-icon">${icon('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>')}</span>
              <span class="ms-copy">
                <span class="ms-name">À propos de Maranatha</span>
                <span class="ms-desc">Informations sur l’application</span>
              </span>
              <span class="ms-arrow">›</span>
            </button>
          </div>
        </div>

        <div class="ms-version">
          MARANATHA — version ${VERSION}<br>
          Communauté des Églises Missionnaires Maranatha
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
