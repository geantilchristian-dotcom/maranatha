(function(){

"use strict";


const STORAGE_KEY =
    "maranatha_bible_studies_v2";


let currentPassage =
    null;


/* ==========================================================
   OUTILS
   ========================================================== */

function el(id){

    return document.getElementById(id);
}


function escapeHtml(value){

    return String(
        value == null ? "" : value
    )
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;");
}


function cleanBibleText(value){

    const div =
        document.createElement("div");


    div.innerHTML =
        String(value || "");


    return (
        div.textContent ||
        div.innerText ||
        ""
    )
    .replace(/\s+/g," ")
    .trim();
}


function notify(message,type){

    if(
        typeof window.toast ===
        "function"
    ){

        window.toast(
            message,
            type || "success"
        );

        return;
    }


    if(type === "error"){

        alert(message);

    }else{

        console.log(
            "[MARANATHA]",
            message
        );
    }
}


/* ==========================================================
   STOCKAGE
   ========================================================== */

function readStudies(){

    try{

        const raw =
            localStorage.getItem(
                STORAGE_KEY
            );


        if(!raw){
            return [];
        }


        const parsed =
            JSON.parse(raw);


        return Array.isArray(parsed)
            ? parsed
            : [];


    }catch(error){

        console.error(
            "[BIBLE STUDY STORAGE]",
            error
        );


        return [];
    }
}


function writeStudies(list){

    localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(list)
    );


    window.dispatchEvent(
        new CustomEvent(
            "maranatha-bible-studies-updated",
            {
                detail:list
            }
        )
    );
}


/* ==========================================================
   LIRE LA REFERENCE ACTUELLE
   ========================================================== */

function getSelection(){

    const language =
        el("bs-language");


    const book =
        el("bs-book");


    const chapter =
        el("bs-chapter");


    const verseStart =
        el("bs-verse-start");


    const verseEnd =
        el("bs-verse-end");


    if(
        !language ||
        !book ||
        !chapter
    ){

        throw new Error(
            "Les sélecteurs bibliques sont introuvables."
        );
    }


    const bookNum =
        parseInt(
            book.value,
            10
        );


    const chapterNum =
        parseInt(
            chapter.value,
            10
        );


    if(
        !bookNum ||
        !chapterNum
    ){

        throw new Error(
            "Choisissez le livre et le chapitre."
        );
    }


    const option =
        book.options[
            book.selectedIndex
        ];


    const bookName =
        option
            ? option.textContent.trim()
            : "";


    let start =
        verseStart
            ? parseInt(
                verseStart.value,
                10
              )
            : NaN;


    let end =
        verseEnd
            ? parseInt(
                verseEnd.value,
                10
              )
            : NaN;


    if(!Number.isFinite(start)){

        start =
            null;

        end =
            null;

    }else if(
        !Number.isFinite(end)
    ){

        end =
            start;
    }


    if(
        start !== null &&
        end < start
    ){

        end =
            start;
    }


    const isSwahili =
        language.value === "sw";


    return {

        language:
            isSwahili
                ? "sw"
                : "fr",

        version:
            isSwahili
                ? "SUV"
                : "FR",

        bookNum:
            bookNum,

        bookName:
            bookName,

        chapter:
            chapterNum,

        start:
            start,

        end:
            end
    };
}


/* ==========================================================
   REFERENCE TEXTE
   ========================================================== */

function buildReference(selection){

    let reference =
        selection.bookName +
        " " +
        selection.chapter;


    if(
        selection.start !== null
    ){

        reference +=
            ":" +
            selection.start;


        if(
            selection.end !==
            selection.start
        ){

            reference +=
                "-" +
                selection.end;
        }
    }


    return reference;
}


/* ==========================================================
   AFFICHER LE PASSAGE
   ========================================================== */

async function displayPassage(){

    const button =
        el("bs-load");


    const preview =
        el("bs-preview");


    if(
        !button ||
        !preview
    ){

        console.error(
            "[ETUDE BIBLIQUE] bouton ou zone preview introuvable"
        );

        return;
    }


    let selection;


    try{

        selection =
            getSelection();

    }catch(error){

        notify(
            error.message,
            "error"
        );

        return;
    }


    button.disabled =
        true;


    button.textContent =
        selection.language === "sw"
            ? "Inapakia..."
            : "Chargement...";


    preview.innerHTML = `
        <div class="bs-preview-empty">
            ${
                selection.language === "sw"
                    ? "Inapakia kifungu cha Biblia..."
                    : "Chargement du passage biblique..."
            }
        </div>
    `;


    try{

        const apiUrl =
            "/api/bible/" +
            selection.bookNum +
            "/" +
            selection.chapter +
            "?version=" +
            encodeURIComponent(
                selection.version
            );


        console.log(
            "[BIBLE STUDY RUNTIME] GET",
            apiUrl
        );


        const response =
            await fetch(
                apiUrl,
                {
                    cache:"no-store"
                }
            );


        let result;


        try{

            result =
                await response.json();

        }catch(error){

            throw new Error(
                "Réponse Bible invalide."
            );
        }


        if(
            !response.ok
        ){

            throw new Error(
                result?.error ||
                "Erreur API Bible."
            );
        }


        if(
            !result ||
            !Array.isArray(
                result.verses
            )
        ){

            throw new Error(
                "La réponse ne contient aucun tableau de versets."
            );
        }


        let verses =
            result.verses;


        if(
            selection.start !== null
        ){

            verses =
                verses.filter(
                    function(item){

                        const number =
                            Number(
                                item.verse
                            );


                        return (
                            number >=
                                selection.start &&
                            number <=
                                selection.end
                        );
                    }
                );
        }


        if(!verses.length){

            throw new Error(
                "Aucun verset trouvé pour cette sélection."
            );
        }


        const reference =
            buildReference(
                selection
            );


        const passageText =
            verses
            .map(
                function(item){

                    return (
                        item.verse +
                        ". " +
                        cleanBibleText(
                            item.text
                        )
                    );
                }
            )
            .join("\n");


        currentPassage = {

            reference:
                reference,

            bookNum:
                selection.bookNum,

            bookName:
                selection.bookName,

            chapter:
                selection.chapter,

            verseStart:
                selection.start,

            verseEnd:
                selection.end,

            passage:
                passageText,

            bibleVersion:
                selection.version,

            language:
                selection.language
        };


        /*
         * Exposer aussi globalement pour diagnostic.
         */

        window.MARANATHA_BIBLE_STUDY_CURRENT =
            currentPassage;


        preview.innerHTML = `

            <div
                class="bs-preview-ref"
                style="
                    display:flex;
                    align-items:center;
                    gap:7px;
                    margin-bottom:12px;
                ">

                <strong>
                    ${escapeHtml(reference)}
                </strong>


                <span
                    style="
                        display:inline-flex;
                        align-items:center;
                        justify-content:center;
                        min-width:25px;
                        height:20px;
                        padding:0 6px;
                        border-radius:999px;
                        background:rgba(212,175,55,.12);
                        color:#d4af37;
                        font-family:Arial,sans-serif;
                        font-size:7px;
                        font-weight:800;
                    ">

                    ${
                        selection.language === "sw"
                            ? "SW"
                            : "FR"
                    }

                </span>

            </div>


            <div>

                ${
                    verses.map(
                        function(item){

                            const text =
                                cleanBibleText(
                                    item.text
                                );


                            return `

                                <div
                                    style="
                                        display:flex;
                                        align-items:flex-start;
                                        gap:9px;
                                        margin-bottom:11px;
                                    ">

                                    <span
                                        style="
                                            flex:0 0 19px;
                                            padding-top:2px;
                                            color:#d4af37;
                                            font-family:Arial,sans-serif;
                                            font-size:8px;
                                            font-weight:800;
                                            text-align:right;
                                        ">

                                        ${escapeHtml(item.verse)}

                                    </span>


                                    <div
                                        style="
                                            flex:1;
                                            min-width:0;
                                            color:rgba(255,255,255,.90);
                                            font-family:Georgia,'Times New Roman',serif;
                                            font-size:13px;
                                            line-height:1.7;
                                        ">

                                        ${escapeHtml(text)}

                                    </div>

                                </div>

                            `;

                        }
                    ).join("")
                }

            </div>

        `;


        console.log(
            "[BIBLE STUDY RUNTIME] PASSAGE OK",
            currentPassage
        );


    }catch(error){

        currentPassage =
            null;


        window.MARANATHA_BIBLE_STUDY_CURRENT =
            null;


        console.error(
            "[BIBLE STUDY RUNTIME]",
            error
        );


        preview.innerHTML = `

            <div
                class="bs-preview-empty"
                style="color:#ff7b8d;">

                Impossible de charger ce passage.

                <br><br>

                ${escapeHtml(
                    error.message
                )}

            </div>

        `;


    }finally{

        button.disabled =
            false;


        button.textContent =
            "Afficher le passage";
    }
}


/* ==========================================================
   PUBLIER
   ========================================================== */

async function publishStudy(){

    if(!currentPassage){

        notify(
            "Cliquez d'abord sur « Afficher le passage ».",
            "error"
        );

        return;
    }


    const title =
        el("bs-title")
            ? el("bs-title").value.trim()
            : "";


    const explanation =
        el("bs-explanation")
            ? el("bs-explanation").value.trim()
            : "";


    const finalTitle =
        title ||
        currentPassage.reference;


    const record = {

        localId:
            "bs-" +
            Date.now(),

        titre:
            finalTitle,

        referenceBible:
            currentPassage.reference,

        passageBible:
            currentPassage.passage,

        explication:
            explanation,

        bibleVersion:
            currentPassage.bibleVersion,

        language:
            currentPassage.language,

        bookNum:
            currentPassage.bookNum,

        chapter:
            currentPassage.chapter,

        actif:
            true,

        datePublication:
            new Date().toISOString()
    };


    const studies =
        readStudies();


    studies.unshift(
        record
    );


    writeStudies(
        studies
    );


    renderPublishedStudies();


    /*
     * Essayer aussi l'API réelle,
     * sans empêcher le test local.
     */

    try{

        const headers = {
            "Content-Type":
                "application/json"
        };


        if(
            typeof window.authHeaders ===
            "function"
        ){

            Object.assign(
                headers,
                window.authHeaders()
            );
        }


        await fetch(
            "/api/etudes",
            {
                method:"POST",

                headers:
                    headers,

                body:
                    JSON.stringify({
                        titre:
                            finalTitle,

                        texte:
                            currentPassage.passage,

                        pdfUrl:
                            "",

                        datePublication:
                            record.datePublication,

                        actif:
                            true,

                        referenceBible:
                            currentPassage.reference,

                        passageBible:
                            currentPassage.passage,

                        explication:
                            explanation,

                        bibleVersion:
                            currentPassage.bibleVersion,

                        language:
                            currentPassage.language
                    })
            }
        );


    }catch(error){

        console.warn(
            "[BIBLE STUDY RUNTIME] API distante non disponible",
            error
        );
    }


    if(el("bs-title")){

        el("bs-title").value =
            "";
    }


    if(el("bs-explanation")){

        el("bs-explanation").value =
            "";
    }


    notify(
        "Étude biblique publiée.",
        "success"
    );


    console.log(
        "[BIBLE STUDY RUNTIME] PUBLICATION OK",
        record
    );
}


/* ==========================================================
   LISTE DES ETUDES
   ========================================================== */

function renderPublishedStudies(){

    const list =
        el("bs-list");


    const counter =
        el("bs-count");


    if(
        !list ||
        !counter
    ){
        return;
    }


    const studies =
        readStudies();


    counter.textContent =
        studies.length +
        " étude" +
        (
            studies.length > 1
                ? "s"
                : ""
        );


    if(!studies.length){

        list.innerHTML = `
            <div class="bs-empty">
                Aucune étude biblique publiée.
            </div>
        `;


        return;
    }


    list.innerHTML =
        studies.map(
            function(item){

                const id =
                    item.localId ||
                    item._id ||
                    "";


                const sw =
                    item.language === "sw" ||
                    item.bibleVersion === "SUV";


                return `

                    <div class="bs-study-item">

                        <div class="bs-study-icon">
                            BIBLE
                        </div>


                        <div>

                            <div class="bs-study-ref">

                                ${escapeHtml(
                                    item.referenceBible ||
                                    "Étude biblique"
                                )}

                                &nbsp;·&nbsp;

                                ${sw ? "SW" : "FR"}

                            </div>


                            <div class="bs-study-title">
                                ${escapeHtml(
                                    item.titre ||
                                    item.referenceBible ||
                                    "Étude biblique"
                                )}
                            </div>


                            ${
                                item.explication
                                    ? `
                                        <div class="bs-study-text">
                                            ${escapeHtml(
                                                item.explication.slice(
                                                    0,
                                                    180
                                                )
                                            )}
                                        </div>
                                    `
                                    : ""
                            }

                        </div>


                        <div class="bs-study-actions">

                            <button
                                type="button"
                                class="bs-delete"
                                data-runtime-delete="${escapeHtml(id)}">

                                Supprimer

                            </button>

                        </div>

                    </div>

                `;

            }
        ).join("");
}


/* ==========================================================
   SUPPRIMER
   ========================================================== */

function deleteStudy(id){

    if(!id){
        return;
    }


    if(
        !confirm(
            "Supprimer cette étude biblique ?"
        )
    ){
        return;
    }


    const studies =
        readStudies()
        .filter(
            function(item){

                return (
                    String(
                        item.localId ||
                        item._id ||
                        ""
                    ) !==
                    String(id)
                );
            }
        );


    writeStudies(
        studies
    );


    renderPublishedStudies();
}


/* ==========================================================
   PRENDRE LE CONTROLE DES BOUTONS
   ========================================================== */

document.addEventListener(
    "click",
    function(event){

        const loadButton =
            event.target.closest(
                "#bs-load"
            );


        if(loadButton){

            /*
             * Capture=true :
             * on empêche l'ancien JS cassé
             * de recevoir le clic.
             */

            event.preventDefault();

            event.stopPropagation();

            event.stopImmediatePropagation();


            displayPassage();

            return;
        }


        const publishButton =
            event.target.closest(
                "#bs-publish"
            );


        if(publishButton){

            event.preventDefault();

            event.stopPropagation();

            event.stopImmediatePropagation();


            publishStudy();

            return;
        }


        const deleteButton =
            event.target.closest(
                "[data-runtime-delete]"
            );


        if(deleteButton){

            event.preventDefault();

            event.stopPropagation();

            event.stopImmediatePropagation();


            deleteStudy(
                deleteButton.dataset.runtimeDelete
            );
        }

    },
    true
);


/* ==========================================================
   INITIALISATION
   ========================================================== */

function init(){

    renderPublishedStudies();


    console.log(
        "[MARANATHA] Bible Study Runtime actif"
    );


    console.log(
        "[MARANATHA] Bouton Afficher le passage contrôlé"
    );
}


if(
    document.readyState ===
    "loading"
){

    document.addEventListener(
        "DOMContentLoaded",
        init
    );

}else{

    init();
}


setTimeout(
    renderPublishedStudies,
    500
);


})();