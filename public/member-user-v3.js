(function(){

"use strict";


const STORAGE_KEY =
    "maranatha_membership_requests_v2";


let step = 1;


let form = {
    nom:"",
    eglise:"",
    residence:"",
    fonction:"",
    fonctionAutre:"",
    telephone:"",
    pretAServir:""
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


function getBody(){

    return (
        document.getElementById("m-sheet-body") ||
        document.querySelector(".m-sheet-body")
    );
}


function getSheet(){

    return (
        document.getElementById("m-sheet") ||
        document.querySelector(".m-sheet")
    );
}


function membershipIsOpen(){

    const sheet =
        getSheet();


    if(!sheet){
        return false;
    }


    return String(
        sheet.textContent || ""
    )
    .replace(/\s+/g," ")
    .toLowerCase()
    .includes("devenir membre");
}


function finalRole(){

    if(form.fonction === "Autres"){

        return (
            form.fonctionAutre ||
            "Autres"
        );
    }


    return form.fonction;
}


/* ==========================================================
   STORAGE
   ========================================================== */

function readRequests(){

    try{

        const raw =
            localStorage.getItem(
                STORAGE_KEY
            );


        const result =
            raw
                ? JSON.parse(raw)
                : [];


        return Array.isArray(result)
            ? result
            : [];


    }catch(_error){

        return [];
    }
}


function writeRequests(list){

    localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(list)
    );


    window.dispatchEvent(
        new CustomEvent(
            "maranatha-membership-updated",
            {
                detail:list
            }
        )
    );
}


function saveLocal(record){

    const requests =
        readRequests();


    requests.unshift(
        record
    );


    writeRequests(
        requests
    );
}


/* ==========================================================
   PROGRESS
   ========================================================== */

function progress(){

    const percent =
        Math.min(
            100,
            step * (100 / 6)
        );


    return `
        <div class="member-v3-progress">

            <div class="member-v3-progress-track">

                <div
                    class="member-v3-progress-fill"
                    style="width:${percent}%">
                </div>

            </div>


            <div class="member-v3-progress-label">
                ${step}/6
            </div>

        </div>
    `;
}


function actions(
    label = "Continuer"
){

    return `
        <div class="member-v3-actions">

            ${
                step > 1
                    ? `
                        <button
                            type="button"
                            class="member-v3-btn member-v3-btn-back"
                            data-member-v3-back>

                            Retour

                        </button>
                    `
                    : ""
            }


            <button
                type="button"
                class="member-v3-btn member-v3-btn-primary"
                data-member-v3-next>

                ${esc(label)}

            </button>

        </div>
    `;
}


/* ==========================================================
   STEPS
   ========================================================== */

function stepOne(){

    return `
        ${progress()}

        <div class="member-v3-step">

            <div class="member-v3-question">
                Quel est votre nom et post-nom ?
            </div>

            <div class="member-v3-help">
                Indiquez votre identité complète.
            </div>


            <input
                id="member-v3-name"
                class="member-v3-input"
                type="text"
                autocomplete="name"
                value="${esc(form.nom)}"
                placeholder="Nom et post-nom">


            ${actions()}

        </div>
    `;
}


function stepTwo(){

    return `
        ${progress()}

        <div class="member-v3-step">

            <div class="member-v3-question">
                Quelle est votre église de provenance ?
            </div>

            <div class="member-v3-help">
                Indiquez l'église que vous fréquentez ou fréquentiez.
            </div>


            <input
                id="member-v3-church"
                class="member-v3-input"
                type="text"
                value="${esc(form.eglise)}"
                placeholder="Nom de l'église">


            ${actions()}

        </div>
    `;
}


function stepThree(){

    return `
        ${progress()}

        <div class="member-v3-step">

            <div class="member-v3-question">
                Quel est votre lieu de résidence ?
            </div>

            <div class="member-v3-help">
                Indiquez votre commune, quartier ou avenue.
            </div>


            <input
                id="member-v3-residence"
                class="member-v3-input"
                type="text"
                autocomplete="street-address"
                value="${esc(form.residence)}"
                placeholder="Ex : Bagira, Nyakavogo">


            ${actions()}

        </div>
    `;
}


function stepFour(){

    const roles = [
        "Pasteur",
        "Évangéliste",
        "Musicien",
        "Diacre",
        "Fidèle",
        "Autres"
    ];


    return `
        ${progress()}

        <div class="member-v3-step">

            <div class="member-v3-question">
                Quelle est votre fonction ?
            </div>

            <div class="member-v3-help">
                Choisissez la fonction qui vous correspond.
            </div>


            <div class="member-v3-options">

                ${
                    roles.map(
                        function(role){

                            return `
                                <button
                                    type="button"
                                    class="member-v3-option ${
                                        form.fonction === role
                                            ? "active"
                                            : ""
                                    }"
                                    data-member-v3-role="${esc(role)}">

                                    <span class="member-v3-radio"></span>

                                    ${esc(role)}

                                </button>
                            `;

                        }
                    ).join("")
                }

            </div>


            ${
                form.fonction === "Autres"
                    ? `
                        <input
                            id="member-v3-role-other"
                            class="member-v3-input"
                            type="text"
                            style="margin-top:10px"
                            value="${esc(form.fonctionAutre)}"
                            placeholder="Précisez votre fonction">
                    `
                    : ""
            }


            ${actions()}

        </div>
    `;
}


function stepFive(){

    return `
        ${progress()}

        <div class="member-v3-step">

            <div class="member-v3-question">
                Quel est votre numéro de téléphone ?
            </div>

            <div class="member-v3-help">
                Utilisez de préférence un numéro WhatsApp actif.
            </div>


            <input
                id="member-v3-phone"
                class="member-v3-input"
                type="tel"
                inputmode="tel"
                autocomplete="tel"
                value="${esc(form.telephone)}"
                placeholder="+243 ...">


            ${actions()}

        </div>
    `;
}


function stepSix(){

    return `
        ${progress()}

        <div class="member-v3-step">

            <div class="member-v3-question">
                Êtes-vous prêt(e) à servir Dieu dans la communauté CEMM MARANATHA ?
            </div>

            <div class="member-v3-help">
                Votre réponse nous aidera à mieux vous accueillir.
            </div>


            <div class="member-v3-options">

                <button
                    type="button"
                    class="member-v3-option ${
                        form.pretAServir === "Oui"
                            ? "active"
                            : ""
                    }"
                    data-member-v3-service="Oui">

                    <span class="member-v3-radio"></span>

                    Oui, je suis prêt(e)

                </button>


                <button
                    type="button"
                    class="member-v3-option ${
                        form.pretAServir === "Non"
                            ? "active"
                            : ""
                    }"
                    data-member-v3-service="Non">

                    <span class="member-v3-radio"></span>

                    Non, pas pour le moment

                </button>

            </div>


            ${actions("Voir le récapitulatif")}

        </div>
    `;
}


/* ==========================================================
   SUMMARY
   ========================================================== */

function summaryRow(label,value){

    return `
        <div class="member-v3-summary-row">

            <div class="member-v3-summary-label">
                ${esc(label)}
            </div>

            <div class="member-v3-summary-value">
                ${esc(value || "—")}
            </div>

        </div>
    `;
}


function summary(){

    return `
        <div class="member-v3-step">

            <div class="member-v3-question">
                Vérifiez votre demande
            </div>

            <div class="member-v3-help">
                Vérifiez vos informations avant l'envoi.
            </div>


            <div class="member-v3-summary">

                ${summaryRow(
                    "Nom et post-nom",
                    form.nom
                )}

                ${summaryRow(
                    "Église de provenance",
                    form.eglise
                )}

                ${summaryRow(
                    "Lieu de résidence",
                    form.residence
                )}

                ${summaryRow(
                    "Fonction",
                    finalRole()
                )}

                ${summaryRow(
                    "Téléphone",
                    form.telephone
                )}

                ${summaryRow(
                    "Prêt(e) à servir",
                    form.pretAServir
                )}

            </div>


            <div class="member-v3-actions">

                <button
                    type="button"
                    class="member-v3-btn member-v3-btn-back"
                    data-member-v3-back>

                    Retour

                </button>


                <button
                    id="member-v3-submit"
                    type="button"
                    class="member-v3-btn member-v3-btn-primary">

                    Envoyer ma demande

                </button>

            </div>

        </div>
    `;
}


/* ==========================================================
   RENDER
   ========================================================== */

function render(){

    if(!membershipIsOpen()){
        return;
    }


    const container =
        getBody();


    if(!container){
        return;
    }


    let content = "";


    switch(step){

        case 1:
            content = stepOne();
            break;

        case 2:
            content = stepTwo();
            break;

        case 3:
            content = stepThree();
            break;

        case 4:
            content = stepFour();
            break;

        case 5:
            content = stepFive();
            break;

        case 6:
            content = stepSix();
            break;

        default:
            content = summary();
    }


    container.innerHTML = `
        <div class="member-v3">
            ${content}
        </div>
    `;


    bind();
}


/* ==========================================================
   VALIDATION
   ========================================================== */

function validateStep(){

    if(step === 1){

        form.nom =
            String(
                document.getElementById(
                    "member-v3-name"
                )?.value || ""
            ).trim();


        if(!form.nom){

            alert(
                "Veuillez indiquer votre nom et post-nom."
            );

            return false;
        }
    }


    if(step === 2){

        form.eglise =
            String(
                document.getElementById(
                    "member-v3-church"
                )?.value || ""
            ).trim();


        if(!form.eglise){

            alert(
                "Veuillez indiquer votre église de provenance."
            );

            return false;
        }
    }


    if(step === 3){

        form.residence =
            String(
                document.getElementById(
                    "member-v3-residence"
                )?.value || ""
            ).trim();


        if(!form.residence){

            alert(
                "Veuillez indiquer votre lieu de résidence."
            );

            return false;
        }
    }


    if(step === 4){

        if(!form.fonction){

            alert(
                "Veuillez choisir votre fonction."
            );

            return false;
        }


        if(form.fonction === "Autres"){

            form.fonctionAutre =
                String(
                    document.getElementById(
                        "member-v3-role-other"
                    )?.value || ""
                ).trim();


            if(!form.fonctionAutre){

                alert(
                    "Veuillez préciser votre fonction."
                );

                return false;
            }
        }
    }


    if(step === 5){

        form.telephone =
            String(
                document.getElementById(
                    "member-v3-phone"
                )?.value || ""
            ).trim();


        if(!form.telephone){

            alert(
                "Veuillez indiquer votre numéro de téléphone."
            );

            return false;
        }
    }


    if(step === 6){

        if(!form.pretAServir){

            alert(
                "Veuillez répondre à la question."
            );

            return false;
        }
    }


    return true;
}


/* ==========================================================
   BIND
   ========================================================== */

function bind(){

    document.querySelector(
        "[data-member-v3-next]"
    )?.addEventListener(
        "click",
        function(){

            if(!validateStep()){
                return;
            }


            step++;


            render();
        }
    );


    document.querySelector(
        "[data-member-v3-back]"
    )?.addEventListener(
        "click",
        function(){

            if(step > 1){
                step--;
            }


            render();
        }
    );


    document.querySelectorAll(
        "[data-member-v3-role]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    form.fonction =
                        button.dataset.memberV3Role;


                    render();
                }
            );
        }
    );


    document.querySelectorAll(
        "[data-member-v3-service]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    form.pretAServir =
                        button.dataset.memberV3Service;


                    render();
                }
            );
        }
    );


    document.getElementById(
        "member-v3-submit"
    )?.addEventListener(
        "click",
        submit
    );
}


