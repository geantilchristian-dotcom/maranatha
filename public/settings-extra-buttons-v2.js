(function(){

"use strict";


const ENDPOINT =
    "/api/settings/app-config";


let installTimer =
    null;


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


function esc(value){

    return String(
        value == null ? "" : value
    )
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;");
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


function getTitle(){

    if(
        typeof window.MARANATHA_CURRENT_SHEET_TITLE ===
        "function"
    ){

        const title =
            window.MARANATHA_CURRENT_SHEET_TITLE();


        if(title){
            return title;
        }
    }


    const sheet =
        getSheet();


    if(!sheet){
        return "";
    }


    const possible = [

        ".m-sheet-title",
        ".sheet-title",
        "[data-sheet-title]",
        ".m-sheet-header h1",
        ".m-sheet-header h2",
        ".m-sheet-head h1",
        ".m-sheet-head h2"

    ];


    for(
        const selector of possible
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


function settingsOpen(){

    return (
        normalize(
            getTitle()
        ) ===
        "parametres"
    );
}


/* ==========================================================
   TROUVER LE BOUTON A PROPOS
   ========================================================== */

function findAboutLabel(){

    const body =
        getBody();


    if(!body){
        return null;
    }


    const nodes =
        body.querySelectorAll(
            "button,a,div,span,p"
        );


    for(
        const node of nodes
    ){

        if(
            normalize(
                node.textContent
            ) ===
            "a propos de maranatha"
        ){

            return node;
        }
    }


    return null;
}


function findRow(label){

    if(!label){
        return null;
    }


    /*
     * Cas le plus courant :
     * la ligne est un button ou un lien.
     */

    let row =
        label.closest(
            "button,a,[role='button']"
        );


    if(row){
        return row;
    }


    /*
     * Sinon on cherche une classe de ligne Paramètres.
     */

    row =
        label.closest(
            ".settings-row," +
            ".setting-row," +
            ".m-settings-row," +
            ".m-setting-row," +
            ".settings-item," +
            ".setting-item," +
            ".m-settings-item"
        );


    if(row){
        return row;
    }


    /*
     * Dernier recours :
     * remonter jusqu'à trouver un élément
     * avec plusieurs enfants.
     */

    let current =
        label;


    for(
        let i = 0;
        i < 5 && current;
        i++
    ){

        current =
            current.parentElement;


        if(
            current &&
            current.children.length >= 2
        ){

            return current;
        }
    }


    return label.parentElement;
}


/* ==========================================================
   NETTOYER UN CLONE
   ========================================================== */

function cleanupClone(node){

    if(!node){
        return;
    }


    if(node.id){
        node.removeAttribute("id");
    }


    node.removeAttribute("onclick");
    node.removeAttribute("href");


    node
        .querySelectorAll("*")
        .forEach(
            function(child){

                if(child.id){
                    child.removeAttribute("id");
                }


                child.removeAttribute(
                    "onclick"
                );


                child.removeAttribute(
                    "href"
                );
            }
        );
}


function replaceVisibleLabel(
    row,
    oldText,
    newText
){

    const all =
        row.querySelectorAll(
            "*"
        );


    for(
        const node of all
    ){

        if(
            normalize(
                node.textContent
            ) ===
            normalize(
                oldText
            )
        ){

            /*
             * Préférer le plus petit élément texte.
             */

            const childSame =
                Array.from(
                    node.children || []
                )
                .some(
                    function(child){

                        return (
                            normalize(
                                child.textContent
                            ) ===
                            normalize(
                                oldText
                            )
                        );
                    }
                );


            if(!childSame){

                node.textContent =
                    newText;

                return;
            }
        }
    }


    /*
     * Cas simple : texte direct.
     */

    if(
        normalize(
            row.textContent
        ) ===
        normalize(
            oldText
        )
    ){

        row.textContent =
            newText;
    }
}


/* ==========================================================
   CREER LES DEUX NOUVELLES LIGNES
   ========================================================== */

function createRow(
    source,
    type,
    label
){

    const row =
        source.cloneNode(true);


    cleanupClone(
        row
    );


    row.setAttribute(
        "data-maranatha-settings-extra",
        type
    );


    replaceVisibleLabel(
        row,
        "À propos de Maranatha",
        label
    );


    /*
     * Si le clone est un div,
     * le rendre accessible au clavier.
     */

    if(
        row.tagName !== "BUTTON" &&
        row.tagName !== "A"
    ){

        row.setAttribute(
            "role",
            "button"
        );


        row.setAttribute(
            "tabindex",
            "0"
        );
    }


    row.addEventListener(
        "click",
        function(event){

            event.preventDefault();
            event.stopPropagation();
            event.stopImmediatePropagation();


            openDocument(
                type
            );
        },
        true
    );


    row.addEventListener(
        "keydown",
        function(event){

            if(
                event.key === "Enter" ||
                event.key === " "
            ){

                event.preventDefault();


                openDocument(
                    type
                );
            }
        }
    );


    return row;
}


/* ==========================================================
   INSTALLER DANS PARAMETRES
   ========================================================== */

function installButtons(){

    if(
        !settingsOpen()
    ){
        return;
    }


    const body =
        getBody();


    if(!body){
        return;
    }


    /*
     * Déjà installés.
     */

    if(
        body.querySelector(
            '[data-maranatha-settings-extra="terms"]'
        ) &&
        body.querySelector(
            '[data-maranatha-settings-extra="help"]'
        )
    ){

        return;
    }


    const label =
        findAboutLabel();


    if(!label){
        return;
    }


    const aboutRow =
        findRow(
            label
        );


    if(
        !aboutRow ||
        !aboutRow.parentElement
    ){
        return;
    }


    const parent =
        aboutRow.parentElement;


    /*
     * Conditions d'utilisation
     */

    if(
        !body.querySelector(
            '[data-maranatha-settings-extra="terms"]'
        )
    ){

        const terms =
            createRow(
                aboutRow,
                "terms",
                "Conditions d’utilisation"
            );


        parent.insertBefore(
            terms,
            aboutRow
        );
    }


    /*
     * Aide & support
     */

    if(
        !body.querySelector(
            '[data-maranatha-settings-extra="help"]'
        )
    ){

        const help =
            createRow(
                aboutRow,
                "help",
                "Aide & support"
            );


        parent.insertBefore(
            help,
            aboutRow
        );
    }


    console.log(
        "[MARANATHA] Boutons Conditions + Aide installés"
    );
}


/* ==========================================================
   CHARGER LES PARAMETRES
   ========================================================== */

async function loadConfig(){

    const response =
        await fetch(
            ENDPOINT,
            {
                cache:"no-store"
            }
        );


    if(!response.ok){

        throw new Error(
            "Impossible de charger les paramètres."
        );
    }


    return response.json();
}


/* ==========================================================
   WHATSAPP SUPPORT
   ========================================================== */

function whatsappUrl(phone){

    let digits =
        String(
            phone || ""
        )
        .replace(/\D/g,"");


    if(
        digits.startsWith("0")
    ){

        digits =
            "243" +
            digits.substring(1);
    }


    if(
        digits.length === 9
    ){

        digits =
            "243" +
            digits;
    }


    if(!digits){
        return "";
    }


    return (
        "https://wa.me/" +
        digits
    );
}


/* ==========================================================
   OUVRIR UN DOCUMENT
   ========================================================== */

async function openDocument(type){

    let title = "";
    let field = "";


    if(type === "terms"){

        title =
            "Conditions d’utilisation";

        field =
            "terms";
    }


    if(type === "help"){

        title =
            "Aide & support";

        field =
            "help";
    }


    if(
        !title ||
        !field
    ){
        return;
    }


    try{

        const config =
            await loadConfig();


        const documents =
            config.documents || {};


        const application =
            config.application || {};


        const contact =
            config.contact || {};


        const text =
            String(
                documents[field] ||
                ""
            ).trim();


        let content = `
            <div
                class="maranatha-public-document">

        `;


        if(text){

            content += `
                <div
                    class="mpd-content">

                    ${esc(text)}

                </div>
            `;

        }else{

            content += `
                <div
                    class="mpd-empty">

                    Ce contenu n'a pas encore
                    été publié par MARANATHA.

                </div>
            `;
        }


        /*
         * Pour Aide & support,
         * ajouter automatiquement
         * les coordonnées administratives.
         */

        if(type === "help"){

            const supportEmail =
                application.supportEmail ||
                contact.email ||
                "";


            const supportWhatsapp =
                application.supportWhatsapp ||
                contact.whatsapp ||
                contact.phone ||
                "";


            const wa =
                whatsappUrl(
                    supportWhatsapp
                );


            if(
                supportEmail ||
                supportWhatsapp
            ){

                content += `
                    <div
                        style="
                            margin-top:16px;
                            padding:13px;
                            background:#f5f5f7;
                            border-radius:12px;
                        ">

                        <div
                            style="
                                margin-bottom:8px;
                                font-weight:800;
                                color:#29292f;
                            ">

                            Contacter MARANATHA

                        </div>
                `;


                if(supportWhatsapp){

                    content += `
                        <div
                            style="
                                margin-bottom:8px;
                                font-size:11px;
                                color:#65656c;
                            ">

                            WhatsApp :
                            ${esc(supportWhatsapp)}

                        </div>
                    `;


                    if(wa){

                        content += `
                            <a
                                href="${esc(wa)}"
                                target="_blank"
                                rel="noopener noreferrer"
                                style="
                                    display:inline-flex;
                                    align-items:center;
                                    justify-content:center;
                                    min-height:36px;
                                    padding:0 13px;
                                    border-radius:9px;
                                    background:#25D366;
                                    color:white;
                                    font-size:10px;
                                    font-weight:800;
                                    text-decoration:none;
                                ">

                                Ouvrir WhatsApp

                            </a>
                        `;
                    }
                }


                if(supportEmail){

                    content += `
                        <div
                            style="
                                margin-top:9px;
                                font-size:11px;
                                color:#65656c;
                            ">

                            E-mail :
                            ${esc(supportEmail)}

                        </div>
                    `;
                }


                content += `
                    </div>
                `;
            }
        }


        content += `
            </div>
        `;


        if(
            typeof window.openSheet ===
            "function"
        ){

            window.openSheet(
                title,
                content
            );

        }else{
            const body =
                getBody();
            if(body){
                body.innerHTML =
                    content;
            }else{
                console.warn(
                    "[MARANATHA SETTINGS] Contenu indisponible"
                );
            }
        }


    }catch(error){

        console.error(
            "[MARANATHA SETTINGS EXTRA]",
            error
        );


        alert(
            error.message
        );
    }
}


/* ==========================================================
   SURVEILLANCE
   ========================================================== */

function scheduleInstall(){

    clearTimeout(
        installTimer
    );


    installTimer =
        setTimeout(
            installButtons,
            40
        );
}


const observer =
    new MutationObserver(
        scheduleInstall
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


document.addEventListener(
    "click",
    function(){

        setTimeout(
            installButtons,
            30
        );


        setTimeout(
            installButtons,
            150
        );


        setTimeout(
            installButtons,
            400
        );

    },
    false
);


console.log(
    "[MARANATHA] Nouveaux boutons Paramètres V2 actifs"
);


})();