(function(){

"use strict";

const ENDPOINT =
    "/api/settings/app-config";


const DOCUMENTS = {

    about: {
        title:"À propos de MARANATHA",
        description:
            "Présentez l'Église, sa vision, sa mission et l'application."
    },

    privacy: {
        title:"Confidentialité et données",
        description:
            "Expliquez quelles données sont collectées, leur utilisation, leur conservation et les droits des utilisateurs."
    },

    terms: {
        title:"Conditions d'utilisation",
        description:
            "Définissez les règles d'utilisation de l'application et de ses services."
    },

    help: {
        title:"Aide & support",
        description:
            "Indiquez comment obtenir de l'aide et contacter MARANATHA."
    }
};


let data = null;
let loaded = false;
let editorKey = null;


function pane(){

    return document.getElementById(
        "pane-params"
    );
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


function headers(json){

    let result = {};

    try {

        if(
            typeof window.authHeaders ===
            "function"
        ){

            result =
                window.authHeaders() || {};
        }

    } catch(_error){}


    if(json){

        result["Content-Type"] =
            "application/json";
    }


    return result;
}


function value(
    group,
    key
){

    return (
        data &&
        data[group] &&
        data[group][key]
    ) || "";
}


function input(
    label,
    group,
    key,
    placeholder,
    full
){

    return `
        <div class="params-field ${
            full ? "full" : ""
        }">

            <label class="params-label">
                ${esc(label)}
            </label>

            <input
                class="params-input"
                type="text"
                data-group="${esc(group)}"
                data-key="${esc(key)}"
                value="${esc(value(group,key))}"
                placeholder="${esc(placeholder || "")}"
            >

        </div>
    `;
}


function textarea(
    label,
    group,
    key,
    placeholder
){

    return `
        <div class="params-field full">

            <label class="params-label">
                ${esc(label)}
            </label>

            <textarea
                class="params-textarea"
                data-group="${esc(group)}"
                data-key="${esc(key)}"
                placeholder="${esc(placeholder || "")}"
            >${esc(value(group,key))}</textarea>

        </div>
    `;
}


function documentRow(key){

    const documentInfo =
        DOCUMENTS[key];


    const text =
        value(
            "documents",
            key
        );


    const ready =
        Boolean(
            text.trim()
        );


    return `
        <div class="params-doc-row">

            <div class="params-doc-info">

                <div class="params-doc-name">
                    ${esc(documentInfo.title)}
                </div>

                <div class="params-doc-meta ${
                    ready ? "ready" : ""
                }">

                    ${
                        ready
                            ? esc(
                                text.length +
                                " caractères • Rédigé"
                              )
                            : "Aucun texte rédigé"
                    }

                </div>

            </div>


            <button
                type="button"
                class="params-doc-btn"
                data-edit-document="${esc(key)}">

                ${
                    ready
                        ? "Modifier"
                        : "Rédiger"
                }

            </button>

        </div>
    `;
}


function render(){

    const container =
        pane();


    if(!container || !data){
        return;
    }


    container.innerHTML = `
        <div class="params-v2">

            <div class="params-v2-head">

                <div>

                    <h2 class="params-v2-title">
                        Paramètres
                    </h2>

                    <div class="params-v2-sub">
                        Gérez les informations officielles,
                        les contacts et les contenus légaux
                        visibles par les fidèles.
                    </div>

                </div>


                <div class="params-v2-status">

                    <span
                        class="params-v2-status-dot">
                    </span>

                    Configuration active

                </div>

            </div>


            <div class="params-v2-grid">


                <section class="params-card">

                    <div class="params-card-title">
                        Identité
                    </div>

                    <div class="params-card-desc">
                        Informations principales de
                        MARANATHA.
                    </div>

                    <div class="params-form-grid">

                        ${input(
                            "Nom de l'Église",
                            "identity",
                            "churchName",
                            "CEMM MARANATHA",
                            false
                        )}

                        ${input(
                            "Nom de l'application",
                            "identity",
                            "appName",
                            "MARANATHA",
                            false
                        )}

                        ${input(
                            "Ministère / communauté",
                            "identity",
                            "ministryName",
                            "Communauté...",
                            true
                        )}

                        ${input(
                            "Version de l'application",
                            "identity",
                            "version",
                            "1.2.4",
                            false
                        )}

                        ${textarea(
                            "Présentation courte",
                            "identity",
                            "description",
                            "Une courte description..."
                        )}

                    </div>

                </section>


                <section class="params-card">

                    <div class="params-card-title">
                        Coordonnées
                    </div>

                    <div class="params-card-desc">
                        Informations officielles pour
                        contacter l'Église.
                    </div>

                    <div class="params-form-grid">

                        ${input(
                            "Téléphone",
                            "contact",
                            "phone",
                            "+243...",
                            false
                        )}

                        ${input(
                            "WhatsApp",
                            "contact",
                            "whatsapp",
                            "+243...",
                            false
                        )}

                        ${input(
                            "Adresse e-mail",
                            "contact",
                            "email",
                            "contact@...",
                            true
                        )}

                        ${textarea(
                            "Adresse physique",
                            "contact",
                            "address",
                            "Ville, commune, avenue..."
                        )}

                    </div>

                </section>


                <section class="params-card">

                    <div class="params-card-title">
                        Réseaux & liens officiels
                    </div>

                    <div class="params-card-desc">
                        Les liens publics de
                        MARANATHA.
                    </div>

                    <div class="params-form-grid">

                        ${input(
                            "Site web",
                            "links",
                            "website",
                            "https://...",
                            true
                        )}

                        ${input(
                            "Facebook",
                            "links",
                            "facebook",
                            "https://facebook.com/...",
                            false
                        )}

                        ${input(
                            "YouTube",
                            "links",
                            "youtube",
                            "https://youtube.com/...",
                            false
                        )}

                        ${input(
                            "TikTok",
                            "links",
                            "tiktok",
                            "https://tiktok.com/@...",
                            true
                        )}

                    </div>

                </section>


                <section class="params-card">

                    <div class="params-card-title">
                        Application & assistance
                    </div>

                    <div class="params-card-desc">
                        Téléchargement APK et support.
                    </div>

                    <div class="params-form-grid">

                        ${input(
                            "Lien de téléchargement APK",
                            "application",
                            "apkUrl",
                            "/downloads/MARANATHA.apk",
                            true
                        )}

                        ${input(
                            "E-mail du support",
                            "application",
                            "supportEmail",
                            "support@...",
                            true
                        )}

                        ${input(
                            "WhatsApp du support",
                            "application",
                            "supportWhatsapp",
                            "+243...",
                            true
                        )}

                    </div>

                </section>


                <section class="params-card full">

                    <div class="params-card-title">
                        Informations & documents
                    </div>

                    <div class="params-card-desc">
                        Rédigez directement les textes
                        qui seront présentés aux utilisateurs
                        de l'application.
                    </div>


                    <div class="params-doc-list">

                        ${documentRow("about")}
                        ${documentRow("privacy")}
                        ${documentRow("terms")}
                        ${documentRow("help")}

                    </div>

                </section>

            </div>


            <div class="params-savebar">

                <button
                    type="button"
                    class="params-save"
                    id="params-save">

                    Enregistrer les paramètres

                </button>

            </div>

        </div>
    `;


    bind();
}


function collect(){

    if(!data){
        return;
    }


    document
        .querySelectorAll(
            "#pane-params [data-group][data-key]"
        )
        .forEach(
            function(element){

                const group =
                    element.dataset.group;

                const key =
                    element.dataset.key;


                if(
                    !data[group] ||
                    typeof data[group] !==
                    "object"
                ){

                    data[group] = {};
                }


                data[group][key] =
                    element.value.trim();
            }
        );
}


async function persist(
    silent
){

    collect();


    const button =
        document.getElementById(
            "params-save"
        );


    if(button){

        button.disabled = true;
        button.textContent =
            "Enregistrement...";
    }


    try {

        const response =
            await fetch(
                ENDPOINT,
                {
                    method:"PUT",
                    headers:headers(true),
                    body:JSON.stringify(data)
                }
            );


        const payload =
            await response.json();


        if(!response.ok){

            throw new Error(
                payload.message ||
                "Enregistrement impossible."
            );
        }


        data =
            payload.settings ||
            data;


        if(!silent){

            if(
                typeof window.toast ===
                "function"
            ){

                window.toast(
                    "Paramètres enregistrés !",
                    "success"
                );

            }else{

                alert(
                    "Paramètres enregistrés."
                );
            }
        }


        render();


        return true;


    } catch(error){

        console.error(
            "[MARANATHA PARAMS]",
            error
        );


        alert(
            "Erreur : " +
            error.message
        );


        return false;


    } finally {

        const currentButton =
            document.getElementById(
                "params-save"
            );


        if(currentButton){

            currentButton.disabled = false;
            currentButton.textContent =
                "Enregistrer les paramètres";
        }
    }
}


function openEditor(key){

    collect();


    const info =
        DOCUMENTS[key];


    if(!info){
        return;
    }


    editorKey = key;


    const old =
        document.querySelector(
            ".params-editor-backdrop"
        );


    if(old){
        old.remove();
    }


    const backdrop =
        document.createElement(
            "div"
        );


    backdrop.className =
        "params-editor-backdrop";


    backdrop.innerHTML = `
        <div class="params-editor">

            <div class="params-editor-head">

                <div>

                    <div class="params-editor-title">
                        ${esc(info.title)}
                    </div>

                    <div class="params-editor-sub">
                        ${esc(info.description)}
                    </div>

                </div>


                <button
                    type="button"
                    class="params-editor-close"
                    id="params-editor-close">

                    ×

                </button>

            </div>


            <textarea
                class="params-editor-area"
                id="params-editor-area"
                placeholder="Rédigez votre texte ici..."
            >${esc(value("documents",key))}</textarea>


            <div class="params-editor-footer">

                <button
                    type="button"
                    class="params-editor-cancel"
                    id="params-editor-cancel">

                    Annuler

                </button>


                <button
                    type="button"
                    class="params-editor-save"
                    id="params-editor-save">

                    Enregistrer ce texte

                </button>

            </div>

        </div>
    `;


    document.body.appendChild(
        backdrop
    );


    document
        .getElementById(
            "params-editor-close"
        )
        ?.addEventListener(
            "click",
            closeEditor
        );


    document
        .getElementById(
            "params-editor-cancel"
        )
        ?.addEventListener(
            "click",
            closeEditor
        );


    document
        .getElementById(
            "params-editor-save"
        )
        ?.addEventListener(
            "click",
            saveEditor
        );


    backdrop.addEventListener(
        "click",
        function(event){

            if(event.target === backdrop){

                closeEditor();
            }
        }
    );


    setTimeout(
        function(){

            document
                .getElementById(
                    "params-editor-area"
                )
                ?.focus();

        },
        50
    );
}


function closeEditor(){

    document
        .querySelector(
            ".params-editor-backdrop"
        )
        ?.remove();


    editorKey = null;
}


async function saveEditor(){

    if(!editorKey){
        return;
    }


    const textarea =
        document.getElementById(
            "params-editor-area"
        );


    if(!data.documents){

        data.documents = {};
    }


    data.documents[editorKey] =
        textarea
            ? textarea.value.trim()
            : "";


    const saved =
        await persist(true);


    if(saved){

        closeEditor();

        render();


        if(
            typeof window.toast ===
            "function"
        ){

            window.toast(
                "Texte enregistré !",
                "success"
            );
        }
    }
}


function bind(){

    document
        .getElementById(
            "params-save"
        )
        ?.addEventListener(
            "click",
            function(){

                persist(false);
            }
        );


    document
        .querySelectorAll(
            "[data-edit-document]"
        )
        .forEach(
            function(button){

                button.addEventListener(
                    "click",
                    function(){

                        openEditor(
                            button.dataset.editDocument
                        );
                    }
                );
            }
        );
}


async function load(){

    const container =
        pane();


    if(!container){
        return;
    }


    container.innerHTML = `
        <div class="params-v2">
            <div
                style="
                    padding:70px 20px;
                    text-align:center;
                    color:rgba(255,255,255,.38);
                    font-size:10px;
                "
            >
                Chargement des paramètres...
            </div>
        </div>
    `;


    try {

        const response =
            await fetch(
                ENDPOINT,
                {
                    headers:headers(false),
                    cache:"no-store"
                }
            );


        if(!response.ok){

            throw new Error(
                "HTTP " +
                response.status
            );
        }


        data =
            await response.json();


        loaded = true;


        render();


    } catch(error){

        console.error(
            "[MARANATHA PARAMS LOAD]",
            error
        );


        container.innerHTML = `
            <div class="params-v2">
                <div
                    style="
                        padding:60px 20px;
                        text-align:center;
                        color:#ff7588;
                        font-size:10px;
                    "
                >
                    Impossible de charger
                    les paramètres.
                    <br><br>
                    ${esc(error.message)}
                </div>
            </div>
        `;
    }
}


function activate(){

    if(!loaded){

        load();

    }else{

        render();
    }
}


/*
 * L'ancien écran de bienvenue
 * n'est plus notre interface Paramètres.
 */
try {

    if(
        typeof window.chargerSplash ===
        "function"
    ){

        window.chargerSplash =
            async function(){
                return;
            };
    }

} catch(_error){}


document.addEventListener(
    "click",
    function(event){

        if(
            event.target.closest(
                '[data-tab="params"]'
            )
        ){

            setTimeout(
                activate,
                30
            );
        }
    },
    true
);


setTimeout(
    function(){

        const container =
            pane();


        if(
            container &&
            container.classList.contains(
                "active"
            )
        ){

            activate();
        }

    },
    400
);


window.MaranathaParamsV2 = {
    load:load,
    save:persist
};


console.log(
    "[MARANATHA] Paramètres V2 actifs"
);

})();