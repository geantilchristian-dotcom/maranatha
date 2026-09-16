(function(){

"use strict";

const KEY =
    "maranatha_program_v2";

let editingId =
    null;




/* ==========================================================
   MARANATHA_PROGRAMME_PRODUCTION_SYNC_V1
   MongoDB = source partagee
   localStorage = cache interface
   ========================================================== */

let programmeApiBooted =
  false;


function programmeAuthHeaders() {

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


  try {

    if (
      window.authHeaders &&
      typeof window.authHeaders ===
      "function"
    ) {

      return (
        window.authHeaders() ||
        {}
      );
    }

  } catch (_error) {}


  return {};
}


function normalizeProgrammeItem(
  item,
  index
) {

  item =
    item &&
    typeof item === "object"
      ? item
      : {};


  const fallbackId =
    "programme-" +
    Date.now() +
    "-" +
    index;


  return {

    id:
      String(
        item.id ||
        item._id ||
        fallbackId
      ),

    name:
      String(
        item.name ||
        item.title ||
        item.titre ||
        item.badge ||
        "PROGRAMME"
      ),

    date:
      String(
        item.date ||
        item.dateStr ||
        ""
      ),

    time:
      String(
        item.time ||
        item.heure ||
        item.heureStr ||
        ""
      ),

    location:
      String(
        item.location ||
        item.lieu ||
        ""
      ),

    details:
      String(
        item.details ||
        item.description ||
        ""
      ),

    image:
      String(
        item.image ||
        item.imageUrl ||
        ""
      ),

    active:
      item.active !== false
  };
}


function programmeFingerprint(
  item
) {

  return [
    item.date,
    item.time,
    item.location,
    item.image,
    item.details
  ].join("|");
}


function mergeProgrammeLists(
  remote,
  local
) {

  const result = [];
  const ids = new Set();
  const fingerprints =
    new Set();


  [
    ...(Array.isArray(remote)
      ? remote
      : []),

    ...(Array.isArray(local)
      ? local
      : [])
  ]
  .map(
    normalizeProgrammeItem
  )
  .forEach(
    item => {

      const id =
        String(
          item.id ||
          ""
        );

      const fp =
        programmeFingerprint(
          item
        );


      if (
        id &&
        ids.has(id)
      ) {
        return;
      }


      if (
        fp &&
        fingerprints.has(fp)
      ) {
        return;
      }


      if (id) {
        ids.add(id);
      }


      if (fp) {
        fingerprints.add(fp);
      }


      result.push(
        item
      );
    }
  );


  return result;
}


function toProgrammeApiItem(
  item,
  index
) {

  const clean =
    normalizeProgrammeItem(
      item,
      index
    );


  return {

    id:
      clean.id,

    badge:
      clean.name ||
      "PROGRAMME",

    dateStr:
      clean.date,

    heureStr:
      clean.time,

    lieu:
      clean.location,

    description:
      clean.details,

    imageUrl:
      clean.image,

    active:
      clean.active
  };
}


async function persistProgramsApi(
  data
) {

  const items =
    Array.isArray(data)
      ? data.map(
          toProgrammeApiItem
        )
      : [];


  const response =
    await fetch(
      "/api/settings/programme",
      {
        method:
          "PUT",

        headers: {
          ...programmeAuthHeaders(),

          "Content-Type":
            "application/json"
        },

        body:
          JSON.stringify({
            items
          })
      }
    );


  let result = {};

  try {
    result =
      await response.json();
  } catch (_error) {}


  if (!response.ok) {

    throw new Error(
      result.error ||
      "Synchronisation MongoDB impossible."
    );
  }


  return result;
}


function hydrateProgrammeCache() {

  let local = [];


  try {

    const raw =
      localStorage.getItem(
        KEY
      );


    const parsed =
      raw
        ? JSON.parse(raw)
        : [];


    if (
      Array.isArray(parsed)
    ) {

      local =
        parsed.map(
          normalizeProgrammeItem
        );
    }

  } catch (_error) {}


  try {

    const xhr =
      new XMLHttpRequest();


    xhr.open(
      "GET",
      "/api/settings/programme",
      false
    );


    xhr.send();


    if (
      xhr.status >= 200 &&
      xhr.status < 300
    ) {

      const payload =
        JSON.parse(
          xhr.responseText ||
          "{}"
        );


      const remote =
        Array.isArray(
          payload.items
        )
          ? payload.items.map(
              normalizeProgrammeItem
            )
          : [];


      const merged =
        mergeProgrammeLists(
          remote,
          local
        );


      localStorage.setItem(
        KEY,
        JSON.stringify(
          merged
        )
      );


      if (
        merged.length >
        remote.length
      ) {

        persistProgramsApi(
          merged
        ).catch(
          error => {

            console.error(
              "[MARANATHA Programme migration]",
              error
            );
          }
        );
      }


      return;
    }

  } catch (error) {

    console.warn(
      "[MARANATHA Programme GET]",
      error
    );
  }
}

/* MARANATHA_PROGRAMME_PRODUCTION_SYNC_V1_HELPERS_END */


function readStore(){

    try{

        if(
            !programmeApiBooted
        ){

            programmeApiBooted =
                true;


            hydrateProgrammeCache();
        }


        const raw =
            localStorage.getItem(
                KEY
            );


        if(!raw){
            return [];
        }


        const data =
            JSON.parse(raw);


        if(!Array.isArray(data)){
            return [];
        }


        return data.map(
            normalizeProgrammeItem
        );


    }catch(error){

        console.error(
            "[MARANATHA Programme lecture]",
            error
        );


        return [];
    }
}


function writeStore(data){

    const clean =
        Array.isArray(data)
            ? data.map(
                normalizeProgrammeItem
            )
            : [];


    localStorage.setItem(
        KEY,
        JSON.stringify(
            clean
        )
    );


    window.dispatchEvent(
        new Event(
            "maranatha-program-updated"
        )
    );


    persistProgramsApi(
        clean
    )
    .then(function(){

        console.log(
            "[MARANATHA Programme] MongoDB synchronise"
        );

    })
    .catch(function(error){

        console.error(
            "[MARANATHA Programme MongoDB]",
            error
        );


        alert(
            error.message ||
            "Programme modifie localement mais non synchronise au serveur."
        );
    });
}


function esc(value){

    return String(
        value == null ? "" : value
    )
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;");
}


function makeId(){

    return (
        Date.now().toString(36) +
        Math.random()
            .toString(36)
            .slice(2,7)
    );
}


async function uploadImage(file){

    if(!file){
        return "";
    }


    const form =
        new FormData();


    form.append(
        "image",
        file,
        file.name ||
        "programme.jpg"
    );


    const response =
        await fetch(
            "/api/settings/programme/upload",
            {
                method:"POST",

                headers:
                    programmeAuthHeaders(),

                body:
                    form
            }
        );


    let result = {};


    try{

        result =
            await response.json();

    }catch(_error){}


    if(
        !response.ok ||
        !result.ok
    ){

        throw new Error(
            result.error ||
            "Impossible d'envoyer l'image."
        );
    }


    return result.url;
}


function sortPrograms(list){

    return [...list].sort(
        function(a,b){

            const aDate =
                new Date(
                    (a.date || "9999-12-31") +
                    "T" +
                    (a.time || "23:59")
                );

            const bDate =
                new Date(
                    (b.date || "9999-12-31") +
                    "T" +
                    (b.time || "23:59")
                );

            return aDate - bDate;
        }
    );
}


function formatDate(value){

    if(!value){
        return "Date non précisée";
    }

    try{

        return new Intl.DateTimeFormat(
            "fr-FR",
            {
                weekday:"short",
                day:"2-digit",
                month:"short",
                year:"numeric"
            }
        )
        .format(
            new Date(
                value + "T12:00:00"
            )
        );

    }catch(error){

        return value;
    }
}


function render(){

    const pane =
        document.getElementById(
            "pane-programme"
        );


    if(!pane){
        return;
    }


    const all =
        readStore();


    const list =
        sortPrograms(all);


    const current =
        editingId
            ? all.find(
                function(item){
                    return item.id === editingId;
                }
            )
            : null;


    pane.innerHTML = `
        <div class="prog2">

            <div class="prog2-head">

                <div>

                    <h2 class="prog2-title">
                        Programme
                    </h2>

                    <div class="prog2-sub">
                        Créez et gérez les programmes visibles
                        par les fidèles.
                    </div>

                </div>


                <div class="prog2-state">
                    ● ${list.length} programme(s)
                </div>

            </div>


            <div class="prog2-layout">

                <div class="prog2-card">

                    <div class="prog2-card-title">
                        ${
                            current
                                ? "Modifier le programme"
                                : "Ajouter un programme"
                        }
                    </div>

                    <div class="prog2-card-sub">
                        Les champs marqués optionnels
                        peuvent rester vides.
                    </div>


                    <form id="prog2-form">

                        <div class="prog2-field">

                            <label>
                                Nom du programme
                            </label>

                            <input
                                id="prog2-name"
                                type="text"
                                value="${esc(current?.name || "")}"
                                placeholder="Ex : Culte du dimanche"
                                required>

                        </div>


                        <div class="prog2-row">

                            <div class="prog2-field">

                                <label>
                                    Date
                                </label>

                                <input
                                    id="prog2-date"
                                    type="date"
                                    value="${esc(current?.date || "")}"
                                    required>

                            </div>


                            <div class="prog2-field">

                                <label>
                                    Heure
                                </label>

                                <input
                                    id="prog2-time"
                                    type="time"
                                    value="${esc(current?.time || "")}"
                                    required>

                            </div>

                        </div>


                        <div class="prog2-field">

                            <label>
                                Lieu
                            </label>

                            <input
                                id="prog2-place"
                                type="text"
                                value="${esc(current?.place || "")}"
                                placeholder="Ex : Temple MARANATHA"
                                required>

                        </div>


                        <div class="prog2-field">

                            <label>
                                Thème
                                <span>optionnel</span>
                            </label>

                            <input
                                id="prog2-theme"
                                type="text"
                                value="${esc(current?.theme || "")}"
                                placeholder="Ex : Marcher par la foi">

                        </div>


                        <div class="prog2-field">

                            <label>
                                Détails du programme
                                <span>optionnel</span>
                            </label>

                            <textarea
                                id="prog2-details"
                                placeholder="Informations complémentaires...">${esc(current?.details || "")}</textarea>

                        </div>


                        <div class="prog2-field">

                            <label>
                                Photo de couverture
                                <span>optionnelle</span>
                            </label>

                            <input
                                id="prog2-image"
                                class="prog2-file"
                                type="file"
                                accept="image/*">


                            ${
                                current?.image
                                    ? `
                                        <div class="prog2-preview">

                                            <img
                                                src="${esc(current.image)}"
                                                alt="Couverture">

                                        </div>
                                    `
                                    : ""
                            }

                        </div>


                        <div class="prog2-actions-form">

                            <button
                                class="prog2-primary"
                                type="submit"
                                id="prog2-save">

                                ${
                                    current
                                        ? "Enregistrer"
                                        : "+ Ajouter le programme"
                                }

                            </button>


                            ${
                                current
                                    ? `
                                        <button
                                            type="button"
                                            class="prog2-secondary"
                                            data-prog-cancel>
                                            Annuler
                                        </button>
                                    `
                                    : ""
                            }

                        </div>

                    </form>

                </div>


                <div class="prog2-card">

                    <div class="prog2-card-title">
                        Programmes publiés
                    </div>

                    <div class="prog2-card-sub">
                        Affichage en liste chronologique.
                    </div>


                    <div class="prog2-list">

                        ${
                            list.length
                                ? list.map(
                                    function(item){

                                        return `
                                            <div class="prog2-item">

                                                <div class="prog2-cover">

                                                    ${
                                                        item.image
                                                            ? `
                                                                <img
                                                                    src="${esc(item.image)}"
                                                                    alt="${esc(item.name)}">
                                                            `
                                                            : `
                                                                <div class="prog2-cover-empty">
                                                                    PROGRAMME
                                                                </div>
                                                            `
                                                    }

                                                </div>


                                                <div class="prog2-info">

                                                    <div class="prog2-date">

                                                        ${formatDate(item.date)}

                                                        ${
                                                            item.time
                                                                ? " • " + esc(item.time)
                                                                : ""
                                                        }

                                                    </div>


                                                    <div class="prog2-name">
                                                        ${esc(item.name)}
                                                    </div>


                                                    ${
                                                        item.theme
                                                            ? `
                                                                <div class="prog2-theme">
                                                                    ${esc(item.theme)}
                                                                </div>
                                                            `
                                                            : ""
                                                    }


                                                    <div class="prog2-location">
                                                        ${esc(item.place || "")}
                                                    </div>


                                                    <div class="prog2-status ${
                                                        item.active === false
                                                            ? "off"
                                                            : ""
                                                    }">

                                                        ${
                                                            item.active === false
                                                                ? "Masqué"
                                                                : "Visible"
                                                        }

                                                    </div>

                                                </div>


                                                <div class="prog2-item-actions">

                                                    <button
                                                        type="button"
                                                        class="prog2-secondary"
                                                        data-prog-toggle="${item.id}">

                                                        ${
                                                            item.active === false
                                                                ? "Afficher"
                                                                : "Masquer"
                                                        }

                                                    </button>


                                                    <button
                                                        type="button"
                                                        class="prog2-secondary"
                                                        data-prog-edit="${item.id}">
                                                        Modifier
                                                    </button>


                                                    <button
                                                        type="button"
                                                        class="prog2-secondary prog2-danger"
                                                        data-prog-delete="${item.id}">
                                                        Supprimer
                                                    </button>

                                                </div>

                                            </div>
                                        `;
                                    }
                                ).join("")
                                : `
                                    <div class="prog2-empty">
                                        Aucun programme publié.
                                    </div>
                                `
                        }

                    </div>

                </div>

            </div>

        </div>
    `;


    bind();
}


async function save(event){

    event.preventDefault();


    const name =
        document.getElementById(
            "prog2-name"
        ).value.trim();


    const date =
        document.getElementById(
            "prog2-date"
        ).value;


    const time =
        document.getElementById(
            "prog2-time"
        ).value;


    const place =
        document.getElementById(
            "prog2-place"
        ).value.trim();


    if(
        !name ||
        !date ||
        !time ||
        !place
    ){

        alert(
            "Nom, date, heure et lieu sont obligatoires."
        );

        return;
    }


    const data =
        readStore();


    let item =
        editingId
            ? data.find(
                function(entry){
                    return entry.id === editingId;
                }
            )
            : null;


    if(!item){

        item = {
            id:makeId(),
            active:true
        };

        data.push(item);
    }


    const button =
        document.getElementById(
            "prog2-save"
        );


    button.disabled =
        true;

    button.textContent =
        "Enregistrement...";


    try{

        item.name =
            name;

        item.date =
            date;

        item.time =
            time;

        item.place =
            place;

        item.theme =
            document.getElementById(
                "prog2-theme"
            ).value.trim();

        item.details =
            document.getElementById(
                "prog2-details"
            ).value.trim();


        const imageInput =
            document.getElementById(
                "prog2-image"
            );


        const file =
            imageInput?.files?.[0];


        if(file){

            item.image =
                await uploadImage(file);
        }


        writeStore(data);


        editingId =
            null;


        render();


    }catch(error){

        alert(
            error.message ||
            "Impossible d'enregistrer le programme."
        );


        button.disabled =
            false;

        button.textContent =
            "Enregistrer";
    }
}


function bind(){

    document.getElementById(
        "prog2-form"
    )?.addEventListener(
        "submit",
        save
    );


    document.querySelector(
        "[data-prog-cancel]"
    )?.addEventListener(
        "click",
        function(){

            editingId =
                null;

            render();
        }
    );


    document.querySelectorAll(
        "[data-prog-edit]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    editingId =
                        button.dataset.progEdit;

                    render();
                }
            );
        }
    );


    document.querySelectorAll(
        "[data-prog-toggle]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    const data =
                        readStore();


                    const item =
                        data.find(
                            function(entry){

                                return (
                                    entry.id ===
                                    button.dataset.progToggle
                                );
                            }
                        );


                    if(!item){
                        return;
                    }


                    item.active =
                        item.active === false;


                    writeStore(data);

                    render();
                }
            );
        }
    );


    document.querySelectorAll(
        "[data-prog-delete]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    if(
                        !confirm(
                            "Supprimer ce programme ?"
                        )
                    ){
                        return;
                    }


                    let data =
                        readStore();


                    data =
                        data.filter(
                            function(item){

                                return (
                                    item.id !==
                                    button.dataset.progDelete
                                );
                            }
                        );


                    writeStore(data);


                    if(
                        editingId ===
                        button.dataset.progDelete
                    ){
                        editingId =
                            null;
                    }


                    render();
                }
            );
        }
    );
}


function init(){

    render();
}


if(document.readyState === "loading"){

    document.addEventListener(
        "DOMContentLoaded",
        init
    );

}else{

    init();
}

})();
/* MARANATHA_PROGRAMME_PRODUCTION_SYNC_V1_END */