/* ==========================================================
   SUBMIT
   ========================================================== */

async function submit(){

    const button =
        document.getElementById(
            "member-v3-submit"
        );


    if(!button){
        return;
    }


    button.disabled =
        true;


    button.textContent =
        "Envoi...";


    const record = {

        id:
            "member-" +
            Date.now(),

        nom:
            form.nom,

        egliseProvenance:
            form.eglise,

        lieuResidence:
            form.residence,

        fonction:
            finalRole(),

        telephone:
            form.telephone,

        pretAServir:
            form.pretAServir,

        statut:
            "en_attente",

        source:
            "application",

        createdAt:
            new Date().toISOString()
    };


    /*
     * Toujours sauvegarder localement.
     */

    saveLocal(
        record
    );


    /*
     * Essayer également le backend.
     */

    try{

        await fetch(
            "/api/membres",
            {
                method:"POST",

                headers:{
                    "Content-Type":
                        "application/json"
                },

                body:
                    JSON.stringify(
                        record
                    )
            }
        );

    }catch(_error){}


    /*
     * Envoyer aussi à la boîte admin si disponible.
     */

    try{

        await fetch(
            "/api/admin-inbox/public",
            {
                method:"POST",

                headers:{
                    "Content-Type":
                        "application/json"
                },

                body:
                    JSON.stringify({

                        type:
                            "demande_membre",

                        titre:
                            "Nouvelle demande d'adhésion",

                        nom:
                            record.nom,

                        telephone:
                            record.telephone,

                        message:
                            [
                                "Église : " +
                                record.egliseProvenance,

                                "Résidence : " +
                                record.lieuResidence,

                                "Fonction : " +
                                record.fonction,

                                "Prêt à servir : " +
                                record.pretAServir
                            ].join("\n"),

                        data:
                            record
                    })
            }
        );

    }catch(_error){}


    showWelcome();
}


/* ==========================================================
   WELCOME
   ========================================================== */

function showWelcome(){

    const container =
        getBody();


    if(!container){
        return;
    }


    const firstName =
        form.nom
        .split(/\s+/)
        .filter(Boolean)[0] ||
        form.nom;


    container.innerHTML = `
        <div class="member-v3">

            <div class="member-v3-success">

                <div class="member-v3-success-icon">
                    ✓
                </div>


                <div class="member-v3-success-title">
                    Bienvenue à CEMM MARANATHA
                </div>


                <div class="member-v3-success-text">

                    Merci
                    <strong>${esc(firstName)}</strong>.

                    Votre demande a bien été reçue.

                    Notre équipe vous contactera
                    prochainement pour la suite.

                </div>


                <div class="member-v3-success-community">

                    Heureux de vous accueillir
                    dans la communauté CEMM MARANATHA.

                </div>

            </div>

        </div>
    `;


    console.log(
        "[MARANATHA MEMBRE V3]",
        form
    );
}


/* ==========================================================
   BRIDGE
   ========================================================== */

let timer = null;


function install(){

    if(!membershipIsOpen()){
        return;
    }


    const container =
        getBody();


    if(
        !container ||
        container.querySelector(
            ".member-v3"
        )
    ){
        return;
    }


    step = 1;


    form = {
        nom:"",
        eglise:"",
        residence:"",
        fonction:"",
        fonctionAutre:"",
        telephone:"",
        pretAServir:""
    };


    render();
}


function schedule(){

    clearTimeout(timer);


    timer =
        setTimeout(
            install,
            30
        );
}


const observer =
    new MutationObserver(
        schedule
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

        setTimeout(install,30);
        setTimeout(install,150);

    },
    false
);


console.log(
    "[MARANATHA] Formulaire membre V3 actif"
);

})();