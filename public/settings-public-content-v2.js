(function(){

"use strict";

const ENDPOINT =
    "/api/settings/app-config";


function esc(value){

    return String(
        value == null ? "" : value
    )
    .replace(/&/g,"&amp;")
    .replace(/</g,"&lt;")
    .replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;");
}


async function getSettings(){

    const response =
        await fetch(
            ENDPOINT,
            {
                cache:"no-store"
            }
        );


    if(!response.ok){

        throw new Error(
            "Impossible de charger les informations."
        );
    }


    return response.json();
}


function contactHtml(config){

    const contact =
        config.contact || {};


    const parts = [];


    if(contact.address){

        parts.push(
            "<strong>Adresse :</strong> " +
            esc(contact.address)
        );
    }


    if(contact.phone){

        parts.push(
            "<strong>Téléphone :</strong> " +
            esc(contact.phone)
        );
    }


    if(contact.email){

        parts.push(
            "<strong>E-mail :</strong> " +
            esc(contact.email)
        );
    }


    if(!parts.length){
        return "";
    }


    return `
        <div class="mpd-contact">
            ${parts.join("<br>")}
        </div>
    `;
}


async function showDocument(
    title,
    documentKey
){

    try {

        const config =
            await getSettings();


        const documents =
            config.documents || {};


        const identity =
            config.identity || {};


        const text =
            String(
                documents[documentKey] ||
                ""
            ).trim();


        let body = `
            <div class="maranatha-public-document">
        `;


        if(
            documentKey ===
            "about"
        ){

            body += `
                <div class="mpd-name">
                    ${esc(
                        identity.churchName ||
                        "CEMM MARANATHA"
                    )}
                </div>

                <div class="mpd-intro">
                    ${esc(
                        identity.ministryName ||
                        ""
                    )}
                </div>
            `;
        }


        if(text){

            body += `
                <div class="mpd-content">
                    ${esc(text)}
                </div>
            `;

        }else{

            body += `
                <div class="mpd-empty">
                    Ce contenu n'a pas encore
                    été publié par MARANATHA.
                </div>
            `;
        }


        if(
            documentKey ===
            "about"
        ){

            body +=
                contactHtml(config);
        }


        body += "</div>";


        if(
            typeof window.openSheet ===
            "function"
        ){

            window.openSheet(
                title,
                body
            );

            return;
        }


        alert(
            text ||
            "Contenu indisponible."
        );


    } catch(error){

        console.error(
            "[MARANATHA PUBLIC SETTINGS]",
            error
        );


        alert(
            error.message
        );
    }
}


function normalize(text){

    return String(
        text || ""
    )
    .replace(/\s+/g," ")
    .trim()
    .toLowerCase();
}


function identifyAction(target){

    let node = target;


    for(
        let i = 0;
        node &&
        node !== document.body &&
        i < 7;
        i++,
        node = node.parentElement
    ){

        const text =
            normalize(
                node.textContent
            );


        if(
            text ===
            "confidentialité et données" ||
            text ===
            "confidentialite et donnees"
        ){

            return "privacy";
        }


        if(
            text ===
            "à propos de maranatha" ||
            text ===
            "a propos de maranatha"
        ){

            return "about";
        }
    }


    return null;
}


document.addEventListener(
    "click",
    function(event){

        const action =
            identifyAction(
                event.target
            );


        if(!action){
            return;
        }


        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();


        if(action === "privacy"){

            /* MARANATHA_PRIVACY_ABOUT_PAGES_V1 */

            if(
                window.MaranathaInfoPages &&
                typeof window.MaranathaInfoPages.open === "function"
            ){
                window.MaranathaInfoPages.open("privacy");
            }

            return;
        }


        if(action === "about"){

            if(
                window.MaranathaInfoPages &&
                typeof window.MaranathaInfoPages.open === "function"
            ){
                window.MaranathaInfoPages.open("about");
            }

            return;
        }

    },
    true
);


console.log(
    "[MARANATHA] Contenus Paramètres publics actifs"
);

})();