(function(){

    "use strict";


    const STORAGE_KEY =
        "maranatha_library_v2";


    const CLEAN_KEY =
        "maranatha_library_demo_cleaned_v3";


    const tabs = [
        ["recent","Prédications récentes"],
        ["live","En direct"],
        ["audio","Audio MP3"],
        ["video","Vidéos"],
        ["book","Livres"]
    ];


    let activeTab =
        "recent";

    let editingId =
        null;

    let sourceMode =
        "file";

    let coverMode =
        "file";


    /* ======================================================
       STOCKAGE
       ====================================================== */

    function emptyStore(){

        return {
            recent:[],
            live:[],
            audio:[],
            video:[],
            book:[]
        };
    }


    function readStore(){

        try{

            const raw =
                localStorage.getItem(
                    STORAGE_KEY
                );


            if(!raw){

                const data =
                    emptyStore();


                localStorage.setItem(
                    STORAGE_KEY,
                    JSON.stringify(data)
                );


                return data;
            }


            const data =
                JSON.parse(raw);


            tabs.forEach(function(tab){

                if(
                    !Array.isArray(
                        data[tab[0]]
                    )
                ){

                    data[tab[0]] =
                        [];
                }
            });


            return data;

        }catch(error){

            console.warn(
                "[BIB ADMIN]",
                error
            );

            return emptyStore();
        }
    }


    function writeStore(data){

        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify(data)
        );


        window.dispatchEvent(
            new CustomEvent(
                "maranatha-library-updated",
                {
                    detail:data
                }
            )
        );
    }


    /* ======================================================
       ENLEVER UNIQUEMENT NOS ANCIENNES DONNEES DE DEMO
       ====================================================== */

    function cleanOldDemo(){

        if(
            localStorage.getItem(
                CLEAN_KEY
            ) === "1"
        ){
            return;
        }


        const data =
            readStore();


        const demoIds =
            new Set([
                "recent-demo-1",
                "live-demo-1",
                "audio-demo-1",
                "video-demo-1",
                "book-demo-1"
            ]);


        Object.keys(data)
        .forEach(function(key){

            if(
                Array.isArray(
                    data[key]
                )
            ){

                data[key] =
                    data[key]
                    .filter(function(item){

                        return !demoIds.has(
                            item.id
                        );
                    });
            }
        });


        writeStore(data);


        localStorage.setItem(
            CLEAN_KEY,
            "1"
        );
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


    function newId(){

        return (
            Date.now().toString(36) +
            Math.random()
                .toString(36)
                .slice(2,8)
        );
    }


    /* ======================================================
       UPLOAD REEL
       ====================================================== */

    async function uploadFile(file){

        if(!file){
            return null;
        }


        const response =
            await fetch(
                "/api/library/upload",
                {
                    method:"POST",

                    headers:{
                        "Content-Type":
                            file.type ||
                            "application/octet-stream",

                        "X-File-Name":
                            encodeURIComponent(
                                file.name
                            )
                    },

                    body:file
                }
            );


        let result = {};


        try{

            result =
                await response.json();

        }catch(_error){}


        if(
            !response.ok ||
            !result.ok
        ){

            throw new Error(
                result.error ||
                "Upload impossible."
            );
        }


        return result;
    }


    /* ======================================================
       SOURCE FICHIER / LIEN
       ====================================================== */

    function sourceSelector(
        item,
        accept,
        label
    ){

        const currentMode =
            item &&
            item.sourceMode
                ? item.sourceMode
                : sourceMode;


        sourceMode =
            currentMode;


        return `
            <div class="mlib-source-block">

                <label class="mlib-source-label">
                    ${label}
                </label>


                <div class="mlib-source-switch">

                    <button
                        type="button"
                        class="mlib-source-choice ${
                            currentMode === "file"
                                ? "active"
                                : ""
                        }"
                        data-source-mode="file">
                        Fichier depuis l'appareil
                    </button>

                    <button
                        type="button"
                        class="mlib-source-choice ${
                            currentMode === "link"
                                ? "active"
                                : ""
                        }"
                        data-source-mode="link">
                        Utiliser un lien
                    </button>

                </div>


                <div
                    class="mlib-source-panel"
                    data-source-panel="file"
                    ${
                        currentMode !== "file"
                            ? 'style="display:none"'
                            : ""
                    }>

                    <input
                        class="mlib-file-input"
                        id="mlib-file"
                        type="file"
                        accept="${accept}">


                    <div
                        class="mlib-current-file"
                        id="mlib-current-file">

                        ${
                            item &&
                            item.sourceMode === "file" &&
                            item.fileName
                                ? `
                                    Fichier actuel :
                                    <strong>
                                        ${esc(item.fileName)}
                                    </strong>
                                `
                                : "Choisissez un fichier sur cet appareil."
                        }

                    </div>

                </div>


                <div
                    class="mlib-source-panel"
                    data-source-panel="link"
                    ${
                        currentMode !== "link"
                            ? 'style="display:none"'
                            : ""
                    }>

                    <input
                        id="mlib-url"
                        type="url"
                        value="${
                            currentMode === "link"
                                ? esc(item?.url || "")
                                : ""
                        }"
                        placeholder="https://...">

                </div>

            </div>
        `;
    }


    function coverSelector(item){

        const currentMode =
            item &&
            item.coverMode
                ? item.coverMode
                : coverMode;


        coverMode =
            currentMode;


        return `
            <div class="mlib-source-block">

                <label class="mlib-source-label">
                    Image de couverture
                    <span>facultative</span>
                </label>


                <div class="mlib-source-switch">

                    <button
                        type="button"
                        class="mlib-source-choice ${
                            currentMode === "file"
                                ? "active"
                                : ""
                        }"
                        data-cover-mode="file">
                        Choisir une image
                    </button>

                    <button
                        type="button"
                        class="mlib-source-choice ${
                            currentMode === "link"
                                ? "active"
                                : ""
                        }"
                        data-cover-mode="link">
                        URL de l'image
                    </button>

                </div>


                <div
                    class="mlib-source-panel"
                    data-cover-panel="file"
                    ${
                        currentMode !== "file"
                            ? 'style="display:none"'
                            : ""
                    }>

                    <input
                        class="mlib-file-input"
                        id="mlib-cover-file"
                        type="file"
                        accept="image/*">


                    <div class="mlib-current-file">

                        ${
                            item &&
                            item.coverMode === "file" &&
                            item.coverFileName
                                ? `
                                    Image actuelle :
                                    <strong>
                                        ${esc(item.coverFileName)}
                                    </strong>
                                `
                                : "PNG, JPG, WEBP..."
                        }

                    </div>

                </div>


                <div
                    class="mlib-source-panel"
                    data-cover-panel="link"
                    ${
                        currentMode !== "link"
                            ? 'style="display:none"'
                            : ""
                    }>

                    <input
                        id="mlib-image"
                        type="url"
                        value="${
                            currentMode === "link"
                                ? esc(item?.image || "")
                                : ""
                        }"
                        placeholder="https://...">

                </div>

            </div>
        `;
    }


    /* ======================================================
       FORMULAIRES
       ====================================================== */

    function formFields(item){

        item =
            item || {};


        if(activeTab === "recent"){

            return `
                <div class="mlib-field">
                    <label>Titre de la prédication</label>
                    <input
                        id="mlib-title"
                        type="text"
                        value="${esc(item.title)}"
                        placeholder="Ex : La foi qui persévère">
                </div>

                <div class="mlib-field">
                    <label>Prédicateur</label>
                    <input
                        id="mlib-speaker"
                        type="text"
                        value="${esc(item.speaker)}"
                        placeholder="Ex : Pasteur MARANATHA">
                </div>

                ${
                    sourceSelector(
                        item,
                        "audio/*,video/*",
                        "Audio ou vidéo"
                    )
                }
            `;
        }


        if(activeTab === "live"){

            return `
                <div class="mlib-field">
                    <label>Titre du direct</label>
                    <input
                        id="mlib-title"
                        type="text"
                        value="${esc(item.title)}"
                        placeholder="Ex : Culte du dimanche">
                </div>


                <div class="mlib-field">

                    <label>Type de direct</label>

                    <select id="mlib-platform">

                        <option value="audio" ${
                            item.platform === "audio"
                                ? "selected"
                                : ""
                        }>
                            Audio MARANATHA
                        </option>

                        <option value="youtube" ${
                            item.platform === "youtube"
                                ? "selected"
                                : ""
                        }>
                            YouTube
                        </option>

                        <option value="facebook" ${
                            item.platform === "facebook"
                                ? "selected"
                                : ""
                        }>
                            Facebook
                        </option>

                        <option value="tiktok" ${
                            item.platform === "tiktok"
                                ? "selected"
                                : ""
                        }>
                            TikTok
                        </option>

                    </select>

                </div>


                <div class="mlib-field">

                    <label>
                        Lien du direct / flux audio
                    </label>

                    <input
                        id="mlib-url"
                        type="url"
                        value="${esc(item.url)}"
                        placeholder="https://...">

                </div>


                <div class="mlib-note">
                    Un direct utilise un lien ou un flux en temps réel.
                    Pour un fichier MP3 enregistré, utilisez l'onglet
                    <strong>Audio MP3</strong>.
                </div>
            `;
        }


        if(activeTab === "audio"){

            return `
                <div class="mlib-field">
                    <label>Titre audio</label>
                    <input
                        id="mlib-title"
                        type="text"
                        value="${esc(item.title)}"
                        placeholder="Ex : Grandir dans la foi">
                </div>

                <div class="mlib-field">
                    <label>Prédicateur / Auteur</label>
                    <input
                        id="mlib-speaker"
                        type="text"
                        value="${esc(item.speaker)}"
                        placeholder="Ex : Pasteur MARANATHA">
                </div>

                ${
                    sourceSelector(
                        item,
                        "audio/*,.mp3,.m4a,.wav,.aac,.ogg",
                        "Fichier audio"
                    )
                }
            `;
        }


        if(activeTab === "video"){

            return `
                <div class="mlib-field">
                    <label>Titre de la vidéo</label>
                    <input
                        id="mlib-title"
                        type="text"
                        value="${esc(item.title)}"
                        placeholder="Ex : Message du dimanche">
                </div>

                ${
                    sourceSelector(
                        item,
                        "video/*,.mp4,.webm,.mov,.m4v",
                        "Vidéo"
                    )
                }

                ${
                    coverSelector(
                        item
                    )
                }
            `;
        }


        return `
            <div class="mlib-field">
                <label>Titre du livre</label>
                <input
                    id="mlib-title"
                    type="text"
                    value="${esc(item.title)}"
                    placeholder="Ex : La puissance de la prière">
            </div>

            <div class="mlib-field">
                <label>Auteur</label>
                <input
                    id="mlib-author"
                    type="text"
                    value="${esc(item.author)}"
                    placeholder="Ex : MARANATHA">
            </div>

            ${
                sourceSelector(
                    item,
                    "application/pdf,.pdf",
                    "Livre PDF"
                )
            }

            ${
                coverSelector(
                    item
                )
            }
        `;
    }


    function description(){

        const text = {

            recent:
                "Publiez les prédications récentes disponibles pour les fidèles.",

            live:
                "Publiez uniquement les directs actuellement actifs.",

            audio:
                "Choisissez un MP3 depuis l'appareil ou utilisez un lien.",

            video:
                "Choisissez une vidéo depuis l'appareil ou collez un lien YouTube, Facebook, etc.",

            book:
                "Choisissez directement le PDF depuis l'appareil ou utilisez un lien."
        };


        return text[activeTab];
    }


    function marker(item){

        if(activeTab === "recent"){
            return "REC";
        }

        if(activeTab === "audio"){
            return "MP3";
        }

        if(activeTab === "video"){
            return "VID";
        }

        if(activeTab === "book"){
            return "PDF";
        }


        return {
            audio:"LIVE",
            youtube:"YT",
            facebook:"FB",
            tiktok:"TT"
        }[item.platform] || "LIVE";
    }


    function meta(item){

        if(
            item.sourceMode === "file" &&
            item.fileName
        ){

            return item.fileName;
        }


        if(activeTab === "recent"){
            return item.speaker || "Prédication";
        }

        if(activeTab === "audio"){
            return item.speaker || "Audio MP3";
        }

        if(activeTab === "book"){
            return item.author || "Livre PDF";
        }

        if(activeTab === "live"){

            return {
                audio:"Audio MARANATHA",
                youtube:"YouTube",
                facebook:"Facebook",
                tiktok:"TikTok"
            }[item.platform] || "Direct";
        }


        return item.url || "Vidéo";
    }


    /* ======================================================
       AFFICHAGE
       ====================================================== */

    function render(){

        const pane =
            document.getElementById(
                "pane-livres"
            );


        if(!pane){
            return;
        }


        const data =
            readStore();


        const list =
            data[activeTab] || [];


        const item =
            editingId
                ? list.find(function(entry){

                    return (
                        entry.id ===
                        editingId
                    );

                }) || null
                : null;


        if(item){

            sourceMode =
                item.sourceMode ||
                "link";

            coverMode =
                item.coverMode ||
                "link";

        }else{

            sourceMode =
                "file";

            coverMode =
                "file";
        }


        pane.innerHTML = `
            <div class="mlib-admin">

                <div class="mlib-admin-head">

                    <div>

                        <h2 class="mlib-admin-title">
                            Bibliothèque
                        </h2>

                        <div class="mlib-admin-sub">
                            Tout contenu publié ici apparaît dans
                            la Bibliothèque des fidèles.
                        </div>

                    </div>


                    <div class="mlib-admin-state">
                        Synchronisation locale active
                    </div>

                </div>


                <div class="mlib-admin-tabs">

                    ${
                        tabs.map(function(tab){

                            return `
                                <button
                                    type="button"
                                    class="mlib-admin-tab ${
                                        tab[0] === activeTab
                                            ? "active"
                                            : ""
                                    }"
                                    data-mlib-tab="${tab[0]}">

                                    ${tab[1]}

                                </button>
                            `;

                        }).join("")
                    }

                </div>


                <div class="mlib-admin-grid">

                    <div class="mlib-admin-card">

                        <div class="mlib-admin-card-title">
                            ${
                                item
                                    ? "Modifier le contenu"
                                    : "Ajouter un contenu"
                            }
                        </div>

                        <div class="mlib-admin-card-desc">
                            ${description()}
                        </div>


                        <form id="mlib-admin-form">

                            ${formFields(item)}


                            <label class="mlib-check">

                                <input
                                    id="mlib-active"
                                    type="checkbox"
                                    ${
                                        !item ||
                                        item.active !== false
                                            ? "checked"
                                            : ""
                                    }>

                                Visible pour les fidèles

                            </label>


                            <div class="mlib-form-actions">

                                <button
                                    id="mlib-save"
                                    type="submit"
                                    class="mlib-primary">

                                    ${
                                        item
                                            ? "Enregistrer"
                                            : "+ Ajouter"
                                    }

                                </button>


                                ${
                                    item
                                        ? `
                                            <button
                                                type="button"
                                                class="mlib-secondary"
                                                data-mlib-cancel>
                                                Annuler
                                            </button>
                                        `
                                        : ""
                                }

                            </div>

                        </form>


                        <div class="mlib-sync-info">
                            <strong>Fichier :</strong>
                            sélection depuis PC ou téléphone.
                            <br>
                            <strong>Lien :</strong>
                            pour YouTube, Facebook, TikTok,
                            hébergement externe ou gros fichiers.
                        </div>

                    </div>


                    <div class="mlib-admin-card">

                        <div class="mlib-list-head">

                            <div>

                                <div class="mlib-admin-card-title">
                                    Contenus publiés
                                </div>

                                <div
                                    class="mlib-admin-card-desc"
                                    style="margin-bottom:0">

                                    Activer, modifier ou supprimer.

                                </div>

                            </div>


                            <div class="mlib-count">
                                ${list.length}
                            </div>

                        </div>


                        <div class="mlib-items">

                            ${
                                list.length
                                ? list.map(function(entry){

                                    return `
                                        <div class="mlib-item">

                                            <div class="mlib-item-marker ${
                                                activeTab === "live"
                                                    ? "live"
                                                    : ""
                                            }">
                                                ${marker(entry)}
                                            </div>


                                            <div class="mlib-item-main">

                                                <div class="mlib-item-title">
                                                    ${esc(entry.title)}
                                                </div>

                                                <div class="mlib-item-meta">
                                                    ${esc(meta(entry))}
                                                </div>

                                                <div class="mlib-status ${
                                                    entry.active !== false
                                                        ? "on"
                                                        : "off"
                                                }">

                                                    ${
                                                        entry.active !== false
                                                            ? "Visible"
                                                            : "Masqué"
                                                    }

                                                </div>

                                            </div>


                                            <div class="mlib-actions">

                                                <button
                                                    type="button"
                                                    class="mlib-action"
                                                    data-toggle="${entry.id}">

                                                    ${
                                                        entry.active !== false
                                                            ? "Masquer"
                                                            : "Afficher"
                                                    }

                                                </button>

                                                <button
                                                    type="button"
                                                    class="mlib-action"
                                                    data-edit="${entry.id}">
                                                    Modifier
                                                </button>

                                                <button
                                                    type="button"
                                                    class="mlib-action danger"
                                                    data-delete="${entry.id}">
                                                    Supprimer
                                                </button>

                                            </div>

                                        </div>
                                    `;

                                }).join("")
                                : `
                                    <div class="mlib-empty">
                                        Aucun contenu publié.
                                    </div>
                                `
                            }

                        </div>

                    </div>

                </div>


                <!-- compatibilite ancien chargerTout -->
                <div
                    id="livres-admin-list"
                    style="display:none!important">
                </div>

            </div>
        `;


        bind();
    }


    /* ======================================================
       INTERACTIONS
       ====================================================== */

    function field(id){

        return document.getElementById(
            id
        );
    }


    function value(id){

        return field(id)
            ? field(id).value.trim()
            : "";
    }


    function setSourceMode(mode){

        sourceMode =
            mode;


        document.querySelectorAll(
            "[data-source-mode]"
        )
        .forEach(function(button){

            button.classList.toggle(
                "active",
                button.dataset.sourceMode ===
                    mode
            );
        });


        document.querySelectorAll(
            "[data-source-panel]"
        )
        .forEach(function(panel){

            panel.style.display =
                panel.dataset.sourcePanel ===
                    mode
                    ? ""
                    : "none";
        });
    }


    function setCoverMode(mode){

        coverMode =
            mode;


        document.querySelectorAll(
            "[data-cover-mode]"
        )
        .forEach(function(button){

            button.classList.toggle(
                "active",
                button.dataset.coverMode ===
                    mode
            );
        });


        document.querySelectorAll(
            "[data-cover-panel]"
        )
        .forEach(function(panel){

            panel.style.display =
                panel.dataset.coverPanel ===
                    mode
                    ? ""
                    : "none";
        });
    }


    async function save(event){

        event.preventDefault();


        const title =
            value(
                "mlib-title"
            );


        if(!title){

            alert(
                "Saisissez un titre."
            );

            return;
        }


        const data =
            readStore();


        const list =
            data[activeTab] || [];


        let item =
            editingId
                ? list.find(function(entry){

                    return (
                        entry.id ===
                        editingId
                    );

                })
                : null;


        if(!item){

            item = {
                id:newId()
            };

            list.unshift(
                item
            );
        }


        const saveButton =
            field(
                "mlib-save"
            );


        if(saveButton){

            saveButton.disabled =
                true;

            saveButton.textContent =
                "Envoi...";
        }


        try{

            item.title =
                title;


            item.active =
                !!field(
                    "mlib-active"
                )?.checked;


            if(
                activeTab === "recent" ||
                activeTab === "audio"
            ){

                item.speaker =
                    value(
                        "mlib-speaker"
                    );
            }


            if(activeTab === "book"){

                item.author =
                    value(
                        "mlib-author"
                    );
            }


            if(activeTab === "live"){

                item.platform =
                    value(
                        "mlib-platform"
                    ) || "audio";


                item.url =
                    value(
                        "mlib-url"
                    );


                item.sourceMode =
                    "link";


                if(!item.url){

                    throw new Error(
                        "Ajoutez le lien du direct."
                    );
                }

            }else{

                item.sourceMode =
                    sourceMode;


                if(sourceMode === "file"){

                    const fileInput =
                        field(
                            "mlib-file"
                        );


                    const file =
                        fileInput &&
                        fileInput.files
                            ? fileInput.files[0]
                            : null;


                    if(file){

                        const uploaded =
                            await uploadFile(
                                file
                            );


                        item.url =
                            uploaded.url;

                        item.fileName =
                            file.name;

                        item.mimeType =
                            file.type;

                    }else if(
                        !item.url ||
                        item.sourceMode !== "file"
                    ){

                        throw new Error(
                            "Choisissez un fichier."
                        );
                    }

                }else{

                    item.url =
                        value(
                            "mlib-url"
                        );


                    item.fileName =
                        "";


                    if(!item.url){

                        throw new Error(
                            "Saisissez un lien."
                        );
                    }
                }
            }


            if(
                activeTab === "video" ||
                activeTab === "book"
            ){

                item.coverMode =
                    coverMode;


                if(coverMode === "file"){

                    const coverInput =
                        field(
                            "mlib-cover-file"
                        );


                    const cover =
                        coverInput &&
                        coverInput.files
                            ? coverInput.files[0]
                            : null;


                    if(cover){

                        const uploadedCover =
                            await uploadFile(
                                cover
                            );


                        item.image =
                            uploadedCover.url;

                        item.coverFileName =
                            cover.name;
                    }

                }else{

                    item.image =
                        value(
                            "mlib-image"
                        );

                    item.coverFileName =
                        "";
                }
            }


            data[activeTab] =
                list;


            writeStore(
                data
            );


            editingId =
                null;


            render();


        }catch(error){

            alert(
                error.message ||
                "Impossible d'enregistrer."
            );


            if(saveButton){

                saveButton.disabled =
                    false;

                saveButton.textContent =
                    "Enregistrer";
            }
        }
    }


    function bind(){

        document.querySelectorAll(
            "[data-mlib-tab]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    activeTab =
                        button.dataset.mlibTab;

                    editingId =
                        null;

                    render();
                }
            );
        });


        document.querySelectorAll(
            "[data-source-mode]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    setSourceMode(
                        button.dataset.sourceMode
                    );
                }
            );
        });


        document.querySelectorAll(
            "[data-cover-mode]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    setCoverMode(
                        button.dataset.coverMode
                    );
                }
            );
        });


        field(
            "mlib-file"
        )?.addEventListener(
            "change",
            function(event){

                const file =
                    event.target.files[0];


                const label =
                    field(
                        "mlib-current-file"
                    );


                if(
                    file &&
                    label
                ){

                    label.innerHTML =
                        "Sélectionné : <strong>" +
                        esc(file.name) +
                        "</strong>";
                }
            }
        );


        field(
            "mlib-admin-form"
        )?.addEventListener(
            "submit",
            save
        );


        document.querySelector(
            "[data-mlib-cancel]"
        )?.addEventListener(
            "click",
            function(){

                editingId =
                    null;

                render();
            }
        );


        document.querySelectorAll(
            "[data-edit]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    editingId =
                        button.dataset.edit;

                    render();
                }
            );
        });


        document.querySelectorAll(
            "[data-toggle]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    const data =
                        readStore();


                    const item =
                        data[activeTab]
                        .find(function(entry){

                            return (
                                entry.id ===
                                button.dataset.toggle
                            );
                        });


                    if(!item){
                        return;
                    }


                    item.active =
                        item.active === false;


                    writeStore(
                        data
                    );

                    render();
                }
            );
        });


        document.querySelectorAll(
            "[data-delete]"
        )
        .forEach(function(button){

            button.addEventListener(
                "click",
                function(){

                    if(
                        !confirm(
                            "Supprimer ce contenu ?"
                        )
                    ){
                        return;
                    }


                    const data =
                        readStore();


                    data[activeTab] =
                        data[activeTab]
                        .filter(function(entry){

                            return (
                                entry.id !==
                                button.dataset.delete
                            );
                        });


                    writeStore(
                        data
                    );


                    editingId =
                        null;


                    render();
                }
            );
        });
    }


    function init(){

        cleanOldDemo();

        render();
    }


    if(
        document.readyState ===
        "loading"
    ){

        document.addEventListener(
            "DOMContentLoaded",
            init
        );

    }else{

        init();
    }

})();