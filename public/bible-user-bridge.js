(function(){

"use strict";


let timer = null;


/* ==========================================================
   OUTILS
   ========================================================== */

function normalize(value){

    return String(
        value || ""
    )
    .normalize("NFD")
    .replace(
        /[\u0300-\u036f]/g,
        ""
    )
    .replace(/\s+/g," ")
    .trim()
    .toLowerCase();
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


/* ==========================================================
   TITRE EXACT DE LA FENETRE
   ========================================================== */

function getTitle(){

    /*
     * Le guard Bibliothèque installé précédemment
     * sait déjà récupérer correctement le titre.
     */

    if(
        typeof window.MARANATHA_CURRENT_SHEET_TITLE ===
        "function"
    ){

        const title =
            window.MARANATHA_CURRENT_SHEET_TITLE();


        if(title){

            return String(title).trim();
        }
    }


    const sheet =
        getSheet();


    if(!sheet){

        return "";
    }


    const selectors = [

        ".m-sheet-title",

        ".sheet-title",

        "[data-sheet-title]",

        ".m-sheet-header .m-title",

        ".m-sheet-header h1",

        ".m-sheet-header h2",

        ".m-sheet-header strong",

        ".m-sheet-head h1",

        ".m-sheet-head h2"

    ];


    for(
        const selector of selectors
    ){

        const element =
            sheet.querySelector(
                selector
            );


        if(
            element &&
            String(
                element.textContent || ""
            ).trim()
        ){

            return String(
                element.textContent
            ).trim();
        }
    }


    /*
     * Dernier secours :
     * prendre seulement le début du texte du header,
     * jamais tout le contenu de la fenêtre.
     */

    const header =
        sheet.querySelector(
            ".m-sheet-header," +
            ".m-sheet-head," +
            "header"
        );


    if(header){

        const text =
            String(
                header.textContent || ""
            )
            .replace(/\s+/g," ")
            .trim();


        const withoutBrand =
            text.replace(
                /^MARANATHA\s*/i,
                ""
            )
            .trim();


        return withoutBrand;
    }


    return "";
}


/* ==========================================================
   REGLE ABSOLUE
   ========================================================== */

function bibleIsReallyOpen(){

    const title =
        normalize(
            getTitle()
        );


    /*
     * IMPORTANT :
     * aucune recherche dans le contenu de la fenêtre.
     *
     * La Bible n'est autorisée QUE si le titre
     * de la fenêtre est exactement "Bible".
     */

    return (
        title === "bible"
    );
}


/* ==========================================================
   RENDU
   ========================================================== */

function installBible(){

    clearTimeout(timer);


    const title =
        getTitle();


    if(
        !bibleIsReallyOpen()
    ){

        /*
         * On ne touche absolument à rien.
         */

        return;
    }


    const body =
        getBody();


    if(!body){

        return;
    }


    /*
     * Déjà rendue.
     */

    if(
        body.querySelector(
            ".mbible"
        )
    ){

        return;
    }


    if(
        typeof window.renderMaranathaBible !==
        "function"
    ){

        console.error(
            "[MARANATHA Bible] renderMaranathaBible introuvable"
        );

        return;
    }


    console.log(
        "[MARANATHA Bible] fenêtre confirmée :",
        title
    );


    window.renderMaranathaBible();
}


/* ==========================================================
   PLANIFICATION
   ========================================================== */

function schedule(){

    clearTimeout(timer);


    timer =
        setTimeout(
            installBible,
            30
        );
}


/* ==========================================================
   OBSERVER LES FENETRES
   ========================================================== */

const observer =
    new MutationObserver(
        function(){

            /*
             * Même lorsqu'une autre fenêtre change,
             * installBible() vérifiera d'abord le titre exact.
             */

            schedule();
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


/* ==========================================================
   APRES UN CLIC
   ========================================================== */

document.addEventListener(
    "click",
    function(){

        setTimeout(
            installBible,
            30
        );


        setTimeout(
            installBible,
            120
        );


        setTimeout(
            installBible,
            350
        );

    },
    false
);


/* ==========================================================
   EXPOSITION DEBUG
   ========================================================== */

window.MARANATHA_BIBLE_IS_OPEN =
    bibleIsReallyOpen;


window.MARANATHA_BIBLE_SHEET_TITLE =
    getTitle;


console.log(
    "[MARANATHA] Bridge Bible STRICT actif"
);


})();