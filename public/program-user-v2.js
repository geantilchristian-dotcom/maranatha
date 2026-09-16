(function(){

"use strict";

const KEY =
    "maranatha_program_v2";


let selectedProgramId =
    null;


/* ==========================================================
   DONNEES
   ========================================================== */

function readPrograms(){

    try{

        const raw =
            localStorage.getItem(KEY);


        if(!raw){
            return [];
        }


        const data =
            JSON.parse(raw);


        if(!Array.isArray(data)){
            return [];
        }


        return data
            .filter(function(item){

                return (
                    item &&
                    item.active !== false
                );

            })
            .sort(function(a,b){

                const da =
                    new Date(
                        (a.date || "9999-12-31") +
                        "T" +
                        (a.time || "23:59")
                    );


                const db =
                    new Date(
                        (b.date || "9999-12-31") +
                        "T" +
                        (b.time || "23:59")
                    );


                return da - db;
            });


    }catch(error){

        console.error(
            "[MARANATHA Programme]",
            error
        );


        return [];
    }
}


function esc(value){

    return String(
        value == null
            ? ""
            : value
    )
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;");
}


function formatDate(value){

    if(!value){
        return "";
    }


    try{

        return new Intl.DateTimeFormat(
            "fr-FR",
            {
                weekday:"long",
                day:"2-digit",
                month:"long",
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


/* ==========================================================
   FENETRE MARANATHA
   ========================================================== */

function getSheetBody(){

    return (
        document.getElementById(
            "m-sheet-body"
        ) ||
        document.querySelector(
            ".m-sheet-body"
        )
    );
}


function getSheet(){

    return (
        document.getElementById(
            "m-sheet"
        ) ||
        document.querySelector(
            ".m-sheet"
        )
    );
}


function isProgrammeSheet(){

    const sheet =
        getSheet();


    if(!sheet){
        return false;
    }


    const text =
        (
            sheet.textContent ||
            ""
        )
        .toLowerCase();


    return (
        text.includes("programme") &&
        !text.includes("bibliothèque")
    );
}


/* ==========================================================
   LISTE DES PROGRAMMES
   ========================================================== */

function buildList(){

    const list =
        readPrograms();


    if(!list.length){

        return `
            <div class="pgu">

                <div class="pgu-empty">
                    Aucun programme disponible actuellement.
                </div>

            </div>
        `;
    }


    return `
        <div class="pgu">

            <div class="pgu-list">

                ${
                    list.map(function(item){

                        return `
                            <div
                                class="pgu-item pgu-item-clickable"
                                data-program-open="${esc(item.id)}"
                                role="button"
                                tabindex="0">

                                <div class="pgu-cover">

                                    ${
                                        item.image
                                            ? `
                                                <img
                                                    src="${esc(item.image)}"
                                                    alt="${esc(item.name)}">
                                            `
                                            : `
                                                <div class="pgu-cover-empty">
                                                    PROGRAMME
                                                </div>
                                            `
                                    }

                                </div>


                                <div class="pgu-main">

                                    <div class="pgu-date">

                                        ${formatDate(item.date)}

                                        ${
                                            item.time
                                                ? " • " + esc(item.time)
                                                : ""
                                        }

                                    </div>


                                    <div class="pgu-name">
                                        ${esc(item.name)}
                                    </div>


                                    ${
                                        item.theme
                                            ? `
                                                <div class="pgu-theme">
                                                    ${esc(item.theme)}
                                                </div>
                                            `
                                            : ""
                                    }


                                    <div class="pgu-place">
                                        ${esc(item.place || "")}
                                    </div>

                                </div>


                                <div class="pgu-arrow">
                                    ›
                                </div>

                            </div>
                        `;

                    }).join("")
                }

            </div>

        </div>
    `;
}


/* ==========================================================
   DETAIL D'UN PROGRAMME
   ========================================================== */

function buildDetail(item){

    if(!item){
        return buildList();
    }


    return `
        <div class="pgu pgu-detail">

            <button
                type="button"
                class="pgu-back"
                data-program-back>
                ← Retour aux programmes
            </button>


            ${
                item.image
                    ? `
                        <div class="pgu-detail-cover">

                            <img
                                src="${esc(item.image)}"
                                alt="${esc(item.name)}">

                        </div>
                    `
                    : ""
            }


            <div class="pgu-detail-content">

                <div class="pgu-detail-date">
                    ${formatDate(item.date)}
                    ${
                        item.time
                            ? " • " + esc(item.time)
                            : ""
                    }
                </div>


                <h2 class="pgu-detail-title">
                    ${esc(item.name)}
                </h2>


                ${
                    item.theme
                        ? `
                            <div class="pgu-detail-theme">

                                <span>
                                    Thème
                                </span>

                                ${esc(item.theme)}

                            </div>
                        `
                        : ""
                }


                ${
                    item.place
                        ? `
                            <div class="pgu-detail-info">

                                <div class="pgu-detail-icon">
                                    ●
                                </div>

                                <div>

                                    <div class="pgu-detail-label">
                                        Lieu
                                    </div>

                                    <div class="pgu-detail-value">
                                        ${esc(item.place)}
                                    </div>

                                </div>

                            </div>
                        `
                        : ""
                }


                ${
                    item.date
                        ? `
                            <div class="pgu-detail-info">

                                <div class="pgu-detail-icon">
                                    ●
                                </div>

                                <div>

                                    <div class="pgu-detail-label">
                                        Date
                                    </div>

                                    <div class="pgu-detail-value">
                                        ${formatDate(item.date)}
                                    </div>

                                </div>

                            </div>
                        `
                        : ""
                }


                ${
                    item.time
                        ? `
                            <div class="pgu-detail-info">

                                <div class="pgu-detail-icon">
                                    ●
                                </div>

                                <div>

                                    <div class="pgu-detail-label">
                                        Heure
                                    </div>

                                    <div class="pgu-detail-value">
                                        ${esc(item.time)}
                                    </div>

                                </div>

                            </div>
                        `
                        : ""
                }


                ${
                    item.details
                        ? `
                            <div class="pgu-detail-description">

                                <div class="pgu-detail-description-title">
                                    Détails du programme
                                </div>

                                <div class="pgu-detail-description-text">
                                    ${esc(item.details)}
                                </div>

                            </div>
                        `
                        : ""
                }

            </div>

        </div>
    `;
}


/* ==========================================================
   AFFICHAGE
   ========================================================== */

function renderProgramme(){

    if(!isProgrammeSheet()){
        return;
    }


    const body =
        getSheetBody();


    if(!body){
        return;
    }


    if(selectedProgramId){

        const program =
            readPrograms()
            .find(function(item){

                return (
                    item.id ===
                    selectedProgramId
                );
            });


        body.innerHTML =
            buildDetail(
                program
            );

    }else{

        body.innerHTML =
            buildList();
    }


    bindProgrammeEvents();


    console.log(
        "[MARANATHA Programme] affiché",
        selectedProgramId
            ? "DETAIL"
            : "LISTE"
    );
}


/* ==========================================================
   CLICS
   ========================================================== */

function openProgram(id){

    selectedProgramId =
        id;


    renderProgramme();


    const body =
        getSheetBody();


    if(body){

        body.scrollTop =
            0;
    }
}


function backToPrograms(){

    selectedProgramId =
        null;


    renderProgramme();


    const body =
        getSheetBody();


    if(body){

        body.scrollTop =
            0;
    }
}


function bindProgrammeEvents(){

    const body =
        getSheetBody();


    if(!body){
        return;
    }


    body.querySelectorAll(
        "[data-program-open]"
    )
    .forEach(function(item){

        item.addEventListener(
            "click",
            function(){

                openProgram(
                    item.dataset.programOpen
                );
            }
        );


        item.addEventListener(
            "keydown",
            function(event){

                if(
                    event.key === "Enter" ||
                    event.key === " "
                ){

                    event.preventDefault();


                    openProgram(
                        item.dataset.programOpen
                    );
                }
            }
        );
    });


    body.querySelector(
        "[data-program-back]"
    )?.addEventListener(
        "click",
        backToPrograms
    );
}


/* ==========================================================
   BRIDGE AVEC L'ANCIEN PROGRAMME
   ========================================================== */

function scheduleRender(){

    setTimeout(
        renderProgramme,
        30
    );

    setTimeout(
        renderProgramme,
        150
    );

    setTimeout(
        renderProgramme,
        500
    );
}


/*
 * Lorsque le fidèle ouvre Programme,
 * l'ancien système ouvre d'abord la fenêtre.
 * Ensuite nous affichons nos vraies données.
 */

document.addEventListener(
    "click",
    function(event){

        const link =
            event.target.closest(
                'a[href="#programme"],' +
                '[href="#programme"]'
            );


        if(!link){
            return;
        }


        selectedProgramId =
            null;


        scheduleRender();

    },
    false
);


/*
 * Mise à jour provenant de l'admin.
 */

window.addEventListener(
    "storage",
    function(event){

        if(
            event.key === KEY
        ){

            renderProgramme();
        }
    }
);


window.addEventListener(
    "maranatha-program-updated",
    renderProgramme
);


console.log(
    "[MARANATHA] Programme détail actif"
);

})();