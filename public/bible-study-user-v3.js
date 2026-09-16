(function(){

"use strict";


const STORAGE_KEY =
    "maranatha_bible_studies_v2";


let selectedStudy =
    null;


let renderTimer =
    null;


/* ==========================================================
   OUTILS
   ========================================================== */

function esc(value){

    return String(
        value == null ? "" : value
    )
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;");
}


function readStudies(){

    try{

        const raw =
            localStorage.getItem(
                STORAGE_KEY
            );


        if(!raw){
            return [];
        }


        const result =
            JSON.parse(raw);


        if(!Array.isArray(result)){
            return [];
        }


        return result.filter(
            function(item){

                return (
                    item &&
                    item.actif !== false &&
                    item.active !== false
                );
            }
        );


    }catch(error){

        console.error(
            "[ETUDE BIBLIQUE FIDELE]",
            error
        );


        return [];
    }
}


function studyId(item){

    return String(
        item.localId ||
        item._id ||
        item.id ||
        ""
    );
}


function studyLanguage(item){

    return (
        item.language === "sw" ||
        item.bibleVersion === "SUV"
    )
        ? "SW"
        : "FR";
}


/* ==========================================================
   FENETRE MARANATHA
   ========================================================== */

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


function getBody(){

    return (
        document.getElementById(
            "m-sheet-body"
        ) ||
        document.querySelector(
            ".m-sheet-body"
        )
    );
}


function studySheetIsOpen(){

    const sheet =
        getSheet();


    if(!sheet){
        return false;
    }


    const text =
        String(
            sheet.textContent || ""
        )
        .replace(/\s+/g," ")
        .trim()
        .toLowerCase();


    return (
        (
            text.includes(
                "étude biblique"
            ) ||
            text.includes(
                "etude biblique"
            )
        ) &&
        !text.includes(
            "bibliothèque"
        )
    );
}


/* ==========================================================
   LISTE
   ========================================================== */

function buildList(){

    const studies =
        readStudies();


    if(!studies.length){

        return `
            <div class="ebf">

                <div class="ebf-empty">

                    Aucune étude biblique
                    disponible actuellement.

                </div>

            </div>
        `;
    }


    return `
        <div class="ebf">

            <div class="ebf-list">

                ${
                    studies.map(
                        function(item){

                            const id =
                                studyId(item);


                            const reference =
                                item.referenceBible ||
                                item.reference ||
                                "Étude biblique";


                            const title =
                                item.titre ||
                                item.title ||
                                reference;


                            const explanation =
                                item.explication ||
                                item.explanation ||
                                "";


                            return `

                                <article
                                    class="ebf-item"
                                    data-ebf-open="${esc(id)}">

                                    <div class="ebf-icon">
                                        BIBLE
                                    </div>


                                    <div class="ebf-main">

                                        <div class="ebf-reference">
                                            ${esc(reference)}
                                        </div>


                                        <div class="ebf-title">
                                            ${esc(title)}
                                        </div>


                                        ${
                                            explanation
                                                ? `
                                                    <div class="ebf-preview">
                                                        ${esc(explanation)}
                                                    </div>
                                                `
                                                : ""
                                        }

                                    </div>


                                    <div class="ebf-lang">
                                        ${studyLanguage(item)}
                                    </div>


                                    <div class="ebf-arrow">
                                        ›
                                    </div>

                                </article>

                            `;

                        }
                    ).join("")
                }

            </div>

        </div>
    `;
}


/* ==========================================================
   DETAIL
   ========================================================== */

function buildDetail(item){

    if(!item){

        selectedStudy =
            null;


        return buildList();
    }


    const reference =
        item.referenceBible ||
        item.reference ||
        "Étude biblique";


    const title =
        item.titre ||
        item.title ||
        reference;


    const passage =
        item.passageBible ||
        item.passage ||
        item.texte ||
        "";


    const explanation =
        item.explication ||
        item.explanation ||
        "";


    return `
        <div class="ebf">

            <button
                type="button"
                class="ebf-back"
                data-ebf-back>

                ← Retour aux études

            </button>


            <div class="ebf-detail-ref">

                <span>
                    ${esc(reference)}
                </span>


                <span class="ebf-detail-lang">
                    ${studyLanguage(item)}
                </span>

            </div>


            <div class="ebf-detail-title">
                ${esc(title)}
            </div>


            ${
                passage
                    ? `
                        <section class="ebf-passage">

                            <div class="ebf-section-title">
                                Passage biblique
                            </div>


                            <div class="ebf-passage-text">
                                ${esc(passage)}
                            </div>

                        </section>
                    `
                    : ""
            }


            ${
                explanation
                    ? `
                        <section class="ebf-explanation">

                            <div class="ebf-explanation-title">
                                Explication / Enseignement
                            </div>


                            <div class="ebf-explanation-text">
                                ${esc(explanation)}
                            </div>

                        </section>
                    `
                    : ""
            }

        </div>
    `;
}


/* ==========================================================
   RENDU
   ========================================================== */

function render(){

    if(
        !studySheetIsOpen()
    ){
        return;
    }


    const body =
        getBody();


    if(!body){
        return;
    }


    if(selectedStudy){

        const item =
            readStudies()
            .find(
                function(entry){

                    return (
                        studyId(entry) ===
                        String(selectedStudy)
                    );
                }
            );


        body.innerHTML =
            buildDetail(item);

    }else{

        body.innerHTML =
            buildList();
    }


    bind();


    console.log(
        "[MARANATHA Etude biblique]",
        readStudies().length,
        "étude(s) synchronisée(s)"
    );
}


/* ==========================================================
   CLICS
   ========================================================== */

function bind(){

    const body =
        getBody();


    if(!body){
        return;
    }


    body
        .querySelectorAll(
            "[data-ebf-open]"
        )
        .forEach(
            function(row){

                row.addEventListener(
                    "click",
                    function(){

                        selectedStudy =
                            row.dataset.ebfOpen;


                        render();


                        body.scrollTop =
                            0;
                    }
                );
            }
        );


    body
        .querySelector(
            "[data-ebf-back]"
        )
        ?.addEventListener(
            "click",
            function(){

                selectedStudy =
                    null;


                render();


                body.scrollTop =
                    0;
            }
        );
}


/* ==========================================================
   SYNCHRONISATION
   ========================================================== */

function schedule(){

    clearTimeout(
        renderTimer
    );


    renderTimer =
        setTimeout(
            render,
            25
        );
}


const observer =
    new MutationObserver(
        function(){

            if(
                studySheetIsOpen()
            ){

                schedule();
            }
        }
    );


observer.observe(
    document.documentElement,
    {
        childList:true,
        subtree:true,
        attributes:true,
        attributeFilter:[
            "class",
            "style",
            "aria-hidden"
        ]
    }
);


/*
 * Lorsque l'utilisateur ouvre l'onglet,
 * attendre que l'ancien code ouvre la fenêtre,
 * puis prendre le contrôle.
 */

document.addEventListener(
    "click",
    function(){

        setTimeout(
            render,
            30
        );


        setTimeout(
            render,
            120
        );


        setTimeout(
            render,
            350
        );


        setTimeout(
            render,
            700
        );

    },
    false
);


/*
 * Admin et fidèle dans deux onglets Chrome.
 */

window.addEventListener(
    "storage",
    function(event){

        if(
            event.key ===
            STORAGE_KEY
        ){

            render();
        }
    }
);


window.addEventListener(
    "maranatha-bible-studies-updated",
    render
);


console.log(
    "[MARANATHA] Bridge Etude biblique fidele V3 actif"
);


})();