(function(){

"use strict";


/* ==========================================================
   CONFIGURATION
   ========================================================== */

const LANGUAGE_KEY =
    "maranatha_bible_language";


const BOOKS_FR = [
"Genèse","Exode","Lévitique","Nombres","Deutéronome",
"Josué","Juges","Ruth","1 Samuel","2 Samuel",
"1 Rois","2 Rois","1 Chroniques","2 Chroniques",
"Esdras","Néhémie","Esther","Job","Psaumes","Proverbes",
"Ecclésiaste","Cantique des cantiques","Ésaïe","Jérémie",
"Lamentations","Ézéchiel","Daniel","Osée","Joël","Amos",
"Abdias","Jonas","Michée","Nahum","Habacuc","Sophonie",
"Aggée","Zacharie","Malachie","Matthieu","Marc","Luc",
"Jean","Actes","Romains","1 Corinthiens","2 Corinthiens",
"Galates","Éphésiens","Philippiens","Colossiens",
"1 Thessaloniciens","2 Thessaloniciens","1 Timothée",
"2 Timothée","Tite","Philémon","Hébreux","Jacques",
"1 Pierre","2 Pierre","1 Jean","2 Jean","3 Jean",
"Jude","Apocalypse"
];


const BOOKS_SW = [
"Mwanzo","Kutoka","Walawi","Hesabu","Kumbukumbu la Sheria",
"Yoshua","Waamuzi","Ruthu","1 Samueli","2 Samueli",
"1 Wafalme","2 Wafalme","1 Mambo ya Nyakati",
"2 Mambo ya Nyakati","Ezra","Nehemia","Esta","Yobu",
"Zaburi","Methali","Mhubiri","Wimbo Ulio Bora",
"Isaya","Yeremia","Maombolezo","Ezekieli","Danieli",
"Hosea","Yoeli","Amosi","Obadia","Yona","Mika",
"Nahumu","Habakuki","Sefania","Hagai","Zekaria","Malaki",
"Mathayo","Marko","Luka","Yohane","Matendo","Waroma",
"1 Wakorintho","2 Wakorintho","Wagalatia","Waefeso",
"Wafilipi","Wakolosai","1 Wathesalonike","2 Wathesalonike",
"1 Timotheo","2 Timotheo","Tito","Filemoni","Waebrania",
"Yakobo","1 Petro","2 Petro","1 Yohane","2 Yohane",
"3 Yohane","Yuda","Ufunuo"
];


/*
 * Nombre réel de chapitres dans chacun des 66 livres.
 */

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


let state = {

    language:
        localStorage.getItem(
            LANGUAGE_KEY
        ) === "sw"
            ? "sw"
            : "fr",

    bookNum:
        43,

    chapter:
        3,

    verses:[]
};


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


/*
 * L'API retourne parfois du HTML comme :
 * <b>Amen, amen</b>
 *
 * On échappe d'abord tout, puis on autorise
 * uniquement b / strong / i / em / br.
 */

function formatBibleText(value){

    return esc(value)

        .replace(
            /&lt;b&gt;/gi,
            "<strong>"
        )

        .replace(
            /&lt;\/b&gt;/gi,
            "</strong>"
        )

        .replace(
            /&lt;strong&gt;/gi,
            "<strong>"
        )

        .replace(
            /&lt;\/strong&gt;/gi,
            "</strong>"
        )

        .replace(
            /&lt;i&gt;/gi,
            "<em>"
        )

        .replace(
            /&lt;\/i&gt;/gi,
            "</em>"
        )

        .replace(
            /&lt;em&gt;/gi,
            "<em>"
        )

        .replace(
            /&lt;\/em&gt;/gi,
            "</em>"
        )

        .replace(
            /&lt;br\s*\/?&gt;/gi,
            "<br>"
        );
}


function books(){

    return state.language === "sw"
        ? BOOKS_SW
        : BOOKS_FR;
}


function bookName(){

    return (
        books()[
            state.bookNum - 1
        ] ||
        ""
    );
}


function chapterCount(){

    return (
        CHAPTER_COUNTS[
            state.bookNum - 1
        ] ||
        1
    );
}


function bibleVersion(){

    return state.language === "sw"
        ? "SUV"
        : "FR";
}


function versionLabel(){

    return state.language === "sw"
        ? "SW"
        : "FR";
}


/* ==========================================================
   OPTIONS LIVRES
   ========================================================== */

function bookOptions(){

    return books()
        .map(
            function(name,index){

                const num =
                    index + 1;


                return `
                    <option
                        value="${num}"
                        ${
                            num ===
                            state.bookNum
                                ? "selected"
                                : ""
                        }>

                        ${esc(name)}

                    </option>
                `;

            }
        )
        .join("");
}


/* ==========================================================
   OPTIONS CHAPITRES
   ========================================================== */

function chapterOptions(){

    const max =
        chapterCount();


    /*
     * Protection si on change de livre.
     */

    if(state.chapter > max){

        state.chapter =
            max;
    }


    if(state.chapter < 1){

        state.chapter =
            1;
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
                    chapter ===
                    state.chapter
                        ? "selected"
                        : ""
                }>

                Chapitre ${chapter}

            </option>
        `;
    }


    return html;
}


/* ==========================================================
   INTERFACE
   ========================================================== */

function shell(){

    const maxChapter =
        chapterCount();


    return `
        <div class="mbible">

            <!-- LANGUES -->

            <div class="mbible-languages">

                <button
                    type="button"
                    class="mbible-language ${
                        state.language === "fr"
                            ? "active"
                            : ""
                    }"
                    data-bible-language="fr">

                    Français

                </button>


                <button
                    type="button"
                    class="mbible-language ${
                        state.language === "sw"
                            ? "active"
                            : ""
                    }"
                    data-bible-language="sw">

                    Kiswahili

                </button>

            </div>


            <!-- LIVRE + CHAPITRE -->

            <div class="mbible-controls">

                <div class="mbible-field">

                    <label>
                        Livre
                    </label>

                    <select
                        id="mbible-book"
                        class="mbible-select">

                        ${bookOptions()}

                    </select>

                </div>


                <div class="mbible-field">

                    <label>
                        Chapitre
                    </label>

                    <select
                        id="mbible-chapter"
                        class="mbible-select">

                        ${chapterOptions()}

                    </select>

                </div>

            </div>


            <!-- NAVIGATION -->

            <div class="mbible-navigation">

                <button
                    type="button"
                    class="mbible-nav"
                    data-bible-prev
                    ${
                        state.chapter <= 1
                            ? "disabled"
                            : ""
                    }>

                    ← Chapitre précédent

                </button>


                <button
                    type="button"
                    class="mbible-nav"
                    data-bible-next
                    ${
                        state.chapter >= maxChapter
                            ? "disabled"
                            : ""
                    }>

                    Chapitre suivant →

                </button>

            </div>


            <!-- TITRE -->

            <div class="mbible-heading">

                <div class="mbible-reference">

                    ${esc(bookName())}
                    ${state.chapter}

                </div>


                <div class="mbible-version">

                    ${versionLabel()}

                </div>

            </div>


            <!-- TEXTE -->

            <div id="mbible-content">

                <div class="mbible-loading">
                    Chargement du chapitre...
                </div>

            </div>

        </div>
    `;
}


/* ==========================================================
   CHARGER LE CHAPITRE
   ========================================================== */

async function loadChapter(){

    const content =
        document.getElementById(
            "mbible-content"
        );


    if(!content){
        return;
    }


    content.innerHTML = `
        <div class="mbible-loading">

            ${
                state.language === "sw"
                    ? "Inapakia sura..."
                    : "Chargement du chapitre..."
            }

        </div>
    `;


    try{

        const url =
            "/api/bible/" +
            state.bookNum +
            "/" +
            state.chapter +
            "?version=" +
            encodeURIComponent(
                bibleVersion()
            );


        const response =
            await fetch(
                url,
                {
                    cache:"no-store"
                }
            );


        let result = {};


        try{

            result =
                await response.json();

        }catch(_error){}


        if(
            !response.ok ||
            !Array.isArray(
                result.verses
            )
        ){

            throw new Error(
                result.error ||
                "Chapitre indisponible."
            );
        }


        state.verses =
            result.verses;


        if(!state.verses.length){

            content.innerHTML = `
                <div class="mbible-empty">

                    ${
                        state.language === "sw"
                            ? "Hakuna mistari katika sura hii."
                            : "Aucun verset disponible."
                    }

                </div>
            `;


            return;
        }


        content.innerHTML = `
            <div class="mbible-passage">

                ${
                    state.verses
                    .map(
                        function(item){

                            return `
                                <div class="mbible-verse">

                                    <span class="mbible-verse-number">
                                        ${esc(item.verse)}
                                    </span>


                                    <div class="mbible-verse-text">
                                        ${formatBibleText(item.text)}
                                    </div>

                                </div>
                            `;

                        }
                    )
                    .join("")
                }

            </div>
        `;


        console.log(
            "[MARANATHA BIBLE]",
            state.language,
            bookName(),
            state.chapter,
            result.version ||
            bibleVersion()
        );


    }catch(error){

        console.error(
            "[MARANATHA BIBLE]",
            error
        );


        content.innerHTML = `
            <div class="mbible-error">

                ${
                    state.language === "sw"
                        ? "Imeshindikana kupakia "
                        : "Impossible de charger "
                }

                ${esc(bookName())}
                ${state.chapter}.

                <br><br>

                ${esc(error.message)}

            </div>
        `;
    }
}


/* ==========================================================
   EVENEMENTS
   ========================================================== */

function bind(){

    /*
     * Langue
     */

    document.querySelectorAll(
        "[data-bible-language]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    const language =
                        button.dataset.bibleLanguage;


                    if(
                        language ===
                        state.language
                    ){
                        return;
                    }


                    state.language =
                        language;


                    localStorage.setItem(
                        LANGUAGE_KEY,
                        language
                    );


                    /*
                     * Conserver le même numéro de livre
                     * et le même chapitre.
                     */

                    const max =
                        chapterCount();


                    if(state.chapter > max){

                        state.chapter =
                            max;
                    }


                    renderBible();
                }
            );
        }
    );


    /*
     * Livre
     */

    document.getElementById(
        "mbible-book"
    )?.addEventListener(
        "change",
        function(event){

            const value =
                parseInt(
                    event.target.value,
                    10
                );


            if(!value){
                return;
            }


            state.bookNum =
                value;


            /*
             * Nouveau livre :
             * commencer au chapitre 1.
             */

            state.chapter =
                1;


            renderBible();
        }
    );


    /*
     * Chapitre
     */

    document.getElementById(
        "mbible-chapter"
    )?.addEventListener(
        "change",
        function(event){

            const chapter =
                parseInt(
                    event.target.value,
                    10
                );


            if(
                !chapter ||
                chapter < 1 ||
                chapter >
                    chapterCount()
            ){
                return;
            }


            state.chapter =
                chapter;


            renderBible();
        }
    );


    /*
     * Chapitre précédent
     */

    document.querySelector(
        "[data-bible-prev]"
    )?.addEventListener(
        "click",
        function(){

            if(state.chapter <= 1){
                return;
            }


            state.chapter--;


            renderBible();
        }
    );


    /*
     * Chapitre suivant
     */

    document.querySelector(
        "[data-bible-next]"
    )?.addEventListener(
        "click",
        function(){

            if(
                state.chapter >=
                chapterCount()
            ){
                return;
            }


            state.chapter++;


            renderBible();
        }
    );
}


/* ==========================================================
   RENDU
   ========================================================== */

function renderBible(){

    const body =
        document.getElementById(
            "m-sheet-body"
        ) ||
        document.querySelector(
            ".m-sheet-body"
        );


    if(!body){
        return;
    }


    body.innerHTML =
        shell();


    bind();


    loadChapter();
}


/* ==========================================================
   OUVRIR BIBLE
   ========================================================== */

function openBible(){

    if(
        typeof window.openSheet !==
        "function"
    ){

        console.error(
            "[MARANATHA Bible] openSheet introuvable"
        );

        return;
    }


    window.openSheet(
        "Bible",
        '<div id="maranatha-bible-v3"></div>'
    );


    setTimeout(
        renderBible,
        0
    );
}


/* ==========================================================
   EXPOSITION POUR LE BRIDGE
   ========================================================== */

window.openMaranathaBible =
    openBible;


window.renderMaranathaBible =
    renderBible;


window.showBible =
    openBible;


/* ==========================================================
   BOUTON BIBLE
   ========================================================== */

document.addEventListener(
    "click",
    function(event){

        const trigger =
            event.target.closest(
                'a[href="#bible"],' +
                '[href="#bible"],' +
                '[onclick*="showBible"]'
            );


        if(!trigger){
            return;
        }


        /*
         * Le bridge actuel reste également actif.
         */

        setTimeout(
            function(){

                const body =
                    document.getElementById(
                        "m-sheet-body"
                    ) ||
                    document.querySelector(
                        ".m-sheet-body"
                    );


                if(
                    body &&
                    !body.querySelector(
                        ".mbible"
                    )
                ){

                    renderBible();
                }

            },
            50
        );

    },
    false
);


console.log(
    "[MARANATHA] Bible FR/SW V3 active"
);

})();