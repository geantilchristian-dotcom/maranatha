(function(){
"use strict";
if(window.__MARANATHA_UPLOAD_PROGRESS_V3__){
    return;
}
window.__MARANATHA_UPLOAD_PROGRESS_V3__ = true;
let running = 0;
let value = 0;
let timer = null;
let hideTimer = null;
function install(){
    if(document.getElementById("mara-upload-line")){
        return;
    }
    const style =
        document.createElement("style");
    style.textContent = `
        #mara-upload-line{
            position:fixed;
            top:0;
            left:0;
            right:0;
            height:5px;
            z-index:2147483647;
            opacity:0;
            pointer-events:none;
            background:rgba(255,255,255,.08);
            transition:opacity .18s ease;
        }
        #mara-upload-line.show{
            opacity:1;
        }
        #mara-upload-bar{
            width:0%;
            height:100%;
            background:
                linear-gradient(
                    90deg,
                    #d4af37,
                    #ffe47a
                );
            box-shadow:
                0 0 14px rgba(212,175,55,.65);
            transition:width .18s ease;
        }
        #mara-upload-box{
            position:fixed;
            top:14px;
            right:18px;
            z-index:2147483647;
            display:flex;
            align-items:center;
            gap:8px;
            padding:8px 13px;
            border-radius:18px;
            border:1px solid rgba(212,175,55,.30);
            background:#0a2535;
            color:#fff;
            font-family:"Segoe UI",Arial,sans-serif;
            font-size:11px;
            font-weight:700;
            box-shadow:0 8px 22px rgba(0,0,0,.28);
            opacity:0;
            transform:translateY(-6px);
            pointer-events:none;
            transition:
                opacity .18s ease,
                transform .18s ease;
        }
        #mara-upload-box.show{
            opacity:1;
            transform:translateY(0);
        }
        #mara-upload-dot{
            width:7px;
            height:7px;
            border-radius:50%;
            background:#d4af37;
            box-shadow:0 0 0 4px rgba(212,175,55,.12);
        }
        #mara-upload-box.loading #mara-upload-dot{
            animation:maraPulse .85s infinite ease-in-out;
        }
        #mara-upload-box.success #mara-upload-dot{
            background:#2dd36f;
            box-shadow:0 0 0 4px rgba(45,211,111,.13);
        }
        #mara-upload-box.error #mara-upload-dot{
            background:#ff5366;
            box-shadow:0 0 0 4px rgba(255,83,102,.13);
        }
        @keyframes maraPulse{
            0%,100%{
                transform:scale(.75);
                opacity:.6;
            }
            50%{
                transform:scale(1.3);
                opacity:1;
            }
        }
    `;
    document.head.appendChild(style);
    const line =
        document.createElement("div");
    line.id =
        "mara-upload-line";
    line.innerHTML =
        '<div id="mara-upload-bar"></div>';
    const box =
        document.createElement("div");
    box.id =
        "mara-upload-box";
    box.innerHTML = `
        <span id="mara-upload-dot"></span>
        <span id="mara-upload-text">
            Chargement en cours...
        </span>
    `;
    document.body.appendChild(line);
    document.body.appendChild(box);
}
function getUi(){
    install();
    return {
        line:
            document.getElementById("mara-upload-line"),
        bar:
            document.getElementById("mara-upload-bar"),
        box:
            document.getElementById("mara-upload-box"),
        text:
            document.getElementById("mara-upload-text")
    };
}
function setProgress(next){
    value =
        Math.max(
            0,
            Math.min(
                100,
                next
            )
        );
    getUi().bar.style.width =
        value + "%";
}
function setState(type,text){
    const ui =
        getUi();
    ui.box.classList.remove(
        "loading",
        "success",
        "error"
    );
    ui.box.classList.add(type);
    ui.text.textContent =
        text;
}
function begin(){
    clearTimeout(hideTimer);
    running++;
    if(running > 1){
        return;
    }
    const ui =
        getUi();
    ui.line.classList.add("show");
    ui.box.classList.add("show");
    value = 5;
    setProgress(5);
    setState(
        "loading",
        "Chargement en cours... 5%"
    );
    clearInterval(timer);
    timer =
        setInterval(
            function(){
                if(value >= 92){
                    return;
                }
                value +=
                    Math.max(
                        0.7,
                        (92 - value) * 0.06
                    );
                setProgress(value);
                setState(
                    "loading",
                    "Chargement en cours... " +
                    Math.round(value) +
                    "%"
                );
            },
            180
        );
}
function finish(ok){
    running =
        Math.max(
            0,
            running - 1
        );
    if(running > 0){
        return;
    }
    clearInterval(timer);
    timer = null;
    setProgress(100);
    setState(
        ok ? "success" : "error",
        ok
            ? "Chargement terminé - 100%"
            : "Échec du chargement"
    );
    hideTimer =
        setTimeout(
            function(){
                const ui =
                    getUi();
                ui.line.classList.remove("show");
                ui.box.classList.remove("show");
                setTimeout(
                    function(){
                        setProgress(0);
                    },
                    220
                );
            },
            ok ? 1000 : 2200
        );
}
function bodyHasFile(body){
    if(!body){
        return false;
    }
    if(
        typeof Blob !== "undefined" &&
        body instanceof Blob
    ){
        return true;
    }
    if(
        typeof FormData !== "undefined" &&
        body instanceof FormData
    ){
        try{
            for(const entry of body.entries()){
                if(
                    typeof Blob !== "undefined" &&
                    entry[1] instanceof Blob
                ){
                    return true;
                }
            }
        }catch(_error){}
    }
    return false;
}
function isUpload(input,options){
    let url = "";
    try{
        if(typeof input === "string"){
            url = input;
        }else if(
            input &&
            typeof input.url === "string"
        ){
            url = input.url;
        }
    }catch(_error){}
    if(
        /\/upload(?:\/|$|\?)/i.test(url)
    ){
        return true;
    }
    return bodyHasFile(
        options && options.body
    );
}
/*
 * Toutes les fonctions actuelles Médias,
 * Programme et Bibliothèque utilisent fetch().
 */
const nativeFetch =
    window.fetch.bind(window);
window.fetch =
    async function(input,options){
        const upload =
            isUpload(
                input,
                options
            );
        if(!upload){
            return nativeFetch(
                input,
                options
            );
        }
        begin();
        try{
            const response =
                await nativeFetch(
                    input,
                    options
                );
            finish(response.ok);
            return response;
        }catch(error){
            finish(false);
            throw error;
        }
    };
if(
    document.readyState ===
    "loading"
){
    document.addEventListener(
        "DOMContentLoaded",
        install,
        {
            once:true
        }
    );
}else{
    install();
}
console.log(
    "[MARANATHA] Progression upload V3 active"
);
})();