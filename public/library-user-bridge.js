/* MARANATHA_LIBRARY_STRICT_GUARD */

function __maranathaLibraryStrictlyOpen(){

    if(
        typeof window.MARANATHA_LIBRARY_IS_OPEN ===
        "function"
    ){
        return window.MARANATHA_LIBRARY_IS_OPEN();
    }


    const sheet =
        document.getElementById("m-sheet") ||
        document.querySelector(".m-sheet");


    if(!sheet){
        return false;
    }


    const header =
        sheet.querySelector(
            ".m-sheet-title," +
            ".sheet-title," +
            "[data-sheet-title]," +
            ".m-sheet-header h1," +
            ".m-sheet-header h2," +
            "h1,h2"
        );


    const title =
        header
            ? String(
                header.textContent || ""
              )
            : "";


    return (
        title
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g,"")
        .trim()
        .toLowerCase() ===
        "bibliotheque"
    );
}

(function(){

    "use strict";

    const STORAGE_KEY =
        "maranatha_library_v2";


    const TABS = [
        ["recent","Prédications récentes"],
        ["live","En direct"],
        ["audio","Audio MP3"],
        ["video","Vidéos"],
        ["book","Livres"]
    ];


    let activeTab =
        "recent";

    /* ======================================================
       MARANATHA_RECENT_SERMONS_API_V1
       Predications terminees venant du serveur
       ====================================================== */

    let recentSermons = [];

    async function loadRecentSermons(){

        try{

            const response =
                await fetch(
                    "/api/sermons/recent",
                    {
                        cache:"no-store"
                    }
                );

            if(!response.ok){
                throw new Error(
                    "HTTP " +
                    response.status
                );
            }

            const data =
                await response.json();

            recentSermons =
                (
                    Array.isArray(data)
                        ? data
                        : []
                )
                .filter(function(sermon){

                    return (
                        sermon &&
                        sermon.audioUrl
                    );

                })
                .map(function(sermon){

                    return {
                        id:
                            sermon._id ||
                            sermon.id ||
                            "",

                        title:
                            sermon.titre ||
                            "Prédication Maranatha",

                        url:
                            sermon.audioUrl,

                        speaker:
                            "Prédication",

                        active:
                            true,

                        sourceMode:
                            "sermon",

                        dateDiffusion:
                            sermon.dateDiffusion,

                        dateFin:
                            sermon.dateFin,

                        dureeSecondes:
                            sermon.dureeSecondes,

                        statut:
                            sermon.statut
                    };

                });

            if(
                activeTab === "recent" &&
                typeof render === "function"
            ){
                render();
            }

        }catch(error){

            console.warn(
                "[MARANATHA RECENT SERMONS]",
                error
            );

        }
    }

    loadRecentSermons();

    setInterval(
        loadRecentSermons,
        30000
    );


    /* ======================================================
       STOCKAGE PARTAGE ADMIN / FIDELE
       ====================================================== */

    function getStore(){

        try{

            const raw =
                localStorage.getItem(
                    STORAGE_KEY
                );


            if(!raw){

                return {
                    recent:[],
                    live:[],
                    audio:[],
                    video:[],
                    book:[]
                };
            }


            const parsed =
                JSON.parse(raw);


            return {

                recent:
                    Array.isArray(parsed.recent)
                        ? parsed.recent
                        : [],

                live:
                    Array.isArray(parsed.live)
                        ? parsed.live
                        : [],

                audio:
                    Array.isArray(parsed.audio)
                        ? parsed.audio
                        : [],

                video:
                    Array.isArray(parsed.video)
                        ? parsed.video
                        : [],

                book:
                    Array.isArray(parsed.book)
                        ? parsed.book
                        : []
            };

        }catch(error){

            console.error(
                "[MARANATHA LIBRARY]",
                error
            );


            return {
                recent:[],
                live:[],
                audio:[],
                video:[],
                book:[]
            };
        }
    }


    function visibleItems(type){

        const data =
            getStore();


        return (
            data[type] || []
        )
        .filter(function(item){

            return (
                item &&
                item.active !== false
            );
        });
    }


    function esc(value){

        return String(
            value == null
                ? ""
                : value
        )
        .replace(/&/g,"&amp;")
        .replace(/</g,"&lt;")
        .replace(/>/g,"&gt;")
        .replace(/"/g,"&quot;");
    }


    /* ======================================================
       YOUTUBE THUMBNAIL
       ====================================================== */

    function youtubeThumb(url){

        try{

            const value =
                String(url || "");


            let id = "";


            if(
                value.includes(
                    "youtu.be/"
                )
            ){

                id =
                    value
                    .split("youtu.be/")[1]
                    .split(/[?&#/]/)[0];

            }else{

                const parsed =
                    new URL(value);


                if(
                    parsed.hostname.includes(
                        "youtube.com"
                    )
                ){

                    id =
                        parsed.searchParams.get(
                            "v"
                        );


                    if(
                        !id &&
                        parsed.pathname.includes(
                            "/shorts/"
                        )
                    ){

                        id =
                            parsed.pathname
                            .split("/shorts/")[1]
                            .split("/")[0];
                    }
                }
            }


            if(!id){
                return "";
            }


            return (
                "https://img.youtube.com/vi/" +
                id +
                "/hqdefault.jpg"
            );


        }catch(_error){

            return "";
        }
    }


    /* ======================================================
       PARTAGER
       ====================================================== */

    async function shareItem(
        title,
        url
    ){

        const shareUrl =
            url ||
            (
                window.location.origin +
                window.location.pathname +
                "#bibliotheque"
            );


        try{

            if(navigator.share){

                await navigator.share({
                    title:title,
                    text:title,
                    url:shareUrl
                });

                return;
            }


            if(
                navigator.clipboard &&
                navigator.clipboard.writeText
            ){

                await navigator.clipboard.writeText(
                    shareUrl
                );


                alert(
                    "Lien copié."
                );

                return;
            }


            prompt(
                "Copiez ce lien :",
                shareUrl
            );


        }catch(error){

            if(
                error &&
                error.name === "AbortError"
            ){
                return;
            }
        }
    }


    /* ======================================================
       AUDIO / PREDICATION / LIVE
       ====================================================== */

    function renderRow(
        item,
        type
    ){

        let badge =
            "REC";


        let meta =
            item.speaker ||
            "Prédication";


        let action =
            "Écouter";


        if(type === "audio"){

            badge =
                "MP3";

            meta =
                item.speaker ||
                "Audio MP3";
        }


        if(type === "live"){

            const badges = {
                audio:"LIVE",
                youtube:"YT",
                facebook:"FB",
                tiktok:"TT"
            };


            const labels = {
                audio:"Audio MARANATHA",
                youtube:"YouTube",
                facebook:"Facebook",
                tiktok:"TikTok"
            };


            badge =
                badges[item.platform] ||
                "LIVE";


            meta =
                labels[item.platform] ||
                "En direct";


            action =
                item.platform === "audio"
                    ? "Écouter"
                    : "Regarder";
        }


        return `
            <div class="mlib3-row ${
                type === "live"
                    ? "live"
                    : ""
            }">

                <div class="mlib3-type">
                    ${badge}
                </div>


                <div class="mlib3-main">

                    <div class="mlib3-name">
                        ${esc(item.title)}
                    </div>

                    <div class="mlib3-meta">
                        ${esc(meta)}
                    </div>

                    ${
                        type === "live"
                            ? `
                                <div class="mlib3-live">
                                    EN DIRECT
                                </div>
                            `
                            : ""
                    }

                </div>


                <div class="mlib3-actions">

                    ${
                        item.url
                            ? `
                                <a
                                    class="mlib3-open"
                                    href="${esc(item.url)}">

                                    ${action}

                                </a>
                            `
                            : ""
                    }


                    <button
                        type="button"
                        class="mlib3-share"
                        data-bib-share
                        data-title="${esc(item.title)}"
                        data-url="${esc(item.url || "")}">

                        Partager

                    </button>

                </div>

            </div>
        `;
    }


    /* ======================================================
       VIDEOS
       ====================================================== */

    function renderVideos(){

        const list =
            visibleItems(
                "video"
            );


        if(!list.length){

            return `
                <div class="mlib3-empty">
                    Aucune vidéo disponible.
                </div>
            `;
        }


        return `
            <div class="mlib3-video-grid">

                ${
                    list.map(function(item){

                        const image =
                            item.image ||
                            youtubeThumb(
                                item.url
                            );


                        return `
                            <div class="mlib3-video">

                                <a
                                    class="mlib3-video-cover"
                                    href="${esc(item.url || "#")}"
                                    target="_blank"
                                    rel="noopener noreferrer">

                                    ${
                                        image
                                            ? `
                                                <img
                                                    src="${esc(image)}"
                                                    alt="${esc(item.title)}">
                                            `
                                            : `
                                                <div class="mlib3-video-fallback">
                                                    VIDÉO
                                                </div>
                                            `
                                    }

                                    <div class="mlib3-play">
                                        ▶
                                    </div>

                                </a>


                                <div class="mlib3-video-name">
                                    ${esc(item.title)}
                                </div>


                                <div class="mlib3-video-actions">

                                    <button
                                        type="button"
                                        class="mlib3-share"
                                        data-bib-share
                                        data-title="${esc(item.title)}"
                                        data-url="${esc(item.url || "")}">

                                        Partager

                                    </button>

                                </div>

                            </div>
                        `;

                    }).join("")
                }

            </div>
        `;
    }


    /* ======================================================
       LIVRES
       ====================================================== */

    function renderBooks(){

        const list =
            visibleItems(
                "book"
            );


        if(!list.length){

            return `
                <div class="mlib3-empty">
                    Aucun livre disponible.
                </div>
            `;
        }


        return `
            <div class="mlib3-book-grid">

                ${
                    list.map(function(item){

                        return `
                            <div class="mlib3-book">

                                <a
                                    class="mlib3-book-cover"
                                    href="${esc(item.url || "#")}"
                                    data-bib-read-pdf
                                    data-url="${esc(item.url || "")}"
                                    title="Ouvrir le livre">

                                    ${
                                        item.image
                                            ? `
                                                <img
                                                    src="${esc(item.image)}"
                                                    alt="${esc(item.title)}">
                                            `
                                            : `
                                                <div class="mlib3-book-placeholder">

                                                    <div class="mlib3-book-brand">
                                                        MARANATHA
                                                    </div>

                                                    <div class="mlib3-book-big">
                                                        ${esc(item.title)}
                                                    </div>

                                                    <div class="mlib3-book-author-small">
                                                        ${esc(item.author || "MARANATHA")}
                                                    </div>

                                                </div>
                                            `
                                    }

                                </a>


                                <div class="mlib3-book-name">
                                    ${esc(item.title)}
                                </div>

                                <div class="mlib3-book-author">
                                    ${esc(item.author || "MARANATHA")}
                                </div>


                                <div class="mlib3-book-actions">

                                    ${
                                        item.url
                                            ? `
                                                <a
                                                    class="mlib3-open"
                                                    href="${esc(item.url)}"
                                                    data-bib-read-pdf
                                                    data-url="${esc(item.url)}"
                                                    title="Lire le livre">
                                                    Lire
                                                </a>


                                                <a
                                                    class="mlib3-download"
                                                    href="${esc(item.url)}"
                                                    download
                                                    title="Télécharger le livre">
                                                    Télécharger
                                                </a>
                                            `
                                            : ""
                                    }


                                    <button
                                        type="button"
                                        class="mlib3-share"
                                        data-bib-share
                                        data-title="${esc(item.title)}"
                                        data-url="${esc(item.url || "")}">

                                        Partager

                                    </button>

                                </div>

                            </div>
                        `;

                    }).join("")
                }

            </div>
        `;
    }


    /* ======================================================
       CONTENU ONGLET
       ====================================================== */

    function renderContent(){

        if(activeTab === "video"){
            return renderVideos();
        }


        if(activeTab === "book"){
            return renderBooks();
        }


        const list =
            activeTab === "recent"
                ? recentSermons
                : visibleItems(
                    activeTab
                );


        if(!list.length){

            const messages = {

                recent:
                    "Aucune prédication récente.",

                live:
                    "Aucun direct actuellement.",

                audio:
                    "Aucun audio MP3 disponible."
            };


            return `
                <div class="mlib3-empty">
                    ${
                        messages[activeTab] ||
                        "Aucun contenu."
                    }
                </div>
            `;
        }


        return `
            <div class="mlib3-list">

                ${
                    list.map(function(item){

                        return renderRow(
                            item,
                            activeTab
                        );

                    }).join("")
                }

            </div>
        `;
    }


    function currentTitle(){

        return {

            recent:
                "Prédications récentes",

            live:
                "En direct",

            audio:
                "Audio MP3",

            video:
                "Vidéos",

            book:
                "Livres"

        }[activeTab];
    }


    /* ======================================================
       TROUVER LA FENETRE EXISTANTE
       ====================================================== */

    function getSheetBody(){

        return (
            document.getElementById(
                "m-sheet-body"
            ) ||
            document.querySelector(
                ".m-sheet-body"
            )
        );
    }


    function isLibraryOpen(){

        const body =
            getSheetBody();


        if(!body){
            return false;
        }


        /*
         * Lorsque showLibrary() original ouvre cette fenêtre,
         * on reconnaît soit son contenu Livres/Videos/Predications,
         * soit notre propre root.
         */

        const text =
            (
                body.textContent ||
                ""
            )
            .toLowerCase();


        return (
            !!body.querySelector(
                "#maranatha-library-bridge"
            ) ||
            text.includes("livres") ||
            text.includes("predications") ||
            text.includes("prédications") ||
            text.includes("videos") ||
            text.includes("vidéos")
        );
    }


    /* ======================================================
       AFFICHER NOTRE BIBLIOTHEQUE
       ====================================================== */

    function render(){
    if(!__maranathaLibraryStrictlyOpen()){ return; }

        const body =
            getSheetBody();


        if(!body){
            return;
        }


        let root =
            body.querySelector(
                "#maranatha-library-bridge"
            );


        if(!root){

            body.innerHTML = `
                <div
                    id="maranatha-library-bridge">
                </div>
            `;


            root =
                body.querySelector(
                    "#maranatha-library-bridge"
                );
        }


        if(!root){
            return;
        }


        root.innerHTML = `
            <div class="mlib3">

                <div class="mlib3-tabs">

                    ${
                        TABS.map(function(tab){

                            return `
                                <button
                                    type="button"
                                    class="mlib3-tab ${
                                        tab[0] ===
                                        activeTab
                                            ? "active"
                                            : ""
                                    }"
                                    data-bib-tab="${tab[0]}">

                                    ${tab[1]}

                                </button>
                            `;

                        }).join("")
                    }

                </div>


                <div class="mlib3-title">
                    ${currentTitle()}
                </div>


                ${renderContent()}

            </div>
        `;


        root.querySelectorAll(
            "[data-bib-tab]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    activeTab =
                        button.dataset.bibTab;


                    render();
                }
            );
        });


        root.querySelectorAll(
            "[data-bib-share]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    shareItem(
                        button.dataset.title,
                        button.dataset.url
                    );
                }
            );
        });


        console.log(
            "[MARANATHA] Bibliothèque synchronisée",
            getStore()
        );
    }


    /* ======================================================
       OBSERVER LE SHEET ORIGINAL
       ====================================================== */

    let scheduled =
        false;


    function scheduleCheck(){

        if(scheduled){
            return;
        }


        scheduled =
            true;


        setTimeout(
            function(){

                scheduled =
                    false;


                const body =
                    getSheetBody();


                if(!body){
                    return;
                }


                /*
                 * Si notre Bibliothèque est déjà en place,
                 * ne rien reconstruire inutilement.
                 */

                if(
                    body.querySelector(
                        "#maranatha-library-bridge"
                    )
                ){
                    return;
                }


                if(
                    isLibraryOpen()
                ){

                    activeTab =
                        "recent";


                    render();
                }

            },
            25
        );
    }


    const observer =
        new MutationObserver(
            scheduleCheck
        );


    observer.observe(
        document.documentElement,
        {
            childList:true,
            subtree:true
        }
    );


    /*
     * Quand l'utilisateur clique Bibliothèque :
     * ON NE BLOQUE PLUS LE CLIC.
     *
     * Le showLibrary() original fait son travail,
     * puis on remplace son contenu.
     */

    document.addEventListener(
        "click",
        function(event){

            const link =
                event.target.closest(
                    'a[href="#bibliotheque"]'
                );


            if(!link){
                return;
            }


            activeTab =
                "recent";


            setTimeout(
                scheduleCheck,
                20
            );


            setTimeout(
                scheduleCheck,
                150
            );


            setTimeout(
                scheduleCheck,
                700
            );

        },
        false
    );


    /*
     * Synchronisation avec l'autre onglet navigateur.
     */


    /* MARANATHA_PDF_READER_V1 */
    document.addEventListener(
        "click",
        function(event){

            const reader =
                event.target.closest(
                    "[data-bib-read-pdf]"
                );

            if(!reader){
                return;
            }

            event.preventDefault();
            event.stopPropagation();

            const url =
                reader.dataset.url ||
                reader.getAttribute("href");

            if(!url || url === "#"){
                return;
            }

            const readUrl =
                "/api/library/read-pdf?url=" +
                encodeURIComponent(url);

            window.open(
                readUrl,
                "_blank",
                "noopener,noreferrer"
            );
        },
        false
    );

    window.addEventListener(
        "storage",
        function(event){

            if(
                event.key ===
                    STORAGE_KEY
            ){

                const body =
                    getSheetBody();


                if(
                    body &&
                    body.querySelector(
                        "#maranatha-library-bridge"
                    )
                ){

                    render();
                }
            }
        }
    );


    console.log(
        "[MARANATHA] Bridge Bibliothèque actif"
    );

})();
