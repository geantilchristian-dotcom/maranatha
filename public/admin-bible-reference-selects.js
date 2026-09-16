(function(){

"use strict";


/* ==========================================================
   NOMBRE DE CHAPITRES DES 66 LIVRES
   ========================================================== */

const CHAPTER_COUNTS = [
50,40,27,36,34,
24,21,4,31,24,
22,25,29,36,10,
13,10,42,150,31,
12,8,66,52,5,
48,12,14,3,9,
1,4,7,3,3,
3,2,14,4,28,
16,24,21,28,16,
16,13,6,6,4,
4,5,3,6,4,
3,1,13,5,5,
3,5,1,1,1,
22
];


let verseRequestId =
    0;


/* ==========================================================
   OUTILS
   ========================================================== */

function getBook(){

    return document.getElementById(
        "bs-book"
    );
}


function getLanguage(){

    return document.getElementById(
        "bs-language"
    );
}


function getChapter(){

    return document.getElementById(
        "bs-chapter"
    );
}


function getVerseStart(){

    return document.getElementById(
        "bs-verse-start"
    );
}


function getVerseEnd(){

    return document.getElementById(
        "bs-verse-end"
    );
}


function getHiddenVerses(){

    return document.getElementById(
        "bs-verses"
    );
}


function getStatus(){

    return document.getElementById(
        "bs-reference-status"
    );
}


function currentBookNumber(){

    const book =
        getBook();


    const value =
        parseInt(
            book?.value,
            10
        );


    return (
        value >= 1 &&
        value <= 66
    )
        ? value
        : 1;
}


function currentVersion(){

    const language =
        getLanguage();


    return (
        language &&
        language.value === "sw"
    )
        ? "SUV"
        : "FR";
}


function chapterCount(){

    return (
        CHAPTER_COUNTS[
            currentBookNumber() - 1
        ] ||
        1
    );
}


/* ==========================================================
   REMPLACER CHAPITRE INPUT -> SELECT
   ========================================================== */

function installChapterSelect(){

    let old =
        document.getElementById(
            "bs-chapter"
        );


    if(!old){
        return false;
    }


    if(
        old.tagName === "SELECT"
    ){

        return true;
    }


    const oldValue =
        parseInt(
            old.value,
            10
        ) || 1;


    const select =
        document.createElement(
            "select"
        );


    select.id =
        "bs-chapter";


    select.dataset.oldValue =
        String(oldValue);


    old.replaceWith(
        select
    );


    return true;
}


/* ==========================================================
   REMPLACER VERSET(S) INPUT -> SELECTS
   ========================================================== */

function installVerseSelects(){

    const old =
        document.getElementById(
            "bs-verses"
        );


    if(!old){
        return false;
    }


    /*
     * Déjà installé.
     */
    if(
        document.getElementById(
            "bs-verse-start"
        )
    ){

        return true;
    }


    const oldValue =
        String(
            old.value || ""
        ).trim();


    const field =
        old.closest(
            ".bs-field"
        );


    if(!field){
        return false;
    }


    let initialStart = "";
    let initialEnd = "";


    if(
        /^\d+$/.test(
            oldValue
        )
    ){

        initialStart =
            oldValue;

    }else{

        const range =
            oldValue.match(
                /^(\d+)-(\d+)$/
            );


        if(range){

            initialStart =
                range[1];

            initialEnd =
                range[2];
        }
    }


    field.innerHTML = `
        <label>
            VERSET(S)
            <span>optionnel</span>
        </label>


        <div class="bs-verse-selects">

            <div class="bs-mini-field">

                <small>
                    Du verset
                </small>

                <select id="bs-verse-start">

                    <option value="">
                        Tout le chapitre
                    </option>

                </select>

            </div>


            <div class="bs-mini-field">

                <small>
                    Jusqu'au verset
                </small>

                <select
                    id="bs-verse-end"
                    disabled>

                    <option value="">
                        Même verset
                    </option>

                </select>

            </div>

        </div>


        <input
            id="bs-verses"
            type="hidden"
            value="">


        <div
            id="bs-reference-status"
            class="bs-reference-loading">
        </div>
    `;


    field.dataset.initialStart =
        initialStart;


    field.dataset.initialEnd =
        initialEnd;


    return true;
}


/* ==========================================================
   CHAPITRES
   ========================================================== */

function populateChapters(
    requestedChapter
){

    const select =
        getChapter();


    if(!select){
        return;
    }


    const max =
        chapterCount();


    let current =
        parseInt(
            requestedChapter ||
            select.value ||
            select.dataset.oldValue,
            10
        );


    if(
        !current ||
        current < 1
    ){

        current = 1;
    }


    if(current > max){

        current = max;
    }


    let html = "";


    for(
        let chapter = 1;
        chapter <= max;
        chapter++
    ){

        html += `
            <option
                value="${chapter}"
                ${
                    chapter === current
                        ? "selected"
                        : ""
                }>

                Chapitre ${chapter}

            </option>
        `;
    }


    select.innerHTML =
        html;


    select.value =
        String(current);
}


/* ==========================================================
   VALEUR CACHEE DES VERSETS
   ========================================================== */

function syncVerseValue(){

    const start =
        getVerseStart();


    const end =
        getVerseEnd();


    const hidden =
        getHiddenVerses();


    if(
        !start ||
        !end ||
        !hidden
    ){
        return;
    }


    const startValue =
        String(
            start.value || ""
        );


    const endValue =
        String(
            end.value || ""
        );


    /*
     * Tout le chapitre
     */
    if(!startValue){

        hidden.value =
            "";

        end.disabled =
            true;

        end.value =
            "";

        return;
    }


    end.disabled =
        false;


    /*
     * Un seul verset
     */
    if(
        !endValue ||
        endValue === startValue
    ){

        hidden.value =
            startValue;

        return;
    }


    /*
     * Plage
     */
    hidden.value =
        startValue +
        "-" +
        endValue;
}


/* ==========================================================
   OPTIONS FIN DE VERSET
   ========================================================== */

function rebuildEndOptions(){

    const start =
        getVerseStart();


    const end =
        getVerseEnd();


    if(!start || !end){
        return;
    }


    const startNumber =
        parseInt(
            start.value,
            10
        );


    if(!startNumber){

        end.innerHTML = `
            <option value="">
                Même verset
            </option>
        `;


        end.disabled =
            true;


        syncVerseValue();

        return;
    }


    const previous =
        parseInt(
            end.value,
            10
        );


    const available =
        Array.from(
            start.options
        )
        .map(
            function(option){

                return parseInt(
                    option.value,
                    10
                );
            }
        )
        .filter(
            function(number){

                return (
                    number &&
                    number >=
                    startNumber
                );
            }
        );


    let html = `
        <option value="">
            Même verset
        </option>
    `;


    available.forEach(
        function(number){

            html += `
                <option value="${number}">
                    Verset ${number}
                </option>
            `;
        }
    );


    end.innerHTML =
        html;


    end.disabled =
        false;


    if(
        previous &&
        previous >= startNumber &&
        available.includes(
            previous
        )
    ){

        end.value =
            String(previous);
    }


    syncVerseValue();
}


/* ==========================================================
   CHARGER LES VERSETS REELS DU CHAPITRE
   ========================================================== */

async function populateVerses(){

    const start =
        getVerseStart();


    const end =
        getVerseEnd();


    const status =
        getStatus();


    const chapter =
        parseInt(
            getChapter()?.value,
            10
        );


    const bookNum =
        currentBookNumber();


    if(
        !start ||
        !end ||
        !chapter
    ){
        return;
    }


    const requestId =
        ++verseRequestId;


    start.disabled =
        true;


    end.disabled =
        true;


    start.innerHTML = `
        <option value="">
            Chargement...
        </option>
    `;


    end.innerHTML = `
        <option value="">
            Même verset
        </option>
    `;


    if(status){

        status.className =
            "bs-reference-loading";

        status.textContent =
            "Chargement des versets...";
    }


    try{

        const response =
            await fetch(
                "/api/bible/" +
                bookNum +
                "/" +
                chapter +
                "?version=" +
                encodeURIComponent(
                    currentVersion()
                ),
                {
                    cache:"no-store"
                }
            );


        const result =
            await response.json();


        /*
         * Une autre requête est déjà partie.
         */
        if(
            requestId !==
            verseRequestId
        ){
            return;
        }


        if(
            !response.ok ||
            !Array.isArray(
                result.verses
            ) ||
            !result.verses.length
        ){

            throw new Error(
                result.error ||
                "Versets indisponibles."
            );
        }


        let html = `
            <option value="">
                Tout le chapitre
            </option>
        `;


        result.verses.forEach(
            function(item){

                const number =
                    Number(
                        item.verse
                    );


                if(!number){
                    return;
                }


                html += `
                    <option value="${number}">
                        Verset ${number}
                    </option>
                `;
            }
        );


        start.innerHTML =
            html;


        start.disabled =
            false;


        /*
         * Restaurer ancienne sélection si présente.
         */
        const field =
            start.closest(
                ".bs-field"
            );


        const wantedStart =
            field?.dataset.initialStart ||
            "";


        const wantedEnd =
            field?.dataset.initialEnd ||
            "";


        if(
            wantedStart &&
            Array.from(
                start.options
            )
            .some(
                function(option){

                    return (
                        option.value ===
                        wantedStart
                    );
                }
            )
        ){

            start.value =
                wantedStart;
        }


        rebuildEndOptions();


        if(
            wantedEnd &&
            Array.from(
                end.options
            )
            .some(
                function(option){

                    return (
                        option.value ===
                        wantedEnd
                    );
                }
            )
        ){

            end.value =
                wantedEnd;
        }


        /*
         * Valeurs initiales consommées.
         */

        if(field){

            field.dataset.initialStart =
                "";

            field.dataset.initialEnd =
                "";
        }


        syncVerseValue();


        if(status){

            status.className =
                "bs-reference-loading ok";


            status.textContent =
                result.verses.length +
                " verset(s) disponible(s).";
        }


    }catch(error){

        console.error(
            "[MARANATHA Étude biblique]",
            error
        );


        start.innerHTML = `
            <option value="">
                Tout le chapitre
            </option>
        `;


        start.disabled =
            false;


        end.innerHTML = `
            <option value="">
                Même verset
            </option>
        `;


        end.disabled =
            true;


        syncVerseValue();


        if(status){

            status.className =
                "bs-reference-loading error";


            status.textContent =
                "Impossible de charger la liste des versets.";
        }
    }
}


/* ==========================================================
   INSTALLATION DES EVENEMENTS
   ========================================================== */

function bindEvents(){

    const book =
        getBook();


    const language =
        getLanguage();


    const chapter =
        getChapter();


    const start =
        getVerseStart();


    const end =
        getVerseEnd();


    if(
        !book ||
        !chapter ||
        !start ||
        !end
    ){
        return;
    }


    /*
     * Eviter doubles événements.
     */

    if(
        chapter.dataset.selectEvents ===
        "1"
    ){
        return;
    }


    chapter.dataset.selectEvents =
        "1";


    book.addEventListener(
        "change",
        function(){

            /*
             * Nouveau livre :
             * chapitre 1.
             */

            setTimeout(
                function(){

                    populateChapters(
                        1
                    );


                    populateVerses();

                },
                40
            );
        }
    );


    if(language){

        language.addEventListener(
            "change",
            function(){

                /*
                 * L'autre script change d'abord
                 * la liste des livres.
                 */

                setTimeout(
                    function(){

                        populateChapters(
                            getChapter()?.value ||
                            1
                        );


                        populateVerses();

                    },
                    80
                );
            }
        );
    }


    chapter.addEventListener(
        "change",
        function(){

            populateVerses();
        }
    );


    start.addEventListener(
        "change",
        function(){

            rebuildEndOptions();
        }
    );


    end.addEventListener(
        "change",
        function(){

            syncVerseValue();
        }
    );
}


/* ==========================================================
   INSTALLATION COMPLETE
   ========================================================== */

function install(){

    const book =
        getBook();


    if(!book){
        return;
    }


    /*
     * Remplacer les anciens inputs.
     */

    installChapterSelect();

    installVerseSelects();


    const chapter =
        getChapter();


    if(!chapter){
        return;
    }


    /*
     * Si déjà entièrement installé,
     * juste réparer les options si nécessaire.
     */

    if(
        chapter.dataset.referenceReady ===
        "1"
    ){

        return;
    }


    chapter.dataset.referenceReady =
        "1";


    populateChapters(
        chapter.dataset.oldValue ||
        1
    );


    bindEvents();


    populateVerses();


    console.log(
        "[MARANATHA] Chapitres/versets sélectionnables actifs"
    );
}


/* ==========================================================
   INITIALISATION
   ========================================================== */

if(
    document.readyState ===
    "loading"
){

    document.addEventListener(
        "DOMContentLoaded",
        function(){

            setTimeout(
                install,
                150
            );
        }
    );

}else{

    setTimeout(
        install,
        150
    );
}


/*
 * Quand on retourne dans Étude biblique.
 */

document.addEventListener(
    "click",
    function(event){

        const tab =
            event.target.closest(
                '[data-tab="etudes"]'
            );


        if(tab){

            setTimeout(
                install,
                100
            );
        }
    }
);


/*
 * Si un autre module reconstruit la page.
 */

let observerTimer =
    null;


const observer =
    new MutationObserver(
        function(){

            clearTimeout(
                observerTimer
            );


            observerTimer =
                setTimeout(
                    function(){

                        const chapter =
                            document.getElementById(
                                "bs-chapter"
                            );


                        if(
                            chapter &&
                            chapter.tagName !==
                            "SELECT"
                        ){

                            install();
                        }

                    },
                    100
                );
        }
    );


observer.observe(
    document.body,
    {
        childList:true,
        subtree:true
    }
);


setTimeout(
    install,
    500
);


})();