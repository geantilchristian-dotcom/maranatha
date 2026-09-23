(function () {
  "use strict";
  const API =
    window.location.origin +
    "/api";
  const root =
    document.getElementById(
      "admin-app-v3-root"
    );
  if (!root) {
    return;
  }
  const state = {
    section:
      "dashboard",
    home: {
      heroBanners: []
    },
    programme: [],
    dailyWord: {
      matin: null,
      soir: null,
      history: []
    },
    sermons: [],
    library: {
      recent: [],
      live: [],
      audio: [],
      video: [],
      book: []
    },
    comments: [],
    dailyPeriod:
      "matin",
    commentFilter:
      "all"
  };
  function esc(value) {
    return String(
      value == null
        ? ""
        : value
    )
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
  }
  function uid(prefix) {
    return (
      String(prefix || "item") +
      "-" +
      Date.now().toString(36) +
      "-" +
      Math.random()
        .toString(36)
        .slice(2, 8)
    );
  }
  function auth() {
    try {
      if (
        typeof window.authHeaders ===
        "function"
      ) {
        return (
          window.authHeaders() ||
          {}
        );
      }
    } catch (_error) {}
    try {
      if (
        typeof authHeaders ===
        "function"
      ) {
        return (
          authHeaders() ||
          {}
        );
      }
    } catch (_error) {}
    return {};
  }
  function jsonHeaders() {
    return {
      ...auth(),
      "Content-Type":
        "application/json",
      "Accept":
        "application/json"
    };
  }
  function toastV3(
    message,
    type
  ) {
    try {
      if (
        typeof window.toast ===
        "function"
      ) {
        window.toast(
          message,
          type || "success"
        );
        return;
      }
    } catch (_error) {}
    console.log(
      "[ADMIN V3]",
      message
    );
  }
  async function api(
    path,
    options
  ) {
    const response =
      await fetch(
        API + path,
        options || {}
      );
    let data =
      null;
    try {
      data =
        await response.json();
    } catch (_error) {}
    if (!response.ok) {
      throw new Error(
        data &&
        data.error
          ? data.error
          : "Erreur serveur."
      );
    }
    return data;
  }
  async function upload(
    file
  ) {
    if (!file) {
      return "";
    }
    const form =
      new FormData();
    form.append(
      "file",
      file
    );
    const response =
      await fetch(
        API +
        "/library/upload",
        {
          method:
            "POST",
          headers:
            auth(),
          body:
            form
        }
      );
    let data =
      {};
    try {
      data =
        await response.json();
    } catch (_error) {}
    if (
      !response.ok ||
      !data.url
    ) {
      throw new Error(
        data.error ||
        "Upload impossible."
      );
    }
    return data.url;
  }
  function icon(
    name
  ) {
    const icons = {
      dashboard:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>',
      home:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/></svg>',
      programme:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4M16 2v4M3 10h18"/></svg>',
      direct:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="2"/><path d="M8.5 8.5a5 5 0 0 0 0 7M15.5 8.5a5 5 0 0 1 0 7"/><path d="M5 5a10 10 0 0 0 0 14M19 5a10 10 0 0 1 0 14"/></svg>',
      word:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M4 4v15.5"/><path d="M6.5 2H20v15H6.5A2.5 2.5 0 0 0 4 19.5V4A2 2 0 0 1 6 2z"/></svg>',
      library:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>',
      comments:
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>'
    };
    return (
      icons[name] ||
      icons.dashboard
    );
  }
  function dateFr(
    value
  ) {
    if (!value) {
      return "";
    }
    const date =
      new Date(value);
    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return String(
        value
      );
    }
    return new Intl.DateTimeFormat(
      "fr-FR",
      {
        day:
          "2-digit",
        month:
          "short",
        year:
          "numeric",
        hour:
          "2-digit",
        minute:
          "2-digit"
      }
    ).format(
      date
    );
  }
  function libraryEmpty() {
    return {
      recent: [],
      live: [],
      audio: [],
      video: [],
      book: []
    };
  }
  function normalizeLibrary(
    value
  ) {
    const out =
      libraryEmpty();
    if (
      !value ||
      typeof value !==
      "object"
    ) {
      return out;
    }
    Object.keys(out)
      .forEach(
        function (
          key
        ) {
          out[key] =
            Array.isArray(
              value[key]
            )
              ? value[key]
              : [];
        }
      );
    return out;
  }
  function syncOldCaches() {
    try {
      localStorage.setItem(
        "maranatha_library_v2",
        JSON.stringify(
          state.library
        )
      );
      localStorage.setItem(
        "maranatha_program_v2",
        JSON.stringify(
          state.programme.map(
            function (
              item
            ) {
              return {
                id:
                  item.id,
                name:
                  item.titre ||
                  item.badge ||
                  "PROGRAMME",
                date:
                  item.dateStr ||
                  "",
                time:
                  item.heureStr ||
                  "",
                location:
                  item.lieu ||
                  "",
                description:
                  item.description ||
                  "",
                image:
                  item.imageUrl ||
                  "",
                pasteur:
                  item.pasteur ||
                  "",
                heureFin:
                  item.heureFin ||
                  "",
                visible:
                  item.visible !==
                  false,
                ordre:
                  Number(
                    item.ordre ||
                    0
                  )
              };
            }
          )
        )
      );
      let media =
        {};
      try {
        media =
          JSON.parse(
            localStorage.getItem(
              "maranatha_media_v2"
            ) ||
            "{}"
          );
      } catch (_error) {
        media =
          {};
      }
      media.banners =
        Array.isArray(
          state.home.heroBanners
        )
          ? state.home.heroBanners
          : [];
      if (
        !Array.isArray(
          media.featuredVideos
        )
      ) {
        media.featuredVideos =
          [];
      }
      if (!media.social) {
        media.social =
          {};
      }
      localStorage.setItem(
        "maranatha_media_v2",
        JSON.stringify(
          media
        )
      );
    } catch (_error) {}
  }
  async function loadAll() {
    const results =
      await Promise.allSettled(
        [
          api(
            "/settings/home"
          ),
          api(
            "/settings/programme"
          ),
          api(
            "/settings/daily-word"
          ),
          api(
            "/sermons"
          ),
          api(
            "/library/state"
          ),
          api(
            "/comments"
          )
        ]
      );
    const [
      home,
      programme,
      daily,
      sermons,
      library,
      comments
    ] =
      results;
    if (
      home.status ===
      "fulfilled"
    ) {
      state.home =
        home.value ||
        {
          heroBanners: []
        };
    }
    if (
      !Array.isArray(
        state.home.heroBanners
      )
    ) {
      state.home.heroBanners =
        [];
    }
    if (
      programme.status ===
      "fulfilled"
    ) {
      state.programme =
        Array.isArray(
          programme.value?.items
        )
          ? programme.value.items
          : [];
    }
    if (
      daily.status ===
      "fulfilled"
    ) {
      state.dailyWord = {
        matin:
          daily.value?.matin ||
          null,
        soir:
          daily.value?.soir ||
          null,
        history:
          Array.isArray(
            daily.value?.history
          )
            ? daily.value.history
            : []
      };
    }
    if (
      sermons.status ===
      "fulfilled"
    ) {
      state.sermons =
        Array.isArray(
          sermons.value
        )
          ? sermons.value
          : [];
    }
    if (
      library.status ===
      "fulfilled"
    ) {
      state.library =
        normalizeLibrary(
          library.value?.value
        );
    }
    if (
      comments.status ===
      "fulfilled"
    ) {
      state.comments =
        Array.isArray(
          comments.value
        )
          ? comments.value
          : [];
    }
    syncOldCaches();
    renderCurrent();
  }
  function shell() {
    root.innerHTML = `
      <div class="av3">
        <div class="av3-shell">
          <aside class="av3-nav">
            <div class="av3-brand">
              <div class="av3-brand-mark">
                ${icon("direct")}
              </div>
              <div>
                <strong>
                  Pilotage App
                </strong>
                <span>
                  MARANATHA V3
                </span>
              </div>
            </div>
            ${navButton(
              "dashboard",
              "Vue générale",
              "dashboard"
            )}
            ${navButton(
              "home",
              "Accueil",
              "home"
            )}
            ${navButton(
              "programme",
              "Programme",
              "programme"
            )}
            ${navButton(
              "direct",
              "Direct",
              "direct"
            )}
            ${navButton(
              "daily",
              "Parole du jour",
              "word"
            )}
            ${navButton(
              "library",
              "Bibliothèque",
              "library"
            )}
            ${navButton(
              "comments",
              "Commentaires",
              "comments"
            )}
          </aside>
          <main class="av3-content">
            <div id="av3-page">
              Chargement…
            </div>
          </main>
        </div>
      </div>
    `;
    root
      .querySelectorAll(
        "[data-av3-nav]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            function () {
              state.section =
                button.dataset.av3Nav;
              root
                .querySelectorAll(
                  "[data-av3-nav]"
                )
                .forEach(
                  function (
                    item
                  ) {
                    item.classList.toggle(
                      "active",
                      item ===
                      button
                    );
                  }
                );
              renderCurrent();
            }
          );
        }
      );
  }
  function navButton(
    key,
    label,
    iconName
  ) {
    return `
      <button
        type="button"
        data-av3-nav="${key}"
        class="${
          state.section === key
            ? "active"
            : ""
        }">
        ${icon(iconName)}
        <span>
          ${esc(label)}
        </span>
      </button>
    `;
  }
  function page() {
    return document.getElementById(
      "av3-page"
    );
  }
  function pageHead(
    title,
    subtitle
  ) {
    return `
      <div class="av3-page-head">
        <div>
          <h2>
            ${esc(title)}
          </h2>
          <p>
            ${esc(subtitle)}
          </p>
        </div>
        <button
          type="button"
          class="av3-refresh"
          id="av3-refresh">
          Actualiser
        </button>
      </div>
    `;
  }
  function wireRefresh() {
    const button =
      document.getElementById(
        "av3-refresh"
      );
    if (!button) {
      return;
    }
    button.addEventListener(
      "click",
      async function () {
        button.disabled =
          true;
        button.textContent =
          "Chargement…";
        try {
          await loadAll();
          toastV3(
            "Données actualisées.",
            "success"
          );
        } catch (error) {
          toastV3(
            error.message,
            "error"
          );
        } finally {
          button.disabled =
            false;
          button.textContent =
            "Actualiser";
        }
      }
    );
  }
  function renderCurrent() {
    switch (
      state.section
    ) {
      case "home":
        renderHome();
        break;
      case "programme":
        renderProgramme();
        break;
      case "direct":
        renderDirect();
        break;
      case "daily":
        renderDaily();
        break;
      case "library":
        renderLibrary();
        break;
      case "comments":
        renderComments();
        break;
      case "dashboard":
      default:
        renderDashboard();
        break;
    }
  }
  // ========================================================
  // DASHBOARD
  // ========================================================
  function renderDashboard() {
    const target =
      page();
    if (!target) {
      return;
    }
    const live =
      state.sermons.find(
        function (
          item
        ) {
          return (
            item.statut ===
            "en_cours"
          );
        }
      );
    const upcoming =
      state.sermons.filter(
        function (
          item
        ) {
          return (
            item.statut ===
            "planifie"
          );
        }
      );
    const libraryCount =
      Object.values(
        state.library
      )
      .reduce(
        function (
          sum,
          list
        ) {
          return (
            sum +
            (
              Array.isArray(list)
                ? list.length
                : 0
            )
          );
        },
        0
      );
    const pendingComments =
      state.comments.filter(
        function (
          item
        ) {
          return (
            !item.traite &&
            !item.adminReponse
          );
        }
      ).length;
    target.innerHTML = `
      ${pageHead(
        "Vue générale",
        "État des contenus visibles dans l'application utilisateur."
      )}
      <div class="av3-grid">
        ${stat(
          live
            ? "1"
            : "0",
          "Direct actif",
          live
            ? live.titre
            : "Aucune diffusion"
        )}
        ${stat(
          String(
            upcoming.length
          ),
          "À venir",
          "Diffusions planifiées"
        )}
        ${stat(
          String(
            libraryCount
          ),
          "Bibliothèque",
          "Contenus disponibles"
        )}
        ${stat(
          String(
            pendingComments
          ),
          "Commentaires",
          "Sans réponse"
        )}
      </div>
      <div class="av3-two">
        <section class="av3-card">
          <div class="av3-card-title">
            <strong>
              Parole du jour
            </strong>
            <span class="av3-status">
              API active
            </span>
          </div>
          ${dailySummary(
            "Matin",
            state.dailyWord.matin
          )}
          ${dailySummary(
            "Soir",
            state.dailyWord.soir
          )}
        </section>
        <section class="av3-card">
          <div class="av3-card-title">
            <strong>
              Prochains programmes
            </strong>
            <span>
              ${state.programme.length}
            </span>
          </div>
          ${
            state.programme.length
              ? state.programme
                  .slice(0, 4)
                  .map(
                    programmeRow
                  )
                  .join("")
              : empty(
                  "Aucun programme publié."
                )
          }
        </section>
      </div>
    `;
    wireRefresh();
  }
  function stat(
    value,
    label,
    sub
  ) {
    return `
      <div class="av3-stat">
        <div class="av3-stat-label">
          ${esc(label)}
        </div>
        <div class="av3-stat-value">
          ${esc(value)}
        </div>
        <div class="av3-stat-sub">
          ${esc(sub)}
        </div>
      </div>
    `;
  }
  function dailySummary(
    label,
    item
  ) {
    return `
      <div class="av3-item">
        <div class="av3-thumb">
          ${icon("word")}
        </div>
        <div class="av3-item-main">
          <div class="av3-item-title">
            ${esc(label)}
          </div>
          <div class="av3-item-meta">
            ${
              item
                ? esc(
                    item.sujet ||
                    "Sans sujet"
                  )
                : "Aucune publication"
            }
          </div>
        </div>
      </div>
    `;
  }
  // ========================================================
  // ACCUEIL
  // ========================================================
  function renderHome() {
    const target =
      page();
    const banners =
      [...state.home.heroBanners]
      .sort(
        function (
          a,
          b
        ) {
          return (
            Number(
              a.ordre ||
              0
            ) -
            Number(
              b.ordre ||
              0
            )
          );
        }
      );
    target.innerHTML = `
      ${pageHead(
        "Accueil & bannières",
        "Contrôle exactement les affiches visibles sur l'accueil."
      )}
      <div class="av3-two">
        <section class="av3-card">
          <div class="av3-card-title">
            <strong>
              Nouvelle bannière
            </strong>
            <span>
              Titre facultatif
            </span>
          </div>
          <form id="av3-banner-form">
            <div class="av3-form-grid">
              <div class="av3-field full">
                <label>
                  Image
                </label>
                <input
                  id="av3-banner-file"
                  type="file"
                  accept="image/*">
              </div>
              <div class="av3-field full">
                <label>
                  Ou URL de l'image
                </label>
                <input
                  id="av3-banner-url"
                  type="url"
                  placeholder="https://...">
              </div>
              <div class="av3-field">
                <label>
                  Titre
                </label>
                <input
                  id="av3-banner-title"
                  type="text"
                  placeholder="Facultatif">
              </div>
              <div class="av3-field">
                <label>
                  Ordre
                </label>
                <input
                  id="av3-banner-order"
                  type="number"
                  value="${banners.length + 1}">
              </div>
              <div class="av3-field full">
                <label>
                  Texte
                </label>
                <textarea
                  id="av3-banner-text"
                  placeholder="Facultatif"></textarea>
              </div>
              <div class="av3-field">
                <label>
                  Bouton
                </label>
                <input
                  id="av3-banner-button"
                  type="text"
                  placeholder="Ex : Découvrir">
              </div>
              <div class="av3-field">
                <label>
                  Lien du bouton
                </label>
                <input
                  id="av3-banner-link"
                  type="text"
                  placeholder="/programme ou https://...">
              </div>
            </div>
            <div class="av3-checks">
              <label class="av3-check">
                <input
                  id="av3-banner-active"
                  type="checkbox"
                  checked>
                Visible
              </label>
            </div>
            <div class="av3-actions">
              <button
                type="submit"
                class="av3-btn primary">
                Publier la bannière
              </button>
            </div>
          </form>
        </section>
        <section class="av3-preview">
          <div class="av3-phone">
            <div class="av3-phone-head">
              EGLISE CEMM MARANATHA
            </div>
            <div class="av3-phone-banner"
                 id="av3-banner-preview">
              <div class="av3-phone-banner-overlay">
                Aperçu
              </div>
            </div>
          </div>
        </section>
      </div>
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Bannières publiées
          </strong>
          <span>
            ${banners.length}
          </span>
        </div>
        <div class="av3-list">
          ${
            banners.length
              ? banners
                  .map(
                    bannerRow
                  )
                  .join("")
              : empty(
                  "Aucune bannière."
                )
          }
        </div>
      </section>
    `;
    wireRefresh();
    wireBannerForm();
    wireBannerRows();
  }
  function bannerRow(
    item
  ) {
    return `
      <div class="av3-item">
        <div class="av3-thumb">
          ${
            item.imageUrl
              ? `<img src="${esc(item.imageUrl)}" alt="">`
              : icon("home")
          }
        </div>
        <div class="av3-item-main">
          <div class="av3-item-title">
            ${
              esc(
                item.title ||
                "Bannière sans titre"
              )
            }
          </div>
          <div class="av3-item-meta">
            Ordre :
            ${Number(
              item.ordre ||
              0
            )}
            ·
            ${
              item.active !== false
                ? "Visible"
                : "Masquée"
            }
          </div>
        </div>
        <div class="av3-item-actions">
          <button
            class="av3-mini"
            data-banner-toggle="${esc(item.id)}">
            ${
              item.active !== false
                ? "Masquer"
                : "Afficher"
            }
          </button>
          <button
            class="av3-mini red"
            data-banner-delete="${esc(item.id)}">
            Supprimer
          </button>
        </div>
      </div>
    `;
  }
  function wireBannerForm() {
    const form =
      document.getElementById(
        "av3-banner-form"
      );
    if (!form) {
      return;
    }
    const file =
      document.getElementById(
        "av3-banner-file"
      );
    const url =
      document.getElementById(
        "av3-banner-url"
      );
    function preview() {
      const box =
        document.getElementById(
          "av3-banner-preview"
        );
      if (!box) {
        return;
      }
      const currentUrl =
        url.value.trim();
      if (file.files[0]) {
        const objectUrl =
          URL.createObjectURL(
            file.files[0]
          );
        box.style.backgroundImage =
          `url("${objectUrl}")`;
        box.style.backgroundSize =
          "cover";
        box.style.backgroundPosition =
          "center";
        return;
      }
      if (currentUrl) {
        box.style.backgroundImage =
          `url("${currentUrl}")`;
        box.style.backgroundSize =
          "cover";
        box.style.backgroundPosition =
          "center";
      } else {
        box.style.backgroundImage =
          "";
      }
    }
    file.addEventListener(
      "change",
      preview
    );
    url.addEventListener(
      "input",
      preview
    );
    form.addEventListener(
      "submit",
      async function (
        event
      ) {
        event.preventDefault();
        const submit =
          form.querySelector(
            'button[type="submit"]'
          );
        submit.disabled =
          true;
        try {
          let imageUrl =
            url.value.trim();
          if (file.files[0]) {
            imageUrl =
              await upload(
                file.files[0]
              );
          }
          if (!imageUrl) {
            throw new Error(
              "Une image est obligatoire."
            );
          }
          const banner = {
            id:
              uid(
                "banner"
              ),
            imageUrl,
            title:
              document
                .getElementById(
                  "av3-banner-title"
                )
                .value
                .trim(),
            text:
              document
                .getElementById(
                  "av3-banner-text"
                )
                .value
                .trim(),
            buttonLabel:
              document
                .getElementById(
                  "av3-banner-button"
                )
                .value
                .trim(),
            link:
              document
                .getElementById(
                  "av3-banner-link"
                )
                .value
                .trim() ||
              "#",
            active:
              document
                .getElementById(
                  "av3-banner-active"
                )
                .checked,
            ordre:
              Number(
                document
                  .getElementById(
                    "av3-banner-order"
                  )
                  .value ||
                0
              )
          };
          const next =
            [
              ...state.home.heroBanners,
              banner
            ];
          const data =
            await api(
              "/settings/home",
              {
                method:
                  "PUT",
                headers:
                  jsonHeaders(),
                body:
                  JSON.stringify({
                    heroBanners:
                      next
                  })
              }
            );
          state.home =
            data;
          syncOldCaches();
          toastV3(
            "Bannière publiée.",
            "success"
          );
          renderHome();
        } catch (error) {
          toastV3(
            error.message,
            "error"
          );
        } finally {
          submit.disabled =
            false;
        }
      }
    );
  }
  function wireBannerRows() {
    document
      .querySelectorAll(
        "[data-banner-delete]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              if (
                !confirm(
                  "Supprimer cette bannière ?"
                )
              ) {
                return;
              }
              const id =
                button.dataset.bannerDelete;
              const next =
                state.home.heroBanners
                .filter(
                  function (
                    item
                  ) {
                    return (
                      String(
                        item.id
                      ) !==
                      String(id)
                    );
                  }
                );
              const data =
                await api(
                  "/settings/home",
                  {
                    method:
                      "PUT",
                    headers:
                      jsonHeaders(),
                    body:
                      JSON.stringify({
                        heroBanners:
                          next
                      })
                  }
                );
              state.home =
                data;
              syncOldCaches();
              renderHome();
            }
          );
        }
      );
    document
      .querySelectorAll(
        "[data-banner-toggle]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              const id =
                button.dataset.bannerToggle;
              const next =
                state.home.heroBanners
                .map(
                  function (
                    item
                  ) {
                    if (
                      String(
                        item.id
                      ) ===
                      String(id)
                    ) {
                      return {
                        ...item,
                        active:
                          item.active ===
                          false
                      };
                    }
                    return item;
                  }
                );
              const data =
                await api(
                  "/settings/home",
                  {
                    method:
                      "PUT",
                    headers:
                      jsonHeaders(),
                    body:
                      JSON.stringify({
                        heroBanners:
                          next
                      })
                  }
                );
              state.home =
                data;
              syncOldCaches();
              renderHome();
            }
          );
        }
      );
  }
  // ========================================================
  // PROGRAMME
  // ========================================================
  function renderProgramme() {
    const target =
      page();
    target.innerHTML = `
      ${pageHead(
        "Programme",
        "Événements visibles sur l'accueil et dans l'onglet Programme."
      )}
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Ajouter un programme
          </strong>
          <span>
            Tous les champs utilisateur
          </span>
        </div>
        <form id="av3-programme-form">
          <div class="av3-form-grid">
            <div class="av3-field">
              <label>
                Titre *
              </label>
              <input
                id="av3-program-title"
                required
                type="text">
            </div>
            <div class="av3-field">
              <label>
                Type
              </label>
              <select id="av3-program-type">
                <option value="CULTE">
                  Culte
                </option>
                <option value="PREDICATION">
                  Prédication
                </option>
                <option value="ETUDE">
                  Étude biblique
                </option>
                <option value="PRIERE">
                  Prière
                </option>
                <option value="CONFERENCE">
                  Conférence
                </option>
                <option value="AUTRE">
                  Autre
                </option>
              </select>
            </div>
            <div class="av3-field">
              <label>
                Date *
              </label>
              <input
                id="av3-program-date"
                required
                type="date">
            </div>
            <div class="av3-field">
              <label>
                Début *
              </label>
              <input
                id="av3-program-time"
                required
                type="time">
            </div>
            <div class="av3-field">
              <label>
                Fin
              </label>
              <input
                id="av3-program-end"
                type="time">
            </div>
            <div class="av3-field">
              <label>
                Intervenant
              </label>
              <input
                id="av3-program-pastor"
                type="text"
                placeholder="Pasteur...">
            </div>
            <div class="av3-field full">
              <label>
                Lieu
              </label>
              <input
                id="av3-program-place"
                type="text">
            </div>
            <div class="av3-field full">
              <label>
                Description
              </label>
              <textarea
                id="av3-program-description"></textarea>
            </div>
            <div class="av3-field">
              <label>
                Image
              </label>
              <input
                id="av3-program-image"
                type="file"
                accept="image/*">
            </div>
            <div class="av3-field">
              <label>
                Ordre
              </label>
              <input
                id="av3-program-order"
                type="number"
                value="${state.programme.length + 1}">
            </div>
          </div>
          <div class="av3-checks">
            <label class="av3-check">
              <input
                id="av3-program-visible"
                type="checkbox"
                checked>
              Visible
            </label>
          </div>
          <div class="av3-actions">
            <button
              type="submit"
              class="av3-btn primary">
              Publier le programme
            </button>
          </div>
        </form>
      </section>
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Programmes publiés
          </strong>
          <span>
            ${state.programme.length}
          </span>
        </div>
        <div class="av3-list">
          ${
            state.programme.length
              ? state.programme
                  .map(
                    programmeRow
                  )
                  .join("")
              : empty(
                  "Aucun programme."
                )
          }
        </div>
      </section>
    `;
    wireRefresh();
    wireProgrammeForm();
    wireProgrammeRows();
  }
  function programmeRow(
    item
  ) {
    return `
      <div class="av3-item">
        <div class="av3-thumb">
          ${
            item.imageUrl
              ? `<img src="${esc(item.imageUrl)}" alt="">`
              : icon("programme")
          }
        </div>
        <div class="av3-item-main">
          <div class="av3-item-title">
            ${esc(
              item.titre ||
              item.badge ||
              "Programme"
            )}
          </div>
          <div class="av3-item-meta">
            ${esc(
              item.dateStr ||
              ""
            )}
            ${
              item.heureStr
                ? " · " +
                  esc(
                    item.heureStr
                  )
                : ""
            }
            ${
              item.heureFin
                ? " - " +
                  esc(
                    item.heureFin
                  )
                : ""
            }
            ${
              item.pasteur
                ? "<br>" +
                  esc(
                    item.pasteur
                  )
                : ""
            }
          </div>
        </div>
        <div class="av3-item-actions">
          <button
            class="av3-mini red"
            data-program-delete="${esc(item.id)}">
            Supprimer
          </button>
        </div>
      </div>
    `;
  }
  function wireProgrammeForm() {
    const form =
      document.getElementById(
        "av3-programme-form"
      );
    if (!form) {
      return;
    }
    form.addEventListener(
      "submit",
      async function (
        event
      ) {
        event.preventDefault();
        const button =
          form.querySelector(
            'button[type="submit"]'
          );
        button.disabled =
          true;
        try {
          const imageFile =
            document
              .getElementById(
                "av3-program-image"
              )
              .files[0];
          const imageUrl =
            imageFile
              ? await upload(
                  imageFile
                )
              : "";
          const type =
            document
              .getElementById(
                "av3-program-type"
              )
              .value;
          const item = {
            id:
              uid(
                "programme"
              ),
            titre:
              document
                .getElementById(
                  "av3-program-title"
                )
                .value
                .trim(),
            badge:
              type,
            type,
            dateStr:
              document
                .getElementById(
                  "av3-program-date"
                )
                .value,
            heureStr:
              document
                .getElementById(
                  "av3-program-time"
                )
                .value,
            heureFin:
              document
                .getElementById(
                  "av3-program-end"
                )
                .value,
            lieu:
              document
                .getElementById(
                  "av3-program-place"
                )
                .value
                .trim(),
            pasteur:
              document
                .getElementById(
                  "av3-program-pastor"
                )
                .value
                .trim(),
            description:
              document
                .getElementById(
                  "av3-program-description"
                )
                .value
                .trim(),
            imageUrl,
            statut:
              "planifie",
            cible:
              "programme",
            visible:
              document
                .getElementById(
                  "av3-program-visible"
                )
                .checked,
            ordre:
              Number(
                document
                  .getElementById(
                    "av3-program-order"
                  )
                  .value ||
                0
              )
          };
          if (
            !item.titre ||
            !item.dateStr ||
            !item.heureStr
          ) {
            throw new Error(
              "Titre, date et heure obligatoires."
            );
          }
          const next =
            [
              ...state.programme,
              item
            ];
          const data =
            await api(
              "/settings/programme",
              {
                method:
                  "PUT",
                headers:
                  jsonHeaders(),
                body:
                  JSON.stringify({
                    items:
                      next
                  })
              }
            );
          state.programme =
            data.items ||
            [];
          syncOldCaches();
          toastV3(
            "Programme publié.",
            "success"
          );
          renderProgramme();
        } catch (error) {
          toastV3(
            error.message,
            "error"
          );
        } finally {
          button.disabled =
            false;
        }
      }
    );
  }
  function wireProgrammeRows() {
    document
      .querySelectorAll(
        "[data-program-delete]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              if (
                !confirm(
                  "Supprimer ce programme ?"
                )
              ) {
                return;
              }
              const id =
                button.dataset.programDelete;
              const next =
                state.programme
                .filter(
                  function (
                    item
                  ) {
                    return (
                      String(
                        item.id
                      ) !==
                      String(id)
                    );
                  }
                );
              const data =
                await api(
                  "/settings/programme",
                  {
                    method:
                      "PUT",
                    headers:
                      jsonHeaders(),
                    body:
                      JSON.stringify({
                        items:
                          next
                      })
                  }
                );
              state.programme =
                data.items ||
                [];
              syncOldCaches();
              renderProgramme();
            }
          );
        }
      );
  }
  // ========================================================
  // DIRECT
  // ========================================================
  function renderDirect() {
    const target =
      page();
    const sorted =
      [...state.sermons]
      .sort(
        function (
          a,
          b
        ) {
          return (
            new Date(
              b.dateDiffusion ||
              0
            ) -
            new Date(
              a.dateDiffusion ||
              0
            )
          );
        }
      );
    target.innerHTML = `
      ${pageHead(
        "Direct",
        "Prépare, démarre et termine les diffusions visibles dans la nouvelle interface."
      )}
      <div class="av3-two">
        <section class="av3-card">
          <div class="av3-card-title">
            <strong>
              Nouvelle diffusion
            </strong>
            <span>
              Audio obligatoire
            </span>
          </div>
          <form id="av3-direct-form">
            <div class="av3-form-grid">
              <div class="av3-field full">
                <label>
                  Titre *
                </label>
                <input
                  id="av3-direct-title"
                  required
                  type="text"
                  placeholder="Ex : Culte dominical">
              </div>
              <div class="av3-field">
                <label>
                  Pasteur / intervenant
                </label>
                <input
                  id="av3-direct-pastor"
                  type="text">
              </div>
              <div class="av3-field">
                <label>
                  Thème
                </label>
                <input
                  id="av3-direct-theme"
                  type="text">
              </div>
              <div class="av3-field">
                <label>
                  Date et heure de début *
                </label>
                <input
                  id="av3-direct-start"
                  required
                  type="datetime-local">
              </div>
              <div class="av3-field">
                <label>
                  Date et heure de fin
                </label>
                <input
                  id="av3-direct-end"
                  type="datetime-local">
              </div>
              <div class="av3-field full">
                <label>
                  Lieu
                </label>
                <input
                  id="av3-direct-place"
                  type="text">
              </div>
              <div class="av3-field full">
                <label>
                  Description
                </label>
                <textarea
                  id="av3-direct-description"></textarea>
              </div>
              <div class="av3-field">
                <label>
                  Image / affiche
                </label>
                <input
                  id="av3-direct-image"
                  type="file"
                  accept="image/*">
              </div>
              <div class="av3-field">
                <label>
                  Audio *
                </label>
                <input
                  id="av3-direct-audio"
                  required
                  type="file"
                  accept="audio/*,.mp3,.m4a,.ogg,.wav,.aac">
              </div>
            </div>
            <div class="av3-checks">
              <label class="av3-check">
                <input
                  id="av3-direct-visible"
                  type="checkbox"
                  checked>
                Visible
              </label>
            </div>
            <div class="av3-actions">
              <button
                type="submit"
                class="av3-btn primary">
                Planifier la diffusion
              </button>
            </div>
          </form>
        </section>
        <section class="av3-preview">
          <div class="av3-phone">
            <div class="av3-phone-head">
              DIRECT
            </div>
            <div class="av3-phone-banner">
              <div class="av3-phone-banner-overlay">
                Aperçu du direct
              </div>
            </div>
            <div style="
              padding:10px 2px 2px;
              font-size:12px;
              font-weight:800;">
              Le contenu publié apparaîtra ici.
            </div>
          </div>
        </section>
      </div>
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Diffusions
          </strong>
          <span>
            ${sorted.length}
          </span>
        </div>
        <div class="av3-list">
          ${
            sorted.length
              ? sorted
                  .map(
                    directRow
                  )
                  .join("")
              : empty(
                  "Aucune diffusion."
                )
          }
        </div>
      </section>
    `;
    wireRefresh();
    wireDirectForm();
    wireDirectRows();
  }
  function directRow(
    item
  ) {
    const status =
      item.statut ||
      "planifie";
    return `
      <div class="av3-item">
        <div class="av3-thumb">
          ${
            item.imageUrl
              ? `<img src="${esc(item.imageUrl)}" alt="">`
              : icon("direct")
          }
        </div>
        <div class="av3-item-main">
          <div class="av3-item-title">
            ${esc(
              item.titre ||
              "Direct MARANATHA"
            )}
          </div>
          <div class="av3-item-meta">
            ${
              esc(
                item.pasteur ||
                ""
              )
            }
            ${
              item.pasteur
                ? "<br>"
                : ""
            }
            ${dateFr(
              item.dateDiffusion
            )}
          </div>
          <div style="margin-top:6px">
            <span class="av3-badge ${
              status === "en_cours"
                ? "live"
                : status === "termine"
                    ? "done"
                    : "future"
            }">
              ${
                status === "en_cours"
                  ? "En direct"
                  : status === "termine"
                      ? "Terminé"
                      : "Planifié"
              }
            </span>
          </div>
        </div>
        <div class="av3-item-actions">
          ${
            status ===
            "planifie"
              ? `
                <button
                  class="av3-mini green"
                  data-direct-start="${esc(item._id)}">
                  Démarrer
                </button>
              `
              : ""
          }
          ${
            status ===
            "en_cours"
              ? `
                <button
                  class="av3-mini red"
                  data-direct-stop="${esc(item._id)}">
                  Arrêter
                </button>
              `
              : ""
          }
          <button
            class="av3-mini red"
            data-direct-delete="${esc(item._id)}">
            Supprimer
          </button>
        </div>
      </div>
    `;
  }
  function wireDirectForm() {
    const form =
      document.getElementById(
        "av3-direct-form"
      );
    if (!form) {
      return;
    }
    form.addEventListener(
      "submit",
      async function (
        event
      ) {
        event.preventDefault();
        const submit =
          form.querySelector(
            'button[type="submit"]'
          );
        submit.disabled =
          true;
        try {
          const audio =
            document
              .getElementById(
                "av3-direct-audio"
              )
              .files[0];
          if (!audio) {
            throw new Error(
              "Choisissez le fichier audio."
            );
          }
          const image =
            document
              .getElementById(
                "av3-direct-image"
              )
              .files[0];
          const imageUrl =
            image
              ? await upload(
                  image
                )
              : "";
          const start =
            document
              .getElementById(
                "av3-direct-start"
              )
              .value;
          const end =
            document
              .getElementById(
                "av3-direct-end"
              )
              .value;
          const startDate =
            new Date(
              start
            );
          if (
            Number.isNaN(
              startDate.getTime()
            )
          ) {
            throw new Error(
              "Date de début invalide."
            );
          }
          const data =
            new FormData();
          data.append(
            "titre",
            document
              .getElementById(
                "av3-direct-title"
              )
              .value
              .trim()
          );
          data.append(
            "description",
            document
              .getElementById(
                "av3-direct-description"
              )
              .value
              .trim()
          );
          data.append(
            "pasteur",
            document
              .getElementById(
                "av3-direct-pastor"
              )
              .value
              .trim()
          );
          data.append(
            "theme",
            document
              .getElementById(
                "av3-direct-theme"
              )
              .value
              .trim()
          );
          data.append(
            "lieu",
            document
              .getElementById(
                "av3-direct-place"
              )
              .value
              .trim()
          );
          data.append(
            "imageUrl",
            imageUrl
          );
          data.append(
            "dateDiffusion",
            startDate.toISOString()
          );
          data.append(
            "heure",
            start
              .split("T")[1] ||
            ""
          );
          data.append(
            "visible",
            document
              .getElementById(
                "av3-direct-visible"
              )
              .checked
              ? "true"
              : "false"
          );
          if (end) {
            const endDate =
              new Date(
                end
              );
            if (
              !Number.isNaN(
                endDate.getTime()
              )
            ) {
              data.append(
                "dateFin",
                endDate.toISOString()
              );
              data.append(
                "heureFin",
                end
                  .split("T")[1] ||
                ""
              );
            }
          }
          data.append(
            "audio",
            audio,
            audio.name
          );
          const response =
            await fetch(
              API +
              "/sermons/schedule",
              {
                method:
                  "POST",
                headers:
                  auth(),
                body:
                  data
              }
            );
          let result =
            {};
          try {
            result =
              await response.json();
          } catch (_error) {}
          if (!response.ok) {
            throw new Error(
              result.error ||
              "Planification impossible."
            );
          }
          toastV3(
            "Diffusion planifiée.",
            "success"
          );
          await loadAll();
        } catch (error) {
          toastV3(
            error.message,
            "error"
          );
        } finally {
          submit.disabled =
            false;
        }
      }
    );
  }
  function wireDirectRows() {
    document
      .querySelectorAll(
        "[data-direct-start]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              await api(
                "/sermons/" +
                encodeURIComponent(
                  button.dataset.directStart
                ) +
                "/start",
                {
                  method:
                    "PATCH",
                  headers:
                    auth()
                }
              );
              toastV3(
                "Direct démarré.",
                "success"
              );
              await loadAll();
            }
          );
        }
      );
    document
      .querySelectorAll(
        "[data-direct-stop]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              await api(
                "/sermons/" +
                encodeURIComponent(
                  button.dataset.directStop
                ) +
                "/stop",
                {
                  method:
                    "PATCH",
                  headers:
                    auth()
                }
              );
              toastV3(
                "Direct terminé.",
                "success"
              );
              await loadAll();
            }
          );
        }
      );
    document
      .querySelectorAll(
        "[data-direct-delete]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              if (
                !confirm(
                  "Supprimer cette diffusion ?"
                )
              ) {
                return;
              }
              await api(
                "/sermons/" +
                encodeURIComponent(
                  button.dataset.directDelete
                ),
                {
                  method:
                    "DELETE",
                  headers:
                    auth()
                }
              );
              await loadAll();
            }
          );
        }
      );
  }
  // ========================================================
  // PAROLE DU JOUR
  // ========================================================
  function renderDaily() {
    const target =
      page();
    const current =
      state.dailyWord[
        state.dailyPeriod
      ];
    target.innerHTML = `
      ${pageHead(
        "Parole du jour",
        "Publication indépendante du matin et du soir, avec historique automatique."
      )}
      <div class="av3-tabs">
        <button
          type="button"
          data-daily-period="matin"
          class="${
            state.dailyPeriod ===
            "matin"
              ? "active"
              : ""
          }">
          Matin
        </button>
        <button
          type="button"
          data-daily-period="soir"
          class="${
            state.dailyPeriod ===
            "soir"
              ? "active"
              : ""
          }">
          Soir
        </button>
      </div>
      <div class="av3-two">
        <section class="av3-card">
          <div class="av3-card-title">
            <strong>
              Publication ${
                state.dailyPeriod ===
                "matin"
                  ? "du matin"
                  : "du soir"
              }
            </strong>
            <span>
              ${
                current
                  ? "Publication existante"
                  : "Nouvelle"
              }
            </span>
          </div>
          <form id="av3-daily-form">
            <div class="av3-form-grid">
              <div class="av3-field">
                <label>
                  Date *
                </label>
                <input
                  id="av3-daily-date"
                  required
                  type="date"
                  value="${esc(
                    current?.date ||
                    new Date()
                      .toISOString()
                      .slice(0,10)
                  )}">
              </div>
              <div class="av3-field">
                <label>
                  Référence
                </label>
                <input
                  id="av3-daily-reference"
                  type="text"
                  value="${esc(
                    current?.reference ||
                    ""
                  )}"
                  placeholder="Ex : Hébreux 11:1">
              </div>
              <div class="av3-field full">
                <label>
                  Sujet *
                </label>
                <input
                  id="av3-daily-subject"
                  required
                  type="text"
                  value="${esc(
                    current?.sujet ||
                    ""
                  )}"
                  placeholder="La foi qui transforme">
              </div>
              <div class="av3-field full">
                <label>
                  Parole *
                </label>
                <textarea
                  id="av3-daily-word"
                  required>${esc(
                    current?.parole ||
                    current?.text ||
                    ""
                  )}</textarea>
              </div>
              <div class="av3-field full">
                <label>
                  Explication
                </label>
                <textarea
                  id="av3-daily-explanation"
                  style="min-height:150px">${esc(
                    current?.explication ||
                    ""
                  )}</textarea>
              </div>
            </div>
            <div class="av3-checks">
              <label class="av3-check">
                <input
                  id="av3-daily-active"
                  type="checkbox"
                  ${
                    current?.active ===
                    false
                      ? ""
                      : "checked"
                  }>
                Visible
              </label>
              <label class="av3-check">
                <input
                  id="av3-daily-notify"
                  type="checkbox">
                Envoyer une notification
              </label>
            </div>
            <div class="av3-actions">
              <button
                type="submit"
                class="av3-btn primary">
                Publier ${
                  state.dailyPeriod ===
                  "matin"
                    ? "le matin"
                    : "le soir"
                }
              </button>
            </div>
          </form>
        </section>
        <section class="av3-preview">
          <div class="av3-phone">
            <div class="av3-phone-head">
              PAROLE DU JOUR
            </div>
            <div style="
              padding:13px 4px;
              color:#c20e28;
              font-size:9px;
              font-weight:800;">
              ${
                state.dailyPeriod ===
                "matin"
                  ? "MATIN"
                  : "SOIR"
              }
            </div>
            <div style="
              padding:0 4px;
              font-size:17px;
              font-weight:800;
              color:#081d43;">
              ${
                esc(
                  current?.sujet ||
                  "Sujet du jour"
                )
              }
            </div>
            <div style="
              margin:12px 4px;
              padding:12px;
              border-left:3px solid #c20e28;
              background:#fff2f4;
              border-radius:7px;
              font-size:10px;
              line-height:1.5;">
              ${
                esc(
                  current?.parole ||
                  current?.text ||
                  "La Parole apparaîtra ici."
                )
              }
            </div>
          </div>
        </section>
      </div>
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Historique
          </strong>
          <span>
            ${state.dailyWord.history.length}
          </span>
        </div>
        <div class="av3-list av3-history">
          ${
            state.dailyWord.history.length
              ? state.dailyWord.history
                  .map(
                    dailyHistoryRow
                  )
                  .join("")
              : empty(
                  "Aucune ancienne publication."
                )
          }
        </div>
      </section>
    `;
    wireRefresh();
    wireDailyTabs();
    wireDailyForm();
  }
  function dailyHistoryRow(
    item
  ) {
    return `
      <div class="av3-item">
        <div class="av3-thumb">
          ${icon("word")}
        </div>
        <div class="av3-item-main">
          <div class="av3-item-title">
            ${esc(
              item.sujet ||
              "Parole du jour"
            )}
          </div>
          <div class="av3-item-meta">
            ${esc(
              item.period ===
              "soir"
                ? "Soir"
                : "Matin"
            )}
            ·
            ${esc(
              item.date ||
              ""
            )}
            ${
              item.reference
                ? "<br>" +
                  esc(
                    item.reference
                  )
                : ""
            }
          </div>
        </div>
      </div>
    `;
  }
  function wireDailyTabs() {
    document
      .querySelectorAll(
        "[data-daily-period]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            function () {
              state.dailyPeriod =
                button.dataset.dailyPeriod;
              renderDaily();
            }
          );
        }
      );
  }
  function wireDailyForm() {
    const form =
      document.getElementById(
        "av3-daily-form"
      );
    if (!form) {
      return;
    }
    form.addEventListener(
      "submit",
      async function (
        event
      ) {
        event.preventDefault();
        const submit =
          form.querySelector(
            'button[type="submit"]'
          );
        submit.disabled =
          true;
        try {
          const existing =
            state.dailyWord[
              state.dailyPeriod
            ];
          const publication = {
            id:
              existing?.id ||
              uid(
                state.dailyPeriod
              ),
            date:
              document
                .getElementById(
                  "av3-daily-date"
                )
                .value,
            sujet:
              document
                .getElementById(
                  "av3-daily-subject"
                )
                .value
                .trim(),
            parole:
              document
                .getElementById(
                  "av3-daily-word"
                )
                .value
                .trim(),
            reference:
              document
                .getElementById(
                  "av3-daily-reference"
                )
                .value
                .trim(),
            explication:
              document
                .getElementById(
                  "av3-daily-explanation"
                )
                .value
                .trim(),
            active:
              document
                .getElementById(
                  "av3-daily-active"
                )
                .checked,
            publishedAt:
              new Date()
                .toISOString()
          };
          const data =
            await api(
              "/settings/daily-word",
              {
                method:
                  "PUT",
                headers:
                  jsonHeaders(),
                body:
                  JSON.stringify({
                    period:
                      state.dailyPeriod,
                    publication,
                    notify:
                      document
                        .getElementById(
                          "av3-daily-notify"
                        )
                        .checked
                  })
              }
            );
          state.dailyWord =
            data.dailyWord;
          toastV3(
            "Parole publiée.",
            "success"
          );
          renderDaily();
        } catch (error) {
          toastV3(
            error.message,
            "error"
          );
        } finally {
          submit.disabled =
            false;
        }
      }
    );
  }
  // ========================================================
  // BIBLIOTHEQUE
  // ========================================================
  function renderLibrary() {
    const target =
      page();
    const all =
      [
        ...state.library.book,
        ...state.library.live,
        ...state.library.audio,
        ...state.library.video
      ];
    target.innerHTML = `
      ${pageHead(
        "Bibliothèque",
        "MongoDB est la source partagée ; le stockage local devient seulement un cache."
      )}
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Ajouter un contenu
          </strong>
          <span>
            Livre · Prédication · Audio · Vidéo
          </span>
        </div>
        <form id="av3-library-form">
          <div class="av3-form-grid">
            <div class="av3-field">
              <label>
                Type *
              </label>
              <select id="av3-library-type">
                <option value="book">
                  Livre
                </option>
                <option value="live">
                  Prédication
                </option>
                <option value="audio">
                  Audio
                </option>
                <option value="video">
                  Vidéo
                </option>
              </select>
            </div>
            <div class="av3-field">
              <label>
                Titre *
              </label>
              <input
                id="av3-library-title"
                required
                type="text">
            </div>
            <div class="av3-field">
              <label>
                Auteur / intervenant
              </label>
              <input
                id="av3-library-author"
                type="text">
            </div>
            <div class="av3-field">
              <label>
                Catégorie
              </label>
              <input
                id="av3-library-category"
                type="text"
                placeholder="Général">
            </div>
            <div class="av3-field full">
              <label>
                Résumé
              </label>
              <textarea
                id="av3-library-description"></textarea>
            </div>
            <div class="av3-field">
              <label>
                Couverture
              </label>
              <input
                id="av3-library-cover"
                type="file"
                accept="image/*">
            </div>
            <div class="av3-field">
              <label>
                Ou URL couverture
              </label>
              <input
                id="av3-library-cover-url"
                type="url">
            </div>
            <div class="av3-field">
              <label>
                Fichier
              </label>
              <input
                id="av3-library-file"
                type="file"
                accept="audio/*,video/*,application/pdf">
            </div>
            <div class="av3-field">
              <label>
                Ou URL du contenu
              </label>
              <input
                id="av3-library-media-url"
                type="url">
            </div>
            <div class="av3-field">
              <label>
                Ordre
              </label>
              <input
                id="av3-library-order"
                type="number"
                value="${all.length + 1}">
            </div>
          </div>
          <div class="av3-checks">
            <label class="av3-check">
              <input
                id="av3-library-download"
                type="checkbox"
                checked>
              Téléchargeable
            </label>
            <label class="av3-check">
              <input
                id="av3-library-new"
                type="checkbox"
                checked>
              Afficher dans Nouveautés
            </label>
            <label class="av3-check">
              <input
                id="av3-library-visible"
                type="checkbox"
                checked>
              Visible
            </label>
            <label class="av3-check">
              <input
                id="av3-library-comments"
                type="checkbox"
                checked>
              Autoriser commentaires
            </label>
            <label class="av3-check">
              <input
                id="av3-library-notify"
                type="checkbox">
              Envoyer notification
            </label>
          </div>
          <div class="av3-actions">
            <button
              type="submit"
              class="av3-btn primary">
              Publier dans la bibliothèque
            </button>
          </div>
        </form>
      </section>
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Contenus publiés
          </strong>
          <span>
            ${all.length}
          </span>
        </div>
        <div class="av3-list">
          ${
            all.length
              ? all
                  .map(
                    libraryRow
                  )
                  .join("")
              : empty(
                  "Aucun contenu."
                )
          }
        </div>
      </section>
    `;
    wireRefresh();
    wireLibraryForm();
    wireLibraryRows();
  }
  function libraryRow(
    item
  ) {
    const id =
      item.id ||
      item._id ||
      "";
    const type =
      item.type ||
      item.kind ||
      "book";
    return `
      <div class="av3-item">
        <div class="av3-thumb">
          ${
            item.image ||
            item.imageUrl ||
            item.cover ||
            item.couvertureUrl
              ? `
                <img
                  src="${esc(
                    item.image ||
                    item.imageUrl ||
                    item.cover ||
                    item.couvertureUrl
                  )}"
                  alt="">
              `
              : icon("library")
          }
        </div>
        <div class="av3-item-main">
          <div class="av3-item-title">
            ${esc(
              item.title ||
              item.titre ||
              "Publication"
            )}
          </div>
          <div class="av3-item-meta">
            ${esc(
              item.author ||
              item.auteur ||
              ""
            )}
            ${
              item.author ||
              item.auteur
                ? "<br>"
                : ""
            }
            ${esc(
              type
            )}
          </div>
        </div>
        <div class="av3-item-actions">
          <button
            class="av3-mini red"
            data-library-delete="${esc(id)}"
            data-library-type="${esc(type)}">
            Supprimer
          </button>
        </div>
      </div>
    `;
  }
  function wireLibraryForm() {
    const form =
      document.getElementById(
        "av3-library-form"
      );
    if (!form) {
      return;
    }
    form.addEventListener(
      "submit",
      async function (
        event
      ) {
        event.preventDefault();
        const submit =
          form.querySelector(
            'button[type="submit"]'
          );
        submit.disabled =
          true;
        try {
          const type =
            document
              .getElementById(
                "av3-library-type"
              )
              .value;
          const title =
            document
              .getElementById(
                "av3-library-title"
              )
              .value
              .trim();
          if (!title) {
            throw new Error(
              "Le titre est obligatoire."
            );
          }
          const coverFile =
            document
              .getElementById(
                "av3-library-cover"
              )
              .files[0];
          const mediaFile =
            document
              .getElementById(
                "av3-library-file"
              )
              .files[0];
          let coverUrl =
            document
              .getElementById(
                "av3-library-cover-url"
              )
              .value
              .trim();
          let mediaUrl =
            document
              .getElementById(
                "av3-library-media-url"
              )
              .value
              .trim();
          if (coverFile) {
            coverUrl =
              await upload(
                coverFile
              );
          }
          if (mediaFile) {
            mediaUrl =
              await upload(
                mediaFile
              );
          }
          if (!mediaUrl) {
            throw new Error(
              "Ajoutez un fichier ou un lien."
            );
          }
          const id =
            uid(
              type
            );
          const item = {
            id,
            _id:
              id,
            type,
            kind:
              type,
            titre:
              title,
            title:
              title,
            auteur:
              document
                .getElementById(
                  "av3-library-author"
                )
                .value
                .trim(),
            author:
              document
                .getElementById(
                  "av3-library-author"
                )
                .value
                .trim(),
            categorie:
              document
                .getElementById(
                  "av3-library-category"
                )
                .value
                .trim() ||
              "Général",
            description:
              document
                .getElementById(
                  "av3-library-description"
                )
                .value
                .trim(),
            image:
              coverUrl,
            imageUrl:
              coverUrl,
            cover:
              coverUrl,
            couvertureUrl:
              coverUrl,
            url:
              mediaUrl,
            fichierUrl:
              mediaUrl,
            telechargeable:
              document
                .getElementById(
                  "av3-library-download"
                )
                .checked,
            commentsEnabled:
              document
                .getElementById(
                  "av3-library-comments"
                )
                .checked,
            active:
              document
                .getElementById(
                  "av3-library-visible"
                )
                .checked,
            actif:
              document
                .getElementById(
                  "av3-library-visible"
                )
                .checked,
            ordre:
              Number(
                document
                  .getElementById(
                    "av3-library-order"
                  )
                  .value ||
                0
              ),
            createdAt:
              new Date()
                .toISOString()
          };
          const next =
            JSON.parse(
              JSON.stringify(
                state.library
              )
            );
          next[type] =
            [
              item,
              ...(
                Array.isArray(
                  next[type]
                )
                  ? next[type]
                  : []
              )
            ];
          if (
            document
              .getElementById(
                "av3-library-new"
              )
              .checked
          ) {
            next.recent =
              [
                item,
                ...(
                  Array.isArray(
                    next.recent
                  )
                    ? next.recent
                    : []
                )
              ];
          }
          const notify =
            document
              .getElementById(
                "av3-library-notify"
              )
              .checked;
          const result =
            await api(
              "/library/state",
              {
                method:
                  "PUT",
                headers:
                  jsonHeaders(),
                body:
                  JSON.stringify({
                    value:
                      next,
                    notifyItem:
                      notify
                        ? {
                            id,
                            titre:
                              title
                          }
                        : null
                  })
              }
            );
          state.library =
            normalizeLibrary(
              result.value
            );
          syncOldCaches();
          toastV3(
            "Contenu publié.",
            "success"
          );
          renderLibrary();
        } catch (error) {
          toastV3(
            error.message,
            "error"
          );
        } finally {
          submit.disabled =
            false;
        }
      }
    );
  }
  function wireLibraryRows() {
    document
      .querySelectorAll(
        "[data-library-delete]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              if (
                !confirm(
                  "Supprimer ce contenu ?"
                )
              ) {
                return;
              }
              const id =
                button.dataset.libraryDelete;
              const next =
                JSON.parse(
                  JSON.stringify(
                    state.library
                  )
                );
              Object.keys(
                next
              )
              .forEach(
                function (
                  key
                ) {
                  next[key] =
                    (
                      next[key] ||
                      []
                    )
                    .filter(
                      function (
                        item
                      ) {
                        return (
                          String(
                            item.id ||
                            item._id ||
                            ""
                          ) !==
                          String(id)
                        );
                      }
                    );
                }
              );
              const result =
                await api(
                  "/library/state",
                  {
                    method:
                      "PUT",
                    headers:
                      jsonHeaders(),
                    body:
                      JSON.stringify({
                        value:
                          next
                      })
                  }
                );
              state.library =
                normalizeLibrary(
                  result.value
                );
              syncOldCaches();
              renderLibrary();
            }
          );
        }
      );
  }
  // ========================================================
  // COMMENTAIRES
  // ========================================================
  function renderComments() {
    const target =
      page();
    const list =
      state.comments.filter(
        function (
          item
        ) {
          if (
            state.commentFilter ===
            "all"
          ) {
            return true;
          }
          return (
            item.section ===
            state.commentFilter
          );
        }
      );
    target.innerHTML = `
      ${pageHead(
        "Commentaires",
        "Commentaires de la Parole, des livres et de la communauté."
      )}
      <div class="av3-tabs">
        ${commentFilterButton(
          "all",
          "Tous"
        )}
        ${commentFilterButton(
          "parole",
          "Parole du jour"
        )}
        ${commentFilterButton(
          "livre",
          "Livres"
        )}
        ${commentFilterButton(
          "communaute",
          "Communauté"
        )}
      </div>
      <section class="av3-card">
        <div class="av3-card-title">
          <strong>
            Messages
          </strong>
          <span>
            ${list.length}
          </span>
        </div>
        <div class="av3-list">
          ${
            list.length
              ? list
                  .map(
                    commentRow
                  )
                  .join("")
              : empty(
                  "Aucun commentaire."
                )
          }
        </div>
      </section>
    `;
    wireRefresh();
    wireCommentFilters();
    wireCommentRows();
  }
  function commentFilterButton(
    key,
    label
  ) {
    return `
      <button
        type="button"
        data-comment-filter="${key}"
        class="${
          state.commentFilter ===
          key
            ? "active"
            : ""
        }">
        ${esc(label)}
      </button>
    `;
  }
  function commentRow(
    item
  ) {
    return `
      <div class="av3-comment">
        <div class="av3-comment-head">
          <div>
            <div class="av3-comment-author">
              ${esc(
                item.auteur ||
                "Utilisateur MARANATHA"
              )}
            </div>
            <div class="av3-comment-date">
              ${dateFr(
                item.dateEnvoi
              )}
              ·
              ${esc(
                item.section ||
                "communaute"
              )}
              ${
                item.periode
                  ? " · " +
                    esc(
                      item.periode
                    )
                  : ""
              }
            </div>
          </div>
          <span class="av3-badge ${
            item.traite ||
            item.adminReponse
              ? "done"
              : "future"
          }">
            ${
              item.traite ||
              item.adminReponse
                ? "Traité"
                : "À répondre"
            }
          </span>
        </div>
        ${
          item.publicationTitre
            ? `
              <div style="
                margin-top:7px;
                color:#d9e2ea;
                font-size:9px;
                font-weight:700;">
                ${esc(
                  item.publicationTitre
                )}
              </div>
            `
            : ""
        }
        <div class="av3-comment-text">
          ${esc(
            item.texte ||
            ""
          )}
        </div>
        ${
          item.adminReponse
            ? `
              <div class="av3-comment-reply">
                <strong>
                  CEMM MARANATHA
                </strong>
                <br>
                ${esc(
                  item.adminReponse
                )}
              </div>
            `
            : ""
        }
        <div class="av3-actions">
          <button
            class="av3-mini green"
            data-comment-reply="${esc(item._id)}">
            Répondre
          </button>
          <button
            class="av3-mini"
            data-comment-status="${esc(item._id)}"
            data-current="${
              item.traite ===
              true
                ? "1"
                : "0"
            }">
            ${
              item.traite ===
              true
                ? "Marquer non traité"
                : "Marquer traité"
            }
          </button>
          <button
            class="av3-mini red"
            data-comment-delete="${esc(item._id)}">
            Supprimer
          </button>
        </div>
      </div>
    `;
  }
  function wireCommentFilters() {
    document
      .querySelectorAll(
        "[data-comment-filter]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            function () {
              state.commentFilter =
                button.dataset.commentFilter;
              renderComments();
            }
          );
        }
      );
  }
  function wireCommentRows() {
    document
      .querySelectorAll(
        "[data-comment-reply]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              const response =
                prompt(
                  "Réponse de CEMM MARANATHA :"
                );
              if (
                response ===
                null
              ) {
                return;
              }
              const result =
                await api(
                  "/comments/" +
                  encodeURIComponent(
                    button.dataset.commentReply
                  ) +
                  "/reply",
                  {
                    method:
                      "PATCH",
                    headers:
                      jsonHeaders(),
                    body:
                      JSON.stringify({
                        reponse:
                          response.trim()
                      })
                  }
                );
              const index =
                state.comments
                .findIndex(
                  function (
                    item
                  ) {
                    return (
                      String(
                        item._id
                      ) ===
                      String(
                        result._id
                      )
                    );
                  }
                );
              if (
                index >=
                0
              ) {
                state.comments[index] =
                  result;
              }
              renderComments();
            }
          );
        }
      );
    document
      .querySelectorAll(
        "[data-comment-status]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              const next =
                button.dataset.current !==
                "1";
              await api(
                "/comments/" +
                encodeURIComponent(
                  button.dataset.commentStatus
                ) +
                "/status",
                {
                  method:
                    "PATCH",
                  headers:
                    jsonHeaders(),
                  body:
                    JSON.stringify({
                      traite:
                        next
                    })
                }
              );
              await loadAll();
            }
          );
        }
      );
    document
      .querySelectorAll(
        "[data-comment-delete]"
      )
      .forEach(
        function (
          button
        ) {
          button.addEventListener(
            "click",
            async function () {
              if (
                !confirm(
                  "Supprimer ce commentaire ?"
                )
              ) {
                return;
              }
              await api(
                "/comments/" +
                encodeURIComponent(
                  button.dataset.commentDelete
                ),
                {
                  method:
                    "DELETE",
                  headers:
                    auth()
                }
              );
              await loadAll();
            }
          );
        }
      );
  }
  function empty(
    text
  ) {
    return `
      <div class="av3-empty">
        ${esc(text)}
      </div>
    `;
  }
  // ========================================================
  // INITIALISATION
  // ========================================================
  shell();
  const pilotageTab =
    document.querySelector(
      '[data-tab="pilotage"]'
    );
  if (pilotageTab) {
    pilotageTab.addEventListener(
      "click",
      function () {
        loadAll()
          .catch(
            function (
              error
            ) {
              toastV3(
                error.message,
                "error"
              );
            }
          );
      }
    );
  }
  // Permet à l'ancien login d'appeler aussi le module V3.
  window.AdminAppV3 = {
    load:
      loadAll,
    show:
      function (
        section
      ) {
        state.section =
          section ||
          "dashboard";
        shell();
        renderCurrent();
      }
  };
  renderDashboard();
})();