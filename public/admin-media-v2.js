(function(){

"use strict";

const KEY = "maranatha_media_v2";

const DEFAULTS = {

    banners:[
        {
            id:"banner-1",
            image:"/test-banners/affiche-1.svg",
            link:"#bibliotheque",
            title:"Jésus revient bientôt",
            active:true
        },
        {
            id:"banner-2",
            image:"/test-banners/affiche-2.svg",
            link:"#programme",
            title:"Grande célébration du dimanche",
            active:true
        },
        {
            id:"banner-3",
            image:"/test-banners/affiche-3.svg",
            link:"#priere",
            title:"Nuit de prière",
            active:true
        },
        {
            id:"banner-4",
            image:"/test-banners/affiche-4.svg",
            link:"#",
            title:"Conférence de la jeunesse",
            active:true
        },
        {
            id:"banner-5",
            image:"/test-banners/affiche-5.svg",
            link:"#programme",
            title:"Semaine de réveil spirituel",
            active:true
        }
    ],

    featuredVideos:[],

    social:{
        facebook:"",
        youtube:"",
        tiktok:"",
        instagram:""
    },

    importedSettings:false
};


let activeTab = "banners";
let editingBanner = null;
let bannerSource = "file";


function cloneDefaults(){
    return JSON.parse(
        JSON.stringify(DEFAULTS)
    );
}


function readStore(){

    try{

        const raw =
            localStorage.getItem(KEY);

        if(!raw){

            const data =
                cloneDefaults();

            localStorage.setItem(
                KEY,
                JSON.stringify(data)
            );

            return data;
        }

        const data =
            JSON.parse(raw);

        if(!Array.isArray(data.banners)){
            data.banners = cloneDefaults().banners;
        }

        if(!Array.isArray(data.featuredVideos)){
            data.featuredVideos = [];
        }

        if(!data.social){
            data.social = cloneDefaults().social;
        }

        return data;

    }catch(error){

        return cloneDefaults();
    }
}


function writeStore(data){

    localStorage.setItem(
        KEY,
        JSON.stringify(data)
    );

    window.dispatchEvent(
        new CustomEvent(
            "maranatha-media-updated",
            {
                detail:data
            }
        )
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


function id(){
    return (
        Date.now().toString(36) +
        Math.random()
            .toString(36)
            .slice(2,7)
    );
}


function auth(){

    try{

        if(
            typeof window.authHeaders ===
            "function"
        ){
            return window.authHeaders();
        }

        if(
            typeof authHeaders ===
            "function"
        ){
            return authHeaders();
        }

    }catch(_error){}

    return {};
}


async function importRealSettings(){

    const data =
        readStore();

    if(data.importedSettings){
        return;
    }


    try{

        const res =
            await fetch(
                "/api/settings/home"
            );


        if(res.ok){

            const cfg =
                await res.json();


            if(
                Array.isArray(
                    cfg.youtubeLinks
                )
            ){

                data.featuredVideos =
                    cfg.youtubeLinks
                    .map(function(item){

                        return {
                            id:id(),
                            url:item.url || "",
                            label:
                                item.label ||
                                "Regarder"
                        };
                    })
                    .filter(function(item){
                        return item.url;
                    });

            }else if(cfg.youtubeUrl){

                data.featuredVideos = [
                    {
                        id:id(),
                        url:cfg.youtubeUrl,
                        label:
                            cfg.ytLabel ||
                            "Regarder"
                    }
                ];
            }


            data.social.facebook =
                cfg.facebookUrl || "";

            data.social.youtube =
                cfg.youtubeChannelUrl || "";

            data.social.tiktok =
                cfg.tiktokUrl || "";

            data.social.instagram =
                cfg.instagramUrl || "";
        }

    }catch(error){

        console.warn(
            "[MEDIAS] settings/home indisponible",
            error
        );
    }


    data.importedSettings =
        true;


    writeStore(data);
}


async function saveSettings(partial){

    try{

        await fetch(
            "/api/settings/home",
            {
                method:"PUT",

                headers:{
                    "Content-Type":
                        "application/json",
                    ...auth()
                },

                body:
                    JSON.stringify(
                        partial
                    )
            }
        );

    }catch(error){

        console.warn(
            "[MEDIAS] sauvegarde API locale indisponible",
            error
        );
    }
}


async function upload(file){

    if(!file){
        return "";
    }


    const res =
        await fetch(
            "/api/library-preview-upload",
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


    const result =
        await res.json();


    if(
        !res.ok ||
        !result.ok
    ){

        throw new Error(
            result.error ||
            "Impossible d'envoyer l'image."
        );
    }


    return result.url;
}


function compatibility(){

    return `
        <div style="display:none!important">

            <div id="yt-links-list"></div>

            <input id="social-fb">
            <input id="social-yt">
            <input id="social-tt">

            <button id="btn-home"></button>
            <button id="btn-social"></button>

            <div id="videos-admin-list"></div>

        </div>
    `;
}


function bannerPanel(data){

    const current =
        editingBanner
            ? data.banners.find(
                function(item){
                    return (
                        item.id ===
                        editingBanner
                    );
                }
            )
            : null;


    return `
        <div class="media2-grid">

            <div class="media2-card">

                <h3>
                    ${
                        current
                            ? "Modifier l'affiche"
                            : "Ajouter une affiche"
                    }
                </h3>

                <div class="media2-desc">
                    Les affiches visibles ici sont les mêmes que
                    sur l'accueil des fidèles.
                </div>


                <form id="media2-banner-form">

                    <div class="media2-field">
                        <label>Titre</label>

                        <input
                            id="media2-banner-title"
                            value="${esc(current?.title || "")}"
                            placeholder="Ex : Culte du dimanche">
                    </div>


                    <div class="media2-field">
                        <label>Lien après clic</label>

                        <input
                            id="media2-banner-link"
                            value="${esc(current?.link || "#")}"
                            placeholder="#programme ou https://...">
                    </div>


                    <div class="media2-field">

                        <label>Image</label>


                        <div class="media2-source">

                            <button
                                type="button"
                                data-banner-source="file"
                                class="${
                                    bannerSource === "file"
                                        ? "active"
                                        : ""
                                }">
                                Choisir sur l'appareil
                            </button>

                            <button
                                type="button"
                                data-banner-source="url"
                                class="${
                                    bannerSource === "url"
                                        ? "active"
                                        : ""
                                }">
                                Utiliser un lien
                            </button>

                        </div>


                        <div
                            data-banner-panel="file"
                            ${
                                bannerSource !== "file"
                                    ? 'style="display:none"'
                                    : ""
                            }>

                            <input
                                id="media2-banner-file"
                                class="media2-file"
                                type="file"
                                accept="image/*">

                        </div>


                        <div
                            data-banner-panel="url"
                            ${
                                bannerSource !== "url"
                                    ? 'style="display:none"'
                                    : ""
                            }>

                            <input
                                id="media2-banner-url"
                                type="url"
                                value="${
                                    bannerSource === "url"
                                        ? esc(current?.image || "")
                                        : ""
                                }"
                                placeholder="https://...">

                        </div>

                    </div>


                    ${
                        current?.image
                            ? `
                                <div
                                    style="
                                        margin-bottom:12px;
                                        border-radius:10px;
                                        overflow:hidden;
                                        aspect-ratio:16/7;
                                    ">

                                    <img
                                        src="${esc(current.image)}"
                                        style="
                                            width:100%;
                                            height:100%;
                                            object-fit:cover;
                                            display:block;
                                        ">

                                </div>
                            `
                            : ""
                    }


                    <label class="media2-check">

                        <input
                            id="media2-banner-active"
                            type="checkbox"
                            ${
                                !current ||
                                current.active !== false
                                    ? "checked"
                                    : ""
                            }>

                        Visible chez les fidèles

                    </label>


                    <div
                        style="
                            display:flex;
                            gap:7px;
                        ">

                        <button
                            class="media2-primary"
                            type="submit">

                            ${
                                current
                                    ? "Enregistrer"
                                    : "+ Ajouter"
                            }

                        </button>


                        ${
                            current
                                ? `
                                    <button
                                        class="media2-secondary"
                                        type="button"
                                        data-banner-cancel>
                                        Annuler
                                    </button>
                                `
                                : ""
                        }

                    </div>

                </form>

            </div>


            <div class="media2-card">

                <h3>
                    Affiches actuelles
                </h3>

                <div class="media2-desc">
                    ${data.banners.length}
                    affiche(s) configurée(s)
                </div>


                <div class="media2-list">

                    ${
                        data.banners
                        .map(function(item,index){

                            return `
                                <div class="media2-banner">

                                    <div class="media2-banner-img">

                                        <img
                                            src="${esc(item.image)}"
                                            alt="${esc(item.title)}">

                                        ${
                                            item.active === false
                                                ? `
                                                    <span class="media2-hidden">
                                                        Masquée
                                                    </span>
                                                `
                                                : ""
                                        }

                                    </div>


                                    <div class="media2-banner-body">

                                        <div class="media2-banner-title">
                                            ${index + 1}.
                                            ${esc(item.title)}
                                        </div>

                                        <div class="media2-banner-link">
                                            ${esc(item.link || "#")}
                                        </div>


                                        <div class="media2-actions">

                                            <button
                                                class="media2-secondary"
                                                data-banner-toggle="${item.id}">
                                                ${
                                                    item.active === false
                                                        ? "Afficher"
                                                        : "Masquer"
                                                }
                                            </button>

                                            <button
                                                class="media2-secondary"
                                                data-banner-edit="${item.id}">
                                                Modifier
                                            </button>

                                            <button
                                                class="media2-secondary media2-danger"
                                                data-banner-delete="${item.id}">
                                                Supprimer
                                            </button>

                                        </div>

                                    </div>

                                </div>
                            `;

                        }).join("")
                    }

                </div>

            </div>

        </div>
    `;
}


function videoPanel(data){

    return `
        <div class="media2-grid">

            <div class="media2-card">

                <h3>
                    Ajouter une vidéo en vedette
                </h3>

                <div class="media2-desc">
                    Ces liens utilisent la configuration
                    Accueil existante.
                </div>


                <form id="media2-video-form">

                    <div class="media2-field">

                        <label>Lien YouTube</label>

                        <input
                            id="media2-video-url"
                            type="url"
                            placeholder="https://youtube.com/watch?v=...">

                    </div>


                    <div class="media2-field">

                        <label>Texte du bouton</label>

                        <input
                            id="media2-video-label"
                            placeholder="Regarder">

                    </div>


                    <button
                        class="media2-primary"
                        type="submit">
                        + Ajouter
                    </button>

                </form>

            </div>


            <div class="media2-card">

                <h3>
                    Vidéos actuellement configurées
                </h3>

                <div class="media2-desc">
                    ${data.featuredVideos.length}
                    vidéo(s)
                </div>


                ${
                    data.featuredVideos.length
                        ? data.featuredVideos
                          .map(function(video){

                            return `
                                <div class="media2-video-row">

                                    <div class="media2-video-main">

                                        <div class="media2-video-title">
                                            ${esc(video.label || "Regarder")}
                                        </div>

                                        <div class="media2-video-url">
                                            ${esc(video.url)}
                                        </div>

                                    </div>


                                    <a
                                        href="${esc(video.url)}"
                                        target="_blank"
                                        class="media2-secondary"
                                        style="
                                            display:flex;
                                            align-items:center;
                                            text-decoration:none;
                                        ">
                                        Voir
                                    </a>


                                    <button
                                        class="media2-secondary media2-danger"
                                        data-video-delete="${video.id}">
                                        Supprimer
                                    </button>

                                </div>
                            `;

                          }).join("")
                        : `
                            <div
                                style="
                                    padding:30px;
                                    text-align:center;
                                    color:rgba(255,255,255,.35);
                                    font-size:10px;
                                ">
                                Aucune vidéo configurée.
                            </div>
                        `
                }

            </div>

        </div>
    `;
}


function socialPanel(data){

    return `
        <div class="media2-card media2-social">

            <h3>
                Réseaux sociaux de l'église
            </h3>

            <div class="media2-desc">
                Les boutons de l'accueil fidèle utiliseront
                exactement ces liens.
            </div>


            <form id="media2-social-form">

                <div class="media2-field">
                    <label>Facebook</label>

                    <input
                        id="media2-facebook"
                        type="url"
                        value="${esc(data.social.facebook || "")}"
                        placeholder="https://facebook.com/...">
                </div>


                <div class="media2-field">
                    <label>YouTube</label>

                    <input
                        id="media2-youtube"
                        type="url"
                        value="${esc(data.social.youtube || "")}"
                        placeholder="https://youtube.com/@...">
                </div>


                <div class="media2-field">
                    <label>TikTok</label>

                    <input
                        id="media2-tiktok"
                        type="url"
                        value="${esc(data.social.tiktok || "")}"
                        placeholder="https://tiktok.com/@...">
                </div>


                <div class="media2-field">
                    <label>Instagram</label>

                    <input
                        id="media2-instagram"
                        type="url"
                        value="${esc(data.social.instagram || "")}"
                        placeholder="https://instagram.com/...">
                </div>


                <button
                    class="media2-primary"
                    type="submit">
                    Enregistrer les liens
                </button>

            </form>


            <div class="media2-note">
                Un champ vide signifie que le réseau n'est pas
                configuré. Aucun faux lien ne sera inventé.
            </div>

        </div>
    `;
}


function render(){

    const pane =
        document.getElementById(
            "pane-medias"
        );


    if(!pane){
        return;
    }


    const data =
        readStore();


    pane.innerHTML = `
        <div class="media2">

            <div class="media2-head">

                <div>
                    <h2 class="media2-title">
                        Médias
                    </h2>

                    <div class="media2-sub">
                        Contrôlez les contenus visibles sur
                        l'accueil des fidèles.
                    </div>
                </div>


                <div class="media2-state">
                    ● Synchronisation locale active
                </div>

            </div>


            <div class="media2-tabs">

                <button
                    class="media2-tab ${
                        activeTab === "banners"
                            ? "active"
                            : ""
                    }"
                    data-media-tab="banners">
                    Bannières / Affiches
                </button>

                <button
                    class="media2-tab ${
                        activeTab === "videos"
                            ? "active"
                            : ""
                    }"
                    data-media-tab="videos">
                    Vidéos en vedette
                </button>

                <button
                    class="media2-tab ${
                        activeTab === "social"
                            ? "active"
                            : ""
                    }"
                    data-media-tab="social">
                    Réseaux sociaux
                </button>

            </div>


            ${
                activeTab === "banners"
                    ? bannerPanel(data)
                    : activeTab === "videos"
                        ? videoPanel(data)
                        : socialPanel(data)
            }


            ${compatibility()}

        </div>
    `;


    bind();
}


function setBannerSource(mode){

    bannerSource =
        mode;


    document.querySelectorAll(
        "[data-banner-source]"
    )
    .forEach(function(button){

        button.classList.toggle(
            "active",
            button.dataset.bannerSource === mode
        );
    });


    document.querySelectorAll(
        "[data-banner-panel]"
    )
    .forEach(function(panel){

        panel.style.display =
            panel.dataset.bannerPanel === mode
                ? ""
                : "none";
    });
}


async function saveBanner(event){

    event.preventDefault();


    const data =
        readStore();


    let item =
        editingBanner
            ? data.banners.find(
                function(banner){
                    return banner.id === editingBanner;
                }
            )
            : null;


    if(!item){

        item = {
            id:id()
        };

        data.banners.push(item);
    }


    item.title =
        document.getElementById(
            "media2-banner-title"
        ).value.trim();


    item.link =
        document.getElementById(
            "media2-banner-link"
        ).value.trim() || "#";


    item.active =
        document.getElementById(
            "media2-banner-active"
        ).checked;


    try{

        if(bannerSource === "file"){

            const input =
                document.getElementById(
                    "media2-banner-file"
                );


            const file =
                input?.files?.[0];


            if(file){

                item.image =
                    await upload(file);

            }else if(!item.image){

                alert(
                    "Choisissez une image."
                );

                return;
            }

        }else{

            const url =
                document.getElementById(
                    "media2-banner-url"
                ).value.trim();


            if(url){
                item.image = url;
            }


            if(!item.image){

                alert(
                    "Saisissez l'URL de l'image."
                );

                return;
            }
        }


        if(!item.title){
            item.title = "Affiche MARANATHA";
        }


        writeStore(data);


        editingBanner =
            null;


        render();


    }catch(error){

        alert(
            error.message ||
            "Impossible d'enregistrer l'affiche."
        );
    }
}


async function syncFeatured(data){

    await saveSettings({
        youtubeLinks:
            data.featuredVideos.map(
                function(video){

                    return {
                        url:video.url,
                        label:video.label
                    };
                }
            )
    });
}


function bind(){

    document.querySelectorAll(
        "[data-media-tab]"
    )
    .forEach(function(button){

        button.addEventListener(
            "click",
            function(){

                activeTab =
                    button.dataset.mediaTab;

                editingBanner =
                    null;

                render();
            }
        );
    });


    document.querySelectorAll(
        "[data-banner-source]"
    )
    .forEach(function(button){

        button.addEventListener(
            "click",
            function(){

                setBannerSource(
                    button.dataset.bannerSource
                );
            }
        );
    });


    document.getElementById(
        "media2-banner-form"
    )?.addEventListener(
        "submit",
        saveBanner
    );


    document.querySelector(
        "[data-banner-cancel]"
    )?.addEventListener(
        "click",
        function(){

            editingBanner =
                null;

            render();
        }
    );


    document.querySelectorAll(
        "[data-banner-edit]"
    )
    .forEach(function(button){

        button.addEventListener(
            "click",
            function(){

                editingBanner =
                    button.dataset.bannerEdit;


                const data =
                    readStore();


                const item =
                    data.banners.find(
                        function(banner){
                            return (
                                banner.id ===
                                editingBanner
                            );
                        }
                    );


                bannerSource =
                    item &&
                    item.image &&
                    item.image.startsWith("http")
                        ? "url"
                        : "file";


                render();
            }
        );
    });


    document.querySelectorAll(
        "[data-banner-toggle]"
    )
    .forEach(function(button){

        button.addEventListener(
            "click",
            function(){

                const data =
                    readStore();


                const item =
                    data.banners.find(
                        function(banner){
                            return (
                                banner.id ===
                                button.dataset.bannerToggle
                            );
                        }
                    );


                if(!item){
                    return;
                }


                item.active =
                    item.active === false;


                writeStore(data);

                render();
            }
        );
    });


    document.querySelectorAll(
        "[data-banner-delete]"
    )
    .forEach(function(button){

        button.addEventListener(
            "click",
            function(){

                if(
                    !confirm(
                        "Supprimer cette affiche ?"
                    )
                ){
                    return;
                }


                const data =
                    readStore();


                data.banners =
                    data.banners.filter(
                        function(item){

                            return (
                                item.id !==
                                button.dataset.bannerDelete
                            );
                        }
                    );


                writeStore(data);

                render();
            }
        );
    });


    document.getElementById(
        "media2-video-form"
    )?.addEventListener(
        "submit",
        async function(event){

            event.preventDefault();


            const url =
                document.getElementById(
                    "media2-video-url"
                ).value.trim();


            const label =
                document.getElementById(
                    "media2-video-label"
                ).value.trim();


            if(!url){

                alert(
                    "Ajoutez le lien YouTube."
                );

                return;
            }


            const data =
                readStore();


            data.featuredVideos.push({
                id:id(),
                url:url,
                label:
                    label ||
                    "Regarder"
            });


            writeStore(data);

            await syncFeatured(data);

            render();
        }
    );


    document.querySelectorAll(
        "[data-video-delete]"
    )
    .forEach(function(button){

        button.addEventListener(
            "click",
            async function(){

                const data =
                    readStore();


                data.featuredVideos =
                    data.featuredVideos.filter(
                        function(video){

                            return (
                                video.id !==
                                button.dataset.videoDelete
                            );
                        }
                    );


                writeStore(data);

                await syncFeatured(data);

                render();
            }
        );
    });


    document.getElementById(
        "media2-social-form"
    )?.addEventListener(
        "submit",
        async function(event){

            event.preventDefault();


            const data =
                readStore();


            data.social = {

                facebook:
                    document.getElementById(
                        "media2-facebook"
                    ).value.trim(),

                youtube:
                    document.getElementById(
                        "media2-youtube"
                    ).value.trim(),

                tiktok:
                    document.getElementById(
                        "media2-tiktok"
                    ).value.trim(),

                instagram:
                    document.getElementById(
                        "media2-instagram"
                    ).value.trim()
            };


            writeStore(data);


            await saveSettings({

                facebookUrl:
                    data.social.facebook,

                youtubeChannelUrl:
                    data.social.youtube,

                tiktokUrl:
                    data.social.tiktok,

                instagramUrl:
                    data.social.instagram
            });


            alert(
                "Liens enregistrés."
            );
        }
    );
}


async function init(){

    await importRealSettings();

    render();
}


if(document.readyState === "loading"){

    document.addEventListener(
        "DOMContentLoaded",
        init
    );

}else{

    init();
}

})();