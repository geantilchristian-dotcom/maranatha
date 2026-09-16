(function(){

"use strict";


var state = {
    items: [],
    filter: "all",
    selected: null,
    loading: false
};


var CATEGORY_LABELS = {
    offrande: "Offrande",
    dime: "Dîme",
    don_mensuel: "Don mensuel",
    don_volontaire: "Don volontaire"
};


function pane(){

    return document.getElementById(
        "pane-dons"
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


function headers(){

    try{

        if(
            typeof window.authHeaders ===
            "function"
        ){

            return window.authHeaders();
        }

    }catch(_error){}


    return {};
}


function categoryLabel(value){

    return (
        CATEGORY_LABELS[
            String(value || "")
            .toLowerCase()
        ] ||
        value ||
        "Don"
    );
}


function amount(value){

    var number =
        Number(value || 0);


    return (
        new Intl.NumberFormat(
            "fr-FR"
        ).format(number) +
        " CDF"
    );
}


function dateValue(value){

    if(!value){
        return "—";
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


function statusInfo(value){

    var status =
        String(value || "PENDING")
        .trim()
        .toUpperCase();


    var paid = [
        "PAID",
        "SUCCESS",
        "SUCCESSFUL",
        "COMPLETED",
        "APPROVED"
    ];


    var failed = [
        "FAILED",
        "CANCELLED",
        "CANCELED",
        "REJECTED",
        "ERROR",
        "EXPIRED"
    ];


    if(paid.indexOf(status) !== -1){

        return {
            code:status,
            label:"Payé",
            css:"paid"
        };
    }


    if(failed.indexOf(status) !== -1){

        return {
            code:status,
            label:"Échoué / annulé",
            css:"failed"
        };
    }


    return {
        code:status,
        label:"En attente",
        css:"pending"
    };
}


function isPaid(item){

    return (
        statusInfo(item.status).css ===
        "paid"
    );
}


function sameDay(a,b){

    return (
        a.getFullYear() === b.getFullYear() &&
        a.getMonth() === b.getMonth() &&
        a.getDate() === b.getDate()
    );
}


function totals(){

    var now =
        new Date();


    var today = 0;
    var month = 0;
    var total = 0;
    var pending = 0;


    state.items.forEach(
        function(item){

            var status =
                statusInfo(item.status);


            if(status.css === "pending"){

                pending++;

                return;
            }


            if(status.css !== "paid"){

                return;
            }


            var n =
                Number(item.amount || 0);


            total += n;


            var d =
                new Date(
                    item.createdAt || 0
                );


            if(
                !isNaN(d.getTime())
            ){

                if(
                    sameDay(
                        d,
                        now
                    )
                ){

                    today += n;
                }


                if(
                    d.getFullYear() ===
                        now.getFullYear() &&
                    d.getMonth() ===
                        now.getMonth()
                ){

                    month += n;
                }
            }
        }
    );


    return {
        today:today,
        month:month,
        total:total,
        pending:pending
    };
}


function extractItems(payload){

    if(Array.isArray(payload)){
        return payload;
    }


    if(
        payload &&
        Array.isArray(payload.items)
    ){
        return payload.items;
    }


    if(
        payload &&
        Array.isArray(payload.donations)
    ){
        return payload.donations;
    }


    if(
        payload &&
        Array.isArray(payload.data)
    ){
        return payload.data;
    }


    return [];
}


async function requestDonations(){

    var urls = [
        "/api/dons/admin",
        "/api/dons"
    ];


    var lastError = null;


    for(
        var i = 0;
        i < urls.length;
        i++
    ){

        try{

            var response =
                await fetch(
                    urls[i],
                    {
                        headers:headers(),
                        cache:"no-store"
                    }
                );


            if(!response.ok){

                lastError =
                    new Error(
                        "HTTP " +
                        response.status
                    );

                continue;
            }


            var payload =
                await response.json();


            return extractItems(
                payload
            );


        }catch(error){

            lastError = error;
        }
    }


    throw (
        lastError ||
        new Error(
            "Impossible de charger les dons."
        )
    );
}


async function load(){

    var container =
        pane();


    if(!container){
        return;
    }


    state.loading = true;


    render();


    try{

        state.items =
            await requestDonations();


        state.items.sort(
            function(a,b){

                return (
                    new Date(
                        b.createdAt || 0
                    ).getTime() -
                    new Date(
                        a.createdAt || 0
                    ).getTime()
                );
            }
        );


    }catch(error){

        console.error(
            "[MARANATHA ADMIN DONS]",
            error
        );


        state.items = [];


        container.innerHTML = `
            <div class="dons-v2">
                <div class="dons-v2-error">
                    Impossible de charger les transactions.
                    <br><br>
                    ${esc(error.message)}
                </div>
            </div>
        `;


        state.loading = false;

        return;
    }


    state.loading = false;


    render();
}


function filteredItems(){

    if(
        state.filter ===
        "all"
    ){

        return state.items;
    }


    return state.items.filter(
        function(item){

            return (
                String(
                    item.category || ""
                ).toLowerCase() ===
                state.filter
            );
        }
    );
}


function statCard(
    label,
    value,
    note
){

    return `
        <div class="dons-v2-stat">

            <div class="dons-v2-stat-label">
                ${esc(label)}
            </div>

            <div class="dons-v2-stat-value">
                ${esc(value)}
            </div>

            <div class="dons-v2-stat-note">
                ${esc(note)}
            </div>

        </div>
    `;
}


function filterButton(
    key,
    label
){

    return `
        <button
            type="button"
            class="dons-v2-filter ${
                state.filter === key
                    ? "active"
                    : ""
            }"
            data-dons-filter="${esc(key)}">

            ${esc(label)}

        </button>
    `;
}


function row(item){

    var status =
        statusInfo(
            item.status
        );


    var id =
        item.externalId ||
        item.id ||
        "";


    return `
        <div
            class="dons-v2-row"
            data-dons-select="${esc(id)}">

            <div>
                <div class="dons-v2-type">
                    ${esc(
                        categoryLabel(
                            item.category
                        )
                    )}
                </div>

                <div class="dons-v2-reference">
                    ${esc(
                        item.externalId ||
                        item.reference ||
                        "—"
                    )}
                </div>
            </div>


            <div class="dons-v2-amount">
                ${esc(
                    amount(
                        item.amount
                    )
                )}
            </div>


            <div>

                <span
                    class="dons-v2-status ${status.css}">

                    ${esc(status.label)}

                </span>

            </div>


            <div class="dons-v2-text">
                ${esc(
                    item.provider ||
                    "K-PAY"
                )}
            </div>


            <div class="dons-v2-text">
                ${esc(
                    dateValue(
                        item.createdAt
                    )
                )}
            </div>


            <div>

                <button
                    type="button"
                    class="dons-v2-check"
                    data-dons-check="${esc(item.externalId || "")}">

                    Vérifier

                </button>

            </div>

        </div>
    `;
}


function detail(item){

    if(!item){
        return "";
    }


    var status =
        statusInfo(
            item.status
        );


    function box(label,value){

        return `
            <div class="dons-v2-detail-item">

                <div class="dons-v2-detail-label">
                    ${esc(label)}
                </div>

                <div class="dons-v2-detail-value">
                    ${esc(value || "—")}
                </div>

            </div>
        `;
    }


    return `
        <div class="dons-v2-detail">

            <div class="dons-v2-detail-title">
                Détails de la transaction
            </div>


            <div class="dons-v2-detail-grid">

                ${box(
                    "Type de contribution",
                    categoryLabel(
                        item.category
                    )
                )}

                ${box(
                    "Montant",
                    amount(
                        item.amount
                    )
                )}

                ${box(
                    "Statut",
                    status.label +
                    " (" +
                    status.code +
                    ")"
                )}

                ${box(
                    "Référence MARANATHA",
                    item.externalId
                )}

                ${box(
                    "Référence K-PAY",
                    item.reference
                )}

                ${box(
                    "Identifiant paiement",
                    item.id
                )}

                ${box(
                    "Moyen / fournisseur",
                    item.provider ||
                    "K-PAY"
                )}

                ${box(
                    "Date",
                    dateValue(
                        item.createdAt
                    )
                )}

                ${box(
                    "Environnement",
                    item.isTest
                        ? "Test / Sandbox"
                        : "Production"
                )}

            </div>

        </div>
    `;
}


function render(){

    var container =
        pane();


    if(!container){
        return;
    }


    if(state.loading){

        container.innerHTML = `
            <div class="dons-v2">
                <div class="dons-v2-loading">
                    Chargement des dons...
                </div>
            </div>
        `;

        return;
    }


    var sums =
        totals();


    var items =
        filteredItems();


    var selected =
        state.items.find(
            function(item){

                return (
                    String(
                        item.externalId ||
                        item.id ||
                        ""
                    ) ===
                    String(
                        state.selected ||
                        ""
                    )
                );
            }
        );


    container.innerHTML = `
        <div class="dons-v2">

            <div class="dons-v2-head">

                <div>

                    <h2 class="dons-v2-title">
                        Dons
                    </h2>

                    <div class="dons-v2-sub">
                        Suivi des contributions effectuées
                        depuis l'application MARANATHA.
                    </div>

                </div>


                <button
                    type="button"
                    class="dons-v2-refresh"
                    id="dons-v2-refresh">

                    Actualiser

                </button>

            </div>


            <div class="dons-v2-stats">

                ${statCard(
                    "Aujourd'hui",
                    amount(sums.today),
                    "Paiements confirmés"
                )}

                ${statCard(
                    "Ce mois",
                    amount(sums.month),
                    "Paiements confirmés"
                )}

                ${statCard(
                    "Total reçu",
                    amount(sums.total),
                    "Toutes périodes"
                )}

                ${statCard(
                    "En attente",
                    String(sums.pending),
                    "Transaction(s)"
                )}

            </div>


            <div class="dons-v2-filters">

                ${filterButton(
                    "all",
                    "Tous"
                )}

                ${filterButton(
                    "offrande",
                    "Offrandes"
                )}

                ${filterButton(
                    "dime",
                    "Dîmes"
                )}

                ${filterButton(
                    "don_mensuel",
                    "Dons mensuels"
                )}

                ${filterButton(
                    "don_volontaire",
                    "Dons volontaires"
                )}

            </div>


            <div class="dons-v2-box">

                ${
                    items.length
                        ? `

                            <div class="dons-v2-table-head">

                                <div>Type</div>
                                <div>Montant</div>
                                <div>Statut</div>
                                <div>Paiement</div>
                                <div>Date</div>
                                <div></div>

                            </div>


                            ${items.map(row).join("")}

                        `
                        : `

                            <div class="dons-v2-empty">

                                Aucune transaction enregistrée.

                                <br><br>

                                Effectuez un don test depuis
                                l'interface fidèle pour vérifier
                                la synchronisation.

                            </div>

                        `
                }

            </div>


            ${detail(selected)}

        </div>
    `;


    bind();
}


function bind(){

    document
        .getElementById(
            "dons-v2-refresh"
        )
        ?.addEventListener(
            "click",
            load
        );


    document
        .querySelectorAll(
            "[data-dons-filter]"
        )
        .forEach(
            function(button){

                button.addEventListener(
                    "click",
                    function(){

                        state.filter =
                            button.dataset.donsFilter;


                        state.selected =
                            null;


                        render();
                    }
                );
            }
        );


    document
        .querySelectorAll(
            "[data-dons-select]"
        )
        .forEach(
            function(element){

                element.addEventListener(
                    "click",
                    function(event){

                        if(
                            event.target.closest(
                                "[data-dons-check]"
                            )
                        ){
                            return;
                        }


                        state.selected =
                            element.dataset.donsSelect;


                        render();
                    }
                );
            }
        );


    document
        .querySelectorAll(
            "[data-dons-check]"
        )
        .forEach(
            function(button){

                button.addEventListener(
                    "click",
                    async function(){

                        var externalId =
                            button.dataset.donsCheck;


                        if(!externalId){
                            return;
                        }


                        button.disabled = true;

                        button.textContent =
                            "...";


                        try{

                            var response =
                                await fetch(
                                    "/api/dons/kpay/status/" +
                                    encodeURIComponent(
                                        externalId
                                    ),
                                    {
                                        headers:headers(),
                                        cache:"no-store"
                                    }
                                );


                            var payload =
                                await response.json();


                            if(
                                !response.ok
                            ){

                                throw new Error(
                                    payload.message ||
                                    "Vérification impossible."
                                );
                            }


                            await load();


                        }catch(error){

                            alert(
                                error.message
                            );


                            button.disabled = false;

                            button.textContent =
                                "Vérifier";
                        }
                    }
                );
            }
        );
}


/* Remplacer les anciennes fonctions Admin Don */

window.chargerDonAdmin =
    load;


window.sauvegarderDon =
    async function(){

        return false;
    };


document.addEventListener(
    "click",
    function(event){

        if(
            event.target.closest(
                '[data-tab="dons"]'
            )
        ){

            setTimeout(
                load,
                30
            );
        }

    },
    false
);


setTimeout(
    function(){

        var p =
            pane();


        if(
            p &&
            p.offsetParent !== null
        ){

            load();
        }

    },
    500
);


console.log(
    "[MARANATHA] Admin Dons V2 actif"
);


})();