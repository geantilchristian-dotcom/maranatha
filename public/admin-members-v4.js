(function(){

"use strict";


const STORAGE_KEY =
    "maranatha_membership_requests_v2";


let selectedId =
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


function pane(){

    return document.getElementById(
        "pane-membres"
    );
}


function read(){

    try{

        const raw =
            localStorage.getItem(
                STORAGE_KEY
            );


        const parsed =
            raw
                ? JSON.parse(raw)
                : [];


        return Array.isArray(parsed)
            ? parsed
            : [];


    }catch(error){

        console.error(
            "[MEMBRES V4]",
            error
        );


        return [];
    }
}


function write(list){

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


function idOf(item){

    return String(
        item.id ||
        item._id ||
        ""
    );
}


function formatDate(value){

    if(!value){
        return "Date inconnue";
    }


    try{

        return new Date(
            value
        ).toLocaleString(
            "fr-FR",
            {
                day:"2-digit",
                month:"2-digit",
                year:"numeric",
                hour:"2-digit",
                minute:"2-digit"
            }
        );


    }catch(_error){

        return String(value);
    }
}


function initials(name){

    const parts =
        String(name || "")
        .trim()
        .split(/\s+/)
        .filter(Boolean);


    if(!parts.length){
        return "M";
    }


    return parts
        .slice(0,2)
        .map(
            function(part){

                return part
                    .charAt(0)
                    .toUpperCase();
            }
        )
        .join("");
}


function statusLabel(status){

    if(status === "accepte"){
        return "Accepté";
    }


    if(status === "refuse"){
        return "Refusé";
    }


    return "En attente";
}


function statusClass(status){

    if(status === "accepte"){
        return "accepted";
    }


    if(status === "refuse"){
        return "refused";
    }


    return "";
}


/* ==========================================================
   WHATSAPP
   ========================================================== */

function whatsappNumber(phone){

    let digits =
        String(phone || "")
        .replace(/\D/g,"");


    /*
     * 097... -> 24397...
     */
    if(
        digits.startsWith("0")
    ){

        digits =
            "243" +
            digits.substring(1);
    }


    /*
     * 97xxxxxxx -> 24397xxxxxxx
     */
    if(
        digits.length === 9 &&
        !digits.startsWith("243")
    ){

        digits =
            "243" +
            digits;
    }


    return digits;
}


function openWhatsapp(item){

    const number =
        whatsappNumber(
            item.telephone
        );


    if(!number){

        alert(
            "Aucun numéro de téléphone valide pour ce fidèle."
        );

        return;
    }


    const firstName =
        String(
            item.nom || ""
        )
        .trim()
        .split(/\s+/)[0] ||
        "";


    const message =
        "Bonjour " +
        firstName +
        ", ici CEMM MARANATHA.";


    const url =
        "https://wa.me/" +
        number +
        "?text=" +
        encodeURIComponent(
            message
        );


    window.open(
        url,
        "_blank",
        "noopener,noreferrer"
    );
}


/* ==========================================================
   LISTE
   ========================================================== */

function renderList(){

    const container =
        pane();


    if(!container){
        return;
    }


    selectedId =
        null;


    const requests =
        read();


    container.innerHTML = `
        <div class="members-v4">

            <div class="members-v4-header">

                <div>

                    <h2 class="members-v4-title">
                        Demandes d'adhésion
                    </h2>

                    <div class="members-v4-sub">
                        Cliquez sur le nom d'un fidèle
                        pour consulter son identité.
                    </div>

                </div>


                <div class="members-v4-count">

                    ${requests.length}
                    demande${requests.length > 1 ? "s" : ""}

                </div>

            </div>


            <div class="members-v4-table">

                ${
                    requests.length
                        ? `

                            <div class="members-v4-table-head">

                                <div>
                                    Nom du fidèle
                                </div>

                                <div>
                                    Date
                                </div>

                            </div>


                            ${
                                requests.map(
                                    function(item){

                                        return `

                                            <div class="members-v4-row">

                                                <div>

                                                    <button
                                                        type="button"
                                                        class="members-v4-name"
                                                        data-members-v4-open="${esc(idOf(item))}">

                                                        ${esc(
                                                            item.nom ||
                                                            "Sans nom"
                                                        )}

                                                    </button>

                                                </div>


                                                <div class="members-v4-date">

                                                    ${esc(
                                                        formatDate(
                                                            item.createdAt
                                                        )
                                                    )}

                                                </div>

                                            </div>

                                        `;

                                    }
                                ).join("")
                            }

                        `
                        : `

                            <div class="members-v4-empty">

                                Aucune demande d'adhésion
                                pour le moment.

                            </div>

                        `
                }

            </div>

        </div>
    `;


    bindList();
}


/* ==========================================================
   DETAIL
   ========================================================== */

function info(
    label,
    value
){

    return `
        <div class="members-v4-info">

            <div class="members-v4-info-label">
                ${esc(label)}
            </div>


            <div class="members-v4-info-value">
                ${esc(
                    value ||
                    "Non renseigné"
                )}
            </div>

        </div>
    `;
}


function renderDetail(id){

    const container =
        pane();


    if(!container){
        return;
    }


    const requests =
        read();


    const item =
        requests.find(
            function(entry){

                return (
                    idOf(entry) ===
                    String(id)
                );
            }
        );


    if(!item){

        renderList();

        return;
    }


    selectedId =
        id;


    container.innerHTML = `
        <div class="members-v4-detail-page">

            <div class="members-v4-detail-top">

                <button
                    type="button"
                    class="members-v4-back"
                    data-members-v4-back>

                    ← Retour aux membres

                </button>


                <div
                    class="members-v4-status ${statusClass(item.statut)}">

                    ${statusLabel(item.statut)}

                </div>

            </div>


            <div class="members-v4-profile">

                <div class="members-v4-profile-head">

                    <div class="members-v4-avatar">

                        ${esc(
                            initials(
                                item.nom
                            )
                        )}

                    </div>


                    <div>

                        <h2 class="members-v4-profile-name">

                            ${esc(
                                item.nom ||
                                "Sans nom"
                            )}

                        </h2>


                        <div class="members-v4-profile-date">

                            Demande envoyée le
                            ${esc(
                                formatDate(
                                    item.createdAt
                                )
                            )}

                        </div>

                    </div>

                </div>


                <div class="members-v4-section-title">
                    Identité du fidèle
                </div>


                <div class="members-v4-info-grid">

                    ${info(
                        "Nom et post-nom",
                        item.nom
                    )}

                    ${info(
                        "Téléphone",
                        item.telephone
                    )}

                    ${info(
                        "Église de provenance",
                        item.egliseProvenance ||
                        item.eglise
                    )}

                    ${info(
                        "Lieu de résidence",
                        item.lieuResidence ||
                        item.residence
                    )}

                    ${info(
                        "Fonction",
                        item.fonction
                    )}

                    ${info(
                        "Prêt(e) à servir Dieu",
                        item.pretAServir
                    )}

                    ${info(
                        "Statut de la demande",
                        statusLabel(
                            item.statut
                        )
                    )}

                    ${info(
                        "Date de la demande",
                        formatDate(
                            item.createdAt
                        )
                    )}

                </div>


                <div class="members-v4-actions">

                    <button
                        type="button"
                        class="members-v4-action members-v4-whatsapp"
                        data-members-v4-whatsapp="${esc(idOf(item))}">

                        Contacter sur WhatsApp

                    </button>


                    ${
                        item.statut !== "accepte"
                            ? `
                                <button
                                    type="button"
                                    class="members-v4-action members-v4-accept"
                                    data-members-v4-status="accepte"
                                    data-members-v4-id="${esc(idOf(item))}">

                                    Accepter

                                </button>
                            `
                            : ""
                    }


                    ${
                        item.statut !== "refuse"
                            ? `
                                <button
                                    type="button"
                                    class="members-v4-action members-v4-refuse"
                                    data-members-v4-status="refuse"
                                    data-members-v4-id="${esc(idOf(item))}">

                                    Refuser

                                </button>
                            `
                            : ""
                    }


                    <button
                        type="button"
                        class="members-v4-action members-v4-delete"
                        data-members-v4-delete="${esc(idOf(item))}">

                        Supprimer

                    </button>

                </div>

            </div>

        </div>
    `;


    bindDetail();
}


/* ==========================================================
   EVENTS LIST
   ========================================================== */

function bindList(){

    document.querySelectorAll(
        "[data-members-v4-open]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    renderDetail(
                        button.dataset.membersV4Open
                    );
                }
            );
        }
    );
}


/* ==========================================================
   EVENTS DETAIL
   ========================================================== */

function bindDetail(){

    document.querySelector(
        "[data-members-v4-back]"
    )
    ?.addEventListener(
        "click",
        renderList
    );


    document.querySelectorAll(
        "[data-members-v4-whatsapp]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    const id =
                        button.dataset.membersV4Whatsapp;


                    const item =
                        read().find(
                            function(entry){

                                return (
                                    idOf(entry) ===
                                    String(id)
                                );
                            }
                        );


                    if(item){

                        openWhatsapp(
                            item
                        );
                    }
                }
            );
        }
    );


    document.querySelectorAll(
        "[data-members-v4-status]"
    )
    .forEach(
        function(button){

            button.addEventListener(
                "click",
                function(){

                    const id =
                        button.dataset.membersV4Id;


                    const status =
                        button.dataset.membersV4Status;


                    const requests =
                        read();


                    const item =
                        requests.find(
                            function(entry){

                                return (
                                    idOf(entry) ===
                                    String(id)
                                );
                            }
                        );


                    if(!item){
                        return;
                    }


                    item.statut =
                        status;


                    item.updatedAt =
                        new Date().toISOString();


                    write(
                        requests
                    );


                    renderDetail(
                        id
                    );
                }
            );
        }
    );


    document.querySelector(
        "[data-members-v4-delete]"
    )
    ?.addEventListener(
        "click",
        function(event){

            const id =
                event.currentTarget
                    .dataset
                    .membersV4Delete;


            if(
                !confirm(
                    "Supprimer cette demande d'adhésion ?"
                )
            ){
                return;
            }


            const requests =
                read().filter(
                    function(entry){

                        return (
                            idOf(entry) !==
                            String(id)
                        );
                    }
                );


            write(
                requests
            );


            renderList();
        }
    );
}


/* ==========================================================
   TAB MEMBRES
   ========================================================== */

document.addEventListener(
    "click",
    function(event){

        const tab =
            event.target.closest(
                '[data-tab="membres"]'
            );


        if(tab){

            setTimeout(
                renderList,
                30
            );


            setTimeout(
                renderList,
                180
            );
        }
    }
);


/* ==========================================================
   SYNCHRO
   ========================================================== */

window.addEventListener(
    "storage",
    function(event){

        if(
            event.key !==
            STORAGE_KEY
        ){
            return;
        }


        if(selectedId){

            renderDetail(
                selectedId
            );

        }else{

            renderList();
        }
    }
);


window.addEventListener(
    "maranatha-membership-updated",
    function(){

        if(selectedId){

            renderDetail(
                selectedId
            );

        }else{

            renderList();
        }
    }
);


/*
 * Premier affichage si l'onglet est déjà actif.
 */

setTimeout(
    function(){

        const p =
            pane();


        if(!p){
            return;
        }


        const activeTab =
            document.querySelector(
                '[data-tab="membres"].active'
            );


        if(
            activeTab ||
            p.offsetParent !== null
        ){

            renderList();
        }

    },
    400
);


console.log(
    "[MARANATHA] Admin Membres V4 actif"
);

})();