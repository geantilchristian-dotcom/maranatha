(function () {
  "use strict";

  if (window.__maranathaDailyBiblePickerFinal) {
    return;
  }

  window.__maranathaDailyBiblePickerFinal = true;

  const BOOKS = [
    ["GenÃ¨se",50],["Exode",40],["LÃ©vitique",27],["Nombres",36],["DeutÃ©ronome",34],
    ["JosuÃ©",24],["Juges",21],["Ruth",4],["1 Samuel",31],["2 Samuel",24],
    ["1 Rois",22],["2 Rois",25],["1 Chroniques",29],["2 Chroniques",36],
    ["Esdras",10],["NÃ©hÃ©mie",13],["Esther",10],["Job",42],["Psaumes",150],
    ["Proverbes",31],["EcclÃ©siaste",12],["Cantique des cantiques",8],
    ["Ã‰saÃ¯e",66],["JÃ©rÃ©mie",52],["Lamentations",5],["Ã‰zÃ©chiel",48],["Daniel",12],
    ["OsÃ©e",14],["JoÃ«l",3],["Amos",9],["Abdias",1],["Jonas",4],["MichÃ©e",7],
    ["Nahum",3],["Habacuc",3],["Sophonie",3],["AggÃ©e",2],["Zacharie",14],
    ["Malachie",4],["Matthieu",28],["Marc",16],["Luc",24],["Jean",21],
    ["Actes",28],["Romains",16],["1 Corinthiens",16],["2 Corinthiens",13],
    ["Galates",6],["Ã‰phÃ©siens",6],["Philippiens",4],["Colossiens",4],
    ["1 Thessaloniciens",5],["2 Thessaloniciens",3],["1 TimothÃ©e",6],
    ["2 TimothÃ©e",4],["Tite",3],["PhilÃ©mon",1],["HÃ©breux",13],["Jacques",5],
    ["1 Pierre",5],["2 Pierre",3],["1 Jean",5],["2 Jean",1],["3 Jean",1],
    ["Jude",1],["Apocalypse",22]
  ];

  function esc(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function ensureStyle() {
    if (document.getElementById("mdw-picker-style")) return;

    const style = document.createElement("style");
    style.id = "mdw-picker-style";

    style.textContent = `
      .mdw-ref-wrap{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:8px}
      .mdw-ref-btn{min-height:42px;padding:0 14px;border:1px solid rgba(255,255,255,.15);
        border-radius:8px;background:#15384a;color:#fff;font-weight:800;cursor:pointer}
      #mdw-modal{position:fixed;inset:0;z-index:999999;background:rgba(0,10,18,.84);
        display:flex;align-items:center;justify-content:center;padding:18px}
      .mdw-card{width:min(720px,96vw);max-height:90vh;overflow:auto;background:#0d2b3b;
        color:#fff;border-radius:16px;border:1px solid rgba(255,255,255,.13);padding:20px}
      .mdw-head{display:flex;justify-content:space-between;gap:14px;align-items:flex-start;margin-bottom:16px}
      .mdw-head strong{font-size:18px}.mdw-head small{display:block;color:#9eb0bd;margin-top:4px}
      .mdw-close{width:38px;height:38px;border:0;border-radius:9px;background:rgba(255,255,255,.08);
        color:#fff;font-size:22px;cursor:pointer}
      .mdw-grid{display:grid;grid-template-columns:2fr 1fr;gap:10px;margin-bottom:10px}
      .mdw-grid.v{grid-template-columns:1fr 1fr}
      #mdw-modal select{width:100%;min-height:44px;border-radius:9px;padding:0 10px;
        background:#17394b;color:#fff;border:1px solid rgba(255,255,255,.12)}
      .mdw-status{min-height:20px;margin:9px 0;color:#f0d45f;font-size:12px}
      .mdw-preview{min-height:105px;padding:14px;border-radius:10px;background:#071f2d;
        border:1px solid rgba(255,255,255,.08);font-size:13px;line-height:1.6}
      .mdw-actions{display:flex;justify-content:flex-end;gap:9px;margin-top:15px;flex-wrap:wrap}
      .mdw-actions button{min-height:42px;padding:0 16px;border-radius:9px;font-weight:800;cursor:pointer}
      .mdw-cancel{background:transparent;color:#fff;border:1px solid rgba(255,255,255,.15)}
      .mdw-use{background:#c20e28;color:#fff;border:0}.mdw-use:disabled{opacity:.45}
      @media(max-width:560px){.mdw-grid,.mdw-grid.v,.mdw-ref-wrap{grid-template-columns:1fr}}
    `;

    document.head.appendChild(style);
  }

  function enhance() {
    const input =
      document.getElementById("av3-daily-reference");

    if (!input || input.dataset.mdwReady === "1") return;

    input.dataset.mdwReady = "1";
    input.readOnly = true;
    input.style.cursor = "pointer";
    input.placeholder = "Choisir dans la Bible";

    const parent = input.parentElement;
    if (!parent) return;

    const wrap = document.createElement("div");
    wrap.className = "mdw-ref-wrap";

    parent.insertBefore(wrap, input);
    wrap.appendChild(input);

    const button = document.createElement("button");
    button.type = "button";
    button.className = "mdw-ref-btn";
    button.textContent = "Bible";

    wrap.appendChild(button);

    input.addEventListener("click", openPicker);
    button.addEventListener("click", openPicker);
  }

  function openPicker() {
    document.getElementById("mdw-modal")?.remove();

    const modal = document.createElement("div");
    modal.id = "mdw-modal";

    modal.innerHTML = `
      <div class="mdw-card">
        <div class="mdw-head">
          <div>
            <strong>Choisir le passage biblique</strong>
            <small>Livre, chapitre et verset(s)</small>
          </div>
          <button type="button" id="mdw-close" class="mdw-close">Ã—</button>
        </div>

        <div class="mdw-grid">
          <select id="mdw-book"></select>
          <select id="mdw-chapter"></select>
        </div>

        <div class="mdw-grid v">
          <select id="mdw-start"></select>
          <select id="mdw-end"></select>
        </div>

        <div id="mdw-status" class="mdw-status">Chargement...</div>
        <div id="mdw-preview" class="mdw-preview"></div>

        <div class="mdw-actions">
          <button type="button" id="mdw-cancel" class="mdw-cancel">Annuler</button>
          <button type="button" id="mdw-use" class="mdw-use" disabled>
            Utiliser ce passage
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(modal);

    const book = document.getElementById("mdw-book");
    const chapter = document.getElementById("mdw-chapter");
    const start = document.getElementById("mdw-start");
    const end = document.getElementById("mdw-end");
    const status = document.getElementById("mdw-status");
    const preview = document.getElementById("mdw-preview");
    const use = document.getElementById("mdw-use");

    let verses = [];

    book.innerHTML =
      BOOKS.map((x, i) =>
        `<option value="${i + 1}">${esc(x[0])}</option>`
      ).join("");

    const current =
      String(
        document.getElementById("av3-daily-reference")?.value || ""
      ).trim();

    let wantedBook = 1;
    let wantedChapter = 1;
    let wantedStart = 1;
    let wantedEnd = 1;

    BOOKS.forEach((x, i) => {
      if (
        current.toLowerCase().startsWith(
          x[0].toLowerCase() + " "
        )
      ) {
        wantedBook = i + 1;
      }
    });

    const match =
      current.match(/(\d+):(\d+)(?:-(\d+))?$/);

    if (match) {
      wantedChapter = Number(match[1]) || 1;
      wantedStart = Number(match[2]) || 1;
      wantedEnd = Number(match[3] || match[2]) || wantedStart;
    }

    book.value = String(wantedBook);

    function fillChapters(preferred) {
      const count =
        BOOKS[Number(book.value) - 1]?.[1] || 1;

      chapter.innerHTML =
        Array.from(
          { length: count },
          (_, i) =>
            `<option value="${i + 1}">Chapitre ${i + 1}</option>`
        ).join("");

      chapter.value =
        String(
          Math.min(
            Math.max(Number(preferred) || 1, 1),
            count
          )
        );
    }

    function render() {
      if (!verses.length) {
        preview.textContent = "Aucun verset disponible.";
        use.disabled = true;
        return;
      }

      let a = Number(start.value || 1);
      let b = Number(end.value || a);

      if (b < a) {
        b = a;
        end.value = String(a);
      }

      const selected =
        verses.filter(x => {
          const n = Number(x.verse);
          return n >= a && n <= b;
        });

      const name =
        BOOKS[Number(book.value) - 1]?.[0] || "Bible";

      const reference =
        `${name} ${chapter.value}:${a}${b > a ? "-" + b : ""}`;

      preview.innerHTML =
        `<div style="font-weight:800;margin-bottom:8px">${esc(reference)}</div>` +
        selected
          .map(x =>
            `<div style="margin-bottom:6px"><strong style="color:#f0d45f">${esc(x.verse)}</strong> ${esc(x.text || "")}</div>`
          )
          .join("");

      use.dataset.reference = reference;
      use.dataset.text =
        selected
          .map(x =>
            `${String(x.verse)} ${String(x.text || "").trim()}`
          )
          .join("\n");

      use.disabled = selected.length === 0;
    }

    async function loadChapter(a = 1, b = 1) {
      status.textContent = "Chargement du chapitre...";
      preview.textContent = "";
      use.disabled = true;

      try {
        const response =
          await fetch(
            `/api/bible/${book.value}/${chapter.value}?version=FR&ts=${Date.now()}`,
            {
              headers: {
                "Accept": "application/json",
                "Cache-Control": "no-cache"
              }
            }
          );

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        verses =
          Array.isArray(data?.verses)
            ? data.verses
            : [];

        const options =
          verses
            .map(x =>
              `<option value="${esc(x.verse)}">Verset ${esc(x.verse)}</option>`
            )
            .join("");

        start.innerHTML = options;
        end.innerHTML = options;

        if (verses.length) {
          const max =
            Number(
              verses[verses.length - 1].verse
            ) || 1;

          const first =
            Math.min(
              Math.max(Number(a) || 1, 1),
              max
            );

          const last =
            Math.min(
              Math.max(Number(b) || first, first),
              max
            );

          start.value = String(first);
          end.value = String(last);
        }

        status.textContent =
          `${verses.length} verset(s) chargÃ©(s).`;

        render();
      } catch (error) {
        verses = [];
        status.textContent =
          "Impossible de charger ce chapitre : " +
          (error?.message || "erreur");
        preview.textContent = "";
        use.disabled = true;
      }
    }

    fillChapters(wantedChapter);
    loadChapter(wantedStart, wantedEnd);

    book.addEventListener("change", () => {
      fillChapters(1);
      loadChapter(1, 1);
    });

    chapter.addEventListener(
      "change",
      () => loadChapter(1, 1)
    );

    start.addEventListener("change", () => {
      if (Number(end.value) < Number(start.value)) {
        end.value = start.value;
      }
      render();
    });

    end.addEventListener("change", render);

    const close = () => modal.remove();

    document
      .getElementById("mdw-close")
      .addEventListener("click", close);

    document
      .getElementById("mdw-cancel")
      .addEventListener("click", close);

    modal.addEventListener("click", event => {
      if (event.target === modal) close();
    });

    use.addEventListener("click", () => {
      const reference =
        document.getElementById("av3-daily-reference");

      const parole =
        document.getElementById("av3-daily-word");

      if (reference) {
        reference.value =
          use.dataset.reference || "";
      }

      if (parole) {
        parole.value =
          use.dataset.text || "";
      }

      close();
    });
  }

  ensureStyle();
  enhance();

  new MutationObserver(enhance).observe(
    document.body,
    {
      childList: true,
      subtree: true
    }
  );
})();
