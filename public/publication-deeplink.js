(function () {
  "use strict";

  var TYPES = {
    etude: {
      endpoint: "/api/etudes",
      label: "Nouvelle étude biblique",
      action: "Lire le document"
    },
    priere: {
      endpoint: "/api/prieres",
      label: "Nouvelle prière"
    },
    livre: {
      endpoint: "/api/livres",
      label: "Nouveau livre",
      action: "Ouvrir le livre"
    },
    video: {
      endpoint: "/api/videos",
      label: "Nouvelle vidéo",
      action: "Voir la vidéo"
    },
    bibliotheque: {
      endpoint: "/api/bibliotheque",
      label: "Nouvelle publication",
      action: "Ouvrir la publication"
    }
  };

  function safeUrl(value) {
    try {
      var url = new URL(String(value || ""), location.origin);
      if (url.protocol !== "http:" && url.protocol !== "https:") return "";
      return url.toString();
    } catch (_) {
      return "";
    }
  }

  function publicationId(item) {
    return String(item && (item._id || item.id || item.localId) || "").trim();
  }

  function clearNotificationQuery() {
    var url = new URL(location.href);
    url.searchParams.delete("notification");
    url.searchParams.delete("type");
    url.searchParams.delete("id");
    history.replaceState(null, "", url.pathname + url.search + url.hash);
  }

  function addStyles() {
    if (document.getElementById("mpub-styles")) return;
    var style = document.createElement("style");
    style.id = "mpub-styles";
    style.textContent =
      ".mpub-backdrop{position:fixed;inset:0;z-index:100000;display:flex;align-items:flex-end;justify-content:center;padding:18px;background:rgba(20,4,8,.66);backdrop-filter:blur(8px)}" +
      ".mpub-card{width:min(100%,430px);max-height:88vh;overflow:auto;border-radius:26px 26px 20px 20px;background:#fff;box-shadow:0 24px 70px rgba(0,0,0,.35)}" +
      ".mpub-cover{display:block;width:100%;max-height:250px;object-fit:cover;border-radius:26px 26px 0 0;background:#f2e8ea}" +
      ".mpub-content{padding:22px}.mpub-label{color:#b00020;font-size:12px;font-weight:900;letter-spacing:.08em;text-transform:uppercase}" +
      ".mpub-title{margin:8px 0 10px;color:#25171a;font:700 28px/1.08 Georgia,serif}.mpub-author{margin:-3px 0 13px;color:#76666a;font-weight:700}" +
      ".mpub-text{margin:0;color:#4d4144;font-size:15px;line-height:1.6;white-space:pre-wrap}" +
      ".mpub-actions{display:flex;gap:10px;margin-top:20px}.mpub-button{min-height:46px;display:inline-flex;align-items:center;justify-content:center;padding:0 18px;border-radius:24px;text-decoration:none;font-weight:800}" +
      ".mpub-primary{flex:1;color:#fff;background:#b00020}.mpub-close{color:#720016;background:#f8e9ec}";
    document.head.appendChild(style);
  }

  function renderPublication(item, config) {
    addStyles();

    var backdrop = document.createElement("div");
    backdrop.className = "mpub-backdrop";
    backdrop.setAttribute("role", "dialog");
    backdrop.setAttribute("aria-modal", "true");
    backdrop.setAttribute("aria-label", config.label);

    var card = document.createElement("article");
    card.className = "mpub-card";

    var cover = safeUrl(item.couvertureUrl || item.imageUrl);
    if (cover) {
      var image = document.createElement("img");
      image.className = "mpub-cover";
      image.src = cover;
      image.alt = "";
      card.appendChild(image);
    }

    var content = document.createElement("div");
    content.className = "mpub-content";

    var label = document.createElement("div");
    label.className = "mpub-label";
    label.textContent = config.label;
    content.appendChild(label);

    var title = document.createElement("h2");
    title.className = "mpub-title";
    title.textContent = item.titre || "Publication Maranatha";
    content.appendChild(title);

    if (item.auteur) {
      var author = document.createElement("div");
      author.className = "mpub-author";
      author.textContent = item.auteur;
      content.appendChild(author);
    }

    var description = item.texte || item.description || "";
    if (description) {
      var text = document.createElement("p");
      text.className = "mpub-text";
      text.textContent = description;
      content.appendChild(text);
    }

    var actions = document.createElement("div");
    actions.className = "mpub-actions";

    var target = safeUrl(
      item.pdfUrl ||
      item.youtubeUrl ||
      item.fichierUrl ||
      item.lienExterne
    );
    if (target) {
      var open = document.createElement("a");
      open.className = "mpub-button mpub-primary";
      open.href = target;
      open.textContent = config.action || "Ouvrir";
      actions.appendChild(open);
    }

    var close = document.createElement("button");
    close.className = "mpub-button mpub-close";
    close.type = "button";
    close.textContent = target ? "Fermer" : "Retour";
    close.addEventListener("click", function () {
      backdrop.remove();
    });
    actions.appendChild(close);
    content.appendChild(actions);
    card.appendChild(content);
    backdrop.appendChild(card);
    document.body.appendChild(backdrop);
    clearNotificationQuery();
  }

  async function openNotificationPublication() {
    var params = new URLSearchParams(location.search);
    if (params.get("notification") !== "publication") return;

    var type = String(params.get("type") || "").toLowerCase();
    var id = String(params.get("id") || "").trim();
    var config = TYPES[type];
    if (!config || !id || id.length > 120) {
      clearNotificationQuery();
      return;
    }

    try {
      var response = await fetch(config.endpoint, { cache: "no-store" });
      if (!response.ok) throw new Error("HTTP " + response.status);
      var list = await response.json();
      var item = Array.isArray(list)
        ? list.find(function (entry) {
            return publicationId(entry) === id;
          })
        : null;
      if (!item) throw new Error("PUBLICATION_NOT_FOUND");
      renderPublication(item, config);
    } catch (_) {
      clearNotificationQuery();
      window.alert("Cette publication n’est pas disponible pour le moment.");
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", openNotificationPublication);
  } else {
    openNotificationPublication();
  }
})();