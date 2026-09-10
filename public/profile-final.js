(function () {
  "use strict";

  const STYLE_ID = "maranatha-profile-final-style";
  const STORAGE_KEYS = {
    nom: "maranatha_nom",
    postNom: "maranatha_postnom",
    prenom: "maranatha_prenom",
    telephone: "maranatha_tel",
    email: "maranatha_email",
    eglise: "maranatha_eglise",
    photo: "maranatha_photo",
    statut: "maranatha_statut"
  };

  function injectStyles() {
    if (document.getElementById(STYLE_ID)) return;

    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `
      .pf-overlay{
        position:fixed; inset:0; z-index:99999; display:none;
        align-items:flex-start; justify-content:center;
        padding:12px; overflow-y:auto;
        background:rgba(15,23,42,.18);
      }
      .pf-overlay.visible{display:flex}
      .pf-card{
        width:100%; max-width:500px; margin:0 auto;
        max-height:calc(100dvh - 24px); overflow:hidden;
        display:flex; flex-direction:column;
        background:#f7f8fb; border-radius:22px;
        box-shadow:0 18px 48px rgba(0,0,0,.22);
      }
      .pf-header{
        flex:0 0 auto; min-height:70px; padding:14px 16px;
        display:flex; align-items:center; justify-content:space-between;
        gap:12px; color:#fff;
        background:linear-gradient(135deg,#720013,#b50024);
      }
      .pf-brand{
        margin-bottom:2px; font-size:9px; font-weight:800;
        opacity:.75; letter-spacing:1.2px;
      }
      .pf-title{font-size:20px; line-height:1.1; font-weight:900}
      .pf-close{
        width:40px; height:40px; flex:0 0 40px;
        display:grid; place-items:center; border-radius:50%;
        border:1px solid rgba(255,255,255,.18);
        background:rgba(255,255,255,.1); color:#fff;
        font-size:25px; cursor:pointer;
      }
      .pf-body{
        min-height:0; overflow-y:auto; padding:14px;
        overscroll-behavior:contain;
      }
      .pf-photo-wrap{text-align:center; margin:2px 0 14px}
      .pf-avatar{
        width:74px; height:74px; margin:0 auto;
        display:flex; align-items:center; justify-content:center;
        overflow:hidden; border-radius:50%;
        background:#fff0f2; color:#b0001b;
        border:3px solid #fff;
        box-shadow:0 4px 14px rgba(0,0,0,.10);
        font-size:28px; font-weight:900;
      }
      .pf-avatar img{width:100%;height:100%;object-fit:cover}
      .pf-photo-btn{
        margin-top:6px; border:0; background:none;
        color:#a5001a; font-size:11px; font-weight:900; cursor:pointer;
      }
      .pf-grid{display:grid;grid-template-columns:1fr 1fr;gap:9px}
      .pf-field{display:grid;gap:5px;margin-bottom:10px}
      .pf-label{font-size:10px;font-weight:800;color:#5c6678}
      .pf-input{
        width:100%; height:46px; box-sizing:border-box;
        border:1px solid #dfe5ed; border-radius:14px;
        padding:0 13px; outline:none; background:#fff;
        color:#172033; font-size:13px;
      }
      .pf-input:focus{
        border-color:#bc1734;
        box-shadow:0 0 0 3px rgba(188,23,52,.09);
      }
      .pf-input[readonly]{background:#f1f3f6;color:#6d7685}
      .pf-hint{margin-top:-5px;font-size:9px;color:#8b94a3}
      .pf-status{
        display:flex; align-items:center; justify-content:space-between;
        gap:12px; padding:11px 13px; margin:2px 0 12px;
        background:#fff; border:1px solid #e3e7ed; border-radius:14px;
      }
      .pf-status-label{font-size:11px;font-weight:800;color:#5f6878}
      .pf-status-badge{
        padding:6px 10px; border-radius:20px;
        background:#fff0f2; color:#b0001b;
        font-size:10px; font-weight:900;
      }
      .pf-message{
        display:none; margin-bottom:10px; padding:10px 12px;
        border-radius:12px; font-size:11px; line-height:1.4;
      }
      .pf-message.show{display:block}
      .pf-message.success{
        color:#11633a;background:#eaf8f0;border:1px solid #c9ead8;
      }
      .pf-message.error{
        color:#8b1728;background:#fff0f2;border:1px solid #f4ccd4;
      }
      .pf-save,.pf-logout{
        width:100%; min-height:46px; border-radius:14px;
        font-size:12px; font-weight:900; cursor:pointer;
      }
      .pf-save{
        border:0; color:#fff;
        background:linear-gradient(135deg,#850018,#d9183b);
        box-shadow:0 7px 17px rgba(148,0,28,.18);
      }
      .pf-logout{
        margin-top:9px; border:1px solid #e8bcc4;
        color:#a5001a; background:#fff;
      }
      @media(max-width:390px){
        .pf-grid{grid-template-columns:1fr}
      }
    `;
    document.head.appendChild(style);
  }

  function safe(value) {
    return String(value == null ? "" : value).trim();
  }

  function readLegacyProfile() {
    try {
      return JSON.parse(localStorage.getItem("maranatha_profile") || "{}");
    } catch (_) {
      return {};
    }
  }

  function getProfile() {
    const legacy = readLegacyProfile();
    const telephoneRaw =
      localStorage.getItem(STORAGE_KEYS.telephone) ||
      legacy.telephone ||
      "";

    return {
      nom:
        localStorage.getItem(STORAGE_KEYS.nom) ||
        legacy.nom ||
        "",
      postNom:
        localStorage.getItem(STORAGE_KEYS.postNom) || "",
      prenom:
        localStorage.getItem(STORAGE_KEYS.prenom) || "",
      telephone:
        /^anon-/i.test(telephoneRaw) ? "" : telephoneRaw,
      email:
        localStorage.getItem(STORAGE_KEYS.email) ||
        legacy.email ||
        "",
      eglise:
        localStorage.getItem(STORAGE_KEYS.eglise) || "",
      statut:
        localStorage.getItem(STORAGE_KEYS.statut) || "Fidèle",
      photo:
        localStorage.getItem(STORAGE_KEYS.photo) || ""
    };
  }

  function initials(profile) {
    const letters =
      (safe(profile.prenom).charAt(0) + safe(profile.nom).charAt(0))
        .toUpperCase();
    return letters || "M";
  }

  function createModal() {
    if (document.getElementById("profile-final-overlay")) return;

    const overlay = document.createElement("div");
    overlay.id = "profile-final-overlay";
    overlay.className = "pf-overlay";
    overlay.innerHTML = `
      <section class="pf-card" role="dialog" aria-modal="true" aria-labelledby="pf-title">
        <header class="pf-header">
          <div>
            <div class="pf-brand">MARANATHA</div>
            <div class="pf-title" id="pf-title">Mon profil</div>
          </div>
          <button class="pf-close" id="pf-close" type="button" aria-label="Fermer">&times;</button>
        </header>

        <div class="pf-body">
          <div class="pf-photo-wrap">
            <div class="pf-avatar" id="pf-avatar">M</div>
            <button class="pf-photo-btn" id="pf-photo-button" type="button">Modifier la photo</button>
            <input id="pf-photo-input" type="file" accept="image/*" hidden>
          </div>

          <div class="pf-message" id="pf-message"></div>

          <div class="pf-grid">
            <div class="pf-field">
              <label class="pf-label" for="pf-nom">Nom</label>
              <input class="pf-input" id="pf-nom" type="text" autocomplete="family-name">
            </div>
            <div class="pf-field">
              <label class="pf-label" for="pf-postnom">Post-nom</label>
              <input class="pf-input" id="pf-postnom" type="text">
            </div>
          </div>

          <div class="pf-field">
            <label class="pf-label" for="pf-prenom">Prénom</label>
            <input class="pf-input" id="pf-prenom" type="text" autocomplete="given-name">
          </div>

          <div class="pf-field">
            <label class="pf-label" for="pf-tel">Téléphone</label>
            <input class="pf-input" id="pf-tel" type="tel" inputmode="tel" placeholder="+243...">
            <div class="pf-hint" id="pf-phone-hint"></div>
          </div>

          <div class="pf-field">
            <label class="pf-label" for="pf-email">E-mail (facultatif)</label>
            <input class="pf-input" id="pf-email" type="email" autocomplete="email" placeholder="exemple@email.com">
          </div>

          <div class="pf-field">
            <label class="pf-label" for="pf-eglise">Église / Assemblée (facultatif)</label>
            <input class="pf-input" id="pf-eglise" type="text" placeholder="Votre assemblée">
          </div>

          <div class="pf-status">
            <div class="pf-status-label">Statut du compte</div>
            <div class="pf-status-badge" id="pf-status">Fidèle</div>
          </div>

          <button class="pf-save" id="pf-save" type="button">Enregistrer les modifications</button>
          <button class="pf-logout" id="pf-logout" type="button">Se déconnecter</button>
        </div>
      </section>
    `;

    document.body.appendChild(overlay);

    overlay.addEventListener("click", function (event) {
      if (event.target === overlay) close();
    });
    document.getElementById("pf-close").addEventListener("click", close);
    document.getElementById("pf-photo-button").addEventListener("click", function () {
      document.getElementById("pf-photo-input").click();
    });
    document.getElementById("pf-photo-input").addEventListener("change", changePhoto);
    document.getElementById("pf-save").addEventListener("click", save);
    document.getElementById("pf-logout").addEventListener("click", logout);
  }

  function setMessage(text, type) {
    const box = document.getElementById("pf-message");
    if (!box) return;
    if (!text) {
      box.className = "pf-message";
      box.textContent = "";
      return;
    }
    box.className = "pf-message show " + (type || "success");
    box.textContent = text;
  }

  function renderAvatar(profile) {
    const avatar = document.getElementById("pf-avatar");
    if (!avatar) return;

    if (profile.photo) {
      const img = document.createElement("img");
      img.src = profile.photo;
      img.alt = "Photo de profil";
      avatar.replaceChildren(img);
    } else {
      avatar.textContent = initials(profile);
    }
  }

  function fill() {
    const profile = getProfile();
    document.getElementById("pf-nom").value = profile.nom;
    document.getElementById("pf-postnom").value = profile.postNom;
    document.getElementById("pf-prenom").value = profile.prenom;
    document.getElementById("pf-tel").value = profile.telephone;
    document.getElementById("pf-email").value = profile.email;
    document.getElementById("pf-eglise").value = profile.eglise;
    document.getElementById("pf-status").textContent = profile.statut;

    const memberId = safe(localStorage.getItem("maranatha_membre_id"));
    const phone = document.getElementById("pf-tel");
    const hint = document.getElementById("pf-phone-hint");

    phone.readOnly = Boolean(memberId);
    hint.textContent = memberId
      ? "Le numéro du compte ne peut pas être modifié depuis le profil."
      : "";

    renderAvatar(profile);
  }

  function open() {
    createModal();
    fill();
    setMessage("");
    document.getElementById("profile-final-overlay").classList.add("visible");
    document.body.style.overflow = "hidden";
  }

  function close() {
    const overlay = document.getElementById("profile-final-overlay");
    if (overlay) overlay.classList.remove("visible");
    document.body.style.overflow = "";
  }

  function changePhoto(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setMessage("Veuillez choisir une image.", "error");
      return;
    }

    const reader = new FileReader();
    reader.onload = function (readerEvent) {
      const img = new Image();
      img.onload = function () {
        const canvas = document.createElement("canvas");
        const size = 320;
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext("2d");
        const side = Math.min(img.width, img.height);
        const sx = (img.width - side) / 2;
        const sy = (img.height - side) / 2;

        ctx.drawImage(img, sx, sy, side, side, 0, 0, size, size);

        try {
          localStorage.setItem(
            STORAGE_KEYS.photo,
            canvas.toDataURL("image/jpeg", 0.82)
          );
          fill();
        } catch (_) {
          setMessage("Cette photo est trop lourde pour être enregistrée.", "error");
        }
      };
      img.src = readerEvent.target.result;
    };
    reader.readAsDataURL(file);
  }

  async function save() {
    const profile = {
      nom: safe(document.getElementById("pf-nom").value),
      postNom: safe(document.getElementById("pf-postnom").value),
      prenom: safe(document.getElementById("pf-prenom").value),
      telephone: safe(document.getElementById("pf-tel").value),
      email: safe(document.getElementById("pf-email").value),
      eglise: safe(document.getElementById("pf-eglise").value)
    };

    if (!profile.nom) {
      setMessage("Le nom est requis.", "error");
      document.getElementById("pf-nom").focus();
      return;
    }
    if (!profile.prenom) {
      setMessage("Le prénom est requis.", "error");
      document.getElementById("pf-prenom").focus();
      return;
    }
    if (!profile.telephone) {
      setMessage("Le numéro de téléphone est requis.", "error");
      document.getElementById("pf-tel").focus();
      return;
    }

    localStorage.setItem(STORAGE_KEYS.nom, profile.nom);
    localStorage.setItem(STORAGE_KEYS.postNom, profile.postNom);
    localStorage.setItem(STORAGE_KEYS.prenom, profile.prenom);
    localStorage.setItem(STORAGE_KEYS.telephone, profile.telephone);
    localStorage.setItem(STORAGE_KEYS.email, profile.email);
    localStorage.setItem(STORAGE_KEYS.eglise, profile.eglise);
    localStorage.setItem(
      "maranatha_user",
      [profile.prenom, profile.postNom, profile.nom].filter(Boolean).join(" ")
    );
    localStorage.setItem(
      "maranatha_profile",
      JSON.stringify({
        nom: [profile.prenom, profile.postNom, profile.nom].filter(Boolean).join(" "),
        telephone: profile.telephone,
        email: profile.email
      })
    );

    const memberId = safe(localStorage.getItem("maranatha_membre_id"));
    if (memberId) {
      try {
        const response = await fetch("/api/membres/" + encodeURIComponent(memberId), {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            nom: profile.nom,
            postNom: profile.postNom,
            prenom: profile.prenom,
            email: profile.email
          })
        });

        if (response.ok) {
          const data = await response.json().catch(function () { return {}; });
          if (data && data.statut) {
            const labels = {
              accepte: "Membre",
              en_attente: "En attente",
              refuse: "Refusé"
            };
            localStorage.setItem(
              STORAGE_KEYS.statut,
              labels[data.statut] || "Fidèle"
            );
          }
        }
      } catch (_) {
        // Le profil reste enregistré localement lorsque le serveur est indisponible.
      }
    }

    setMessage("Profil enregistré avec succès.", "success");
    fill();
  }

  function logout() {
    if (!window.confirm("Voulez-vous vraiment vous déconnecter ?")) return;

    [
      "maranatha_auth_done",
      "maranatha_membre_id",
      "maranatha_prenom",
      "maranatha_nom",
      "maranatha_postnom",
      "maranatha_tel",
      "maranatha_user",
      "maranatha_profile",
      "maranatha_email",
      "maranatha_eglise",
      "maranatha_statut"
    ].forEach(function (key) {
      localStorage.removeItem(key);
    });

    window.location.reload();
  }

  window.ouvrirProfilFinal = open;
  window.fermerProfilFinal = close;

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      injectStyles();
      createModal();
    }, { once: true });
  } else {
    injectStyles();
    createModal();
  }
})();
