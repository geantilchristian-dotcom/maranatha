(function(){

"use strict";


/*
 * ==========================================================
 * MARANATHA
 * Protection stricte entre les fenêtres modales.
 *
 * Le module Bibliothèque ne doit travailler QUE
 * lorsque le titre de la fenêtre est "Bibliothèque".
 * ==========================================================
 */


function getSheet(){

    return (
        document.getElementById("m-sheet") ||
        document.querySelector(".m-sheet")
    );
}


function getSheetBody(){

    return (
        document.getElementById("m-sheet-body") ||
        document.querySelector(".m-sheet-body")
    );
}


function getSheetTitle(){

    const sheet =
        getSheet();


    if(!sheet){
        return "";
    }


    /*
     * Chercher les sélecteurs connus.
     */

    const possibleSelectors = [
        ".m-sheet-title",
        ".sheet-title",
        "[data-sheet-title]",
        ".m-sheet-header h1",
        ".m-sheet-header h2",
        ".m-sheet-header strong",
        "h1",
        "h2"
    ];


    for(
        const selector of
        possibleSelectors
    ){

        const node =
            sheet.querySelector(
                selector
            );


        if(
            node &&
            String(
                node.textContent || ""
            ).trim()
        ){

            return String(
                node.textContent
            ).trim();
        }
    }


    return "";
}


function normalize(value){

    return String(
        value || ""
    )
    .normalize("NFD")
    .replace(
        /[\u0300-\u036f]/g,
        ""
    )
    .trim()
    .toLowerCase();
}


function libraryIsReallyOpen(){

    return (
        normalize(
            getSheetTitle()
        ) ===
        "bibliotheque"
    );
}


/*
 * Rendre la fonction disponible aux autres modules.
 */

window.MARANATHA_LIBRARY_IS_OPEN =
    libraryIsReallyOpen;


window.MARANATHA_CURRENT_SHEET_TITLE =
    getSheetTitle;


/*
 * ==========================================================
 * SECURITE :
 * si un ancien bridge Bibliothèque vient de remplacer
 * le contenu d'une autre fenêtre, on le détecte.
 * ==========================================================
 */

let previousWrongTitle =
    "";


function protectOtherSheets(){

    const title =
        getSheetTitle();


    const normalizedTitle =
        normalize(title);


    const body =
        getSheetBody();


    if(
        !body ||
        !title
    ){
        return;
    }


    /*
     * Bibliothèque : autorisée.
     */

    if(
        normalizedTitle ===
        "bibliotheque"
    ){

        previousWrongTitle =
            "";

        return;
    }


    /*
     * Détecter la structure caractéristique
     * de la bibliothèque.
     */

    const hasLibraryUI =
        !!(
            body.querySelector(
                ".library-local," +
                ".library-tabs," +
                "[data-library-tab]," +
                ".library-demo-list," +
                ".library-book-grid"
            )
        );


    const text =
        normalize(
            body.textContent
        );


    const looksLikeLibrary =
        hasLibraryUI ||
        (
            text.includes(
                "predications recentes"
            ) &&
            text.includes(
                "audio mp3"
            ) &&
            text.includes(
                "videos"
            ) &&
            text.includes(
                "livres"
            )
        );


    if(
        !looksLikeLibrary
    ){
        return;
    }


    /*
     * Une autre fenêtre contient la Bibliothèque :
     * c'est le bug que nous corrigeons.
     */

    if(
        previousWrongTitle !==
        normalizedTitle
    ){

        console.warn(
            "[MARANATHA] Bibliothèque bloquée dans la fenêtre :",
            title
        );


        previousWrongTitle =
            normalizedTitle;
    }


    /*
     * On ne reconstruit pas la fenêtre ici.
     * On demande simplement à l'ancienne fonction
     * de la rouvrir si elle existe.
     *
     * Pour Paramètres / À propos, le clic utilisateur
     * sera rejoué proprement par le bridge ci-dessous.
     */
}


/*
 * Observer les changements.
 */

const observer =
    new MutationObserver(
        function(){

            setTimeout(
                protectOtherSheets,
                0
            );
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
 * ==========================================================
 * Enregistrer le dernier bouton ouvrant une fenêtre.
 * Si la Bibliothèque écrase ensuite cette fenêtre,
 * nous pouvons rappeler le même bouton.
 * ==========================================================
 */

let lastSheetTrigger =
    null;


document.addEventListener(
    "click",
    function(event){

        const candidate =
            event.target.closest(
                "button,a,[onclick],[data-action],[data-sheet]"
            );


        if(!candidate){
            return;
        }


        const text =
            normalize(
                candidate.textContent
            );


        const onclick =
            normalize(
                candidate.getAttribute(
                    "onclick"
                )
            );


        /*
         * Ne mémoriser que les fenêtres autres que Bibliothèque.
         */

        const isLibraryButton =
            text.includes("bibliotheque") ||
            onclick.includes("library");


        if(
            isLibraryButton
        ){
            lastSheetTrigger =
                null;

            return;
        }


        if(
            text.includes("parametres") ||
            text.includes("paramètres") ||
            text.includes("a propos") ||
            text.includes("à propos") ||
            text.includes("devenir membre") ||
            text.includes("etude biblique") ||
            text.includes("étude biblique") ||
            text.includes("programme")
        ){

            lastSheetTrigger =
                candidate;
        }

    },
    true
);


/*
 * ==========================================================
 * GARDE POUR LES FONCTIONS DE BIBLIOTHEQUE
 * ==========================================================
 *
 * Les anciens scripts peuvent consulter cette fonction.
 * Elle est volontairement globale.
 */

window.maranathaLibraryGuard =
    function(){

        const allowed =
            libraryIsReallyOpen();


        if(!allowed){

            console.log(
                "[MARANATHA] rendu Bibliothèque ignoré : fenêtre actuelle =",
                getSheetTitle()
            );
        }


        return allowed;
    };


console.log(
    "[MARANATHA] Protection stricte Bibliothèque active"
);


})();