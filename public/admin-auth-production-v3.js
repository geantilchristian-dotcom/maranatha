(function(){
"use strict";
const STATE = {
    password:""
};
/* ==========================================================
   STYLE
   ========================================================== */
function installStyle(){
    if(
        document.getElementById(
            "maranatha-prod-auth-style"
        )
    ){
        return;
    }
    const style =
        document.createElement(
            "style"
        );
    style.id =
        "maranatha-prod-auth-style";
    style.textContent = `
        #maranatha-prod-auth {
            position:fixed;
            inset:0;
            z-index:2147483647;
            display:flex;
            align-items:center;
            justify-content:center;
            padding:24px;
            box-sizing:border-box;
            background:
                radial-gradient(
                    circle at 15% 12%,
                    rgba(192,0,26,.28),
                    transparent 24%
                ),
                radial-gradient(
                    circle at 85% 88%,
                    rgba(192,0,26,.12),
                    transparent 28%
                ),
                linear-gradient(
                    135deg,
                    #071a27 0%,
                    #071925 44%,
                    #120d18 100%
                );
            font-family:
                Arial,
                Helvetica,
                sans-serif;
        }
        #maranatha-prod-auth *,
        #maranatha-prod-auth *::before,
        #maranatha-prod-auth *::after {
            box-sizing:border-box;
        }
        .mpa-card {
            width:min(430px,100%);
            padding:38px 34px 32px;
            border-radius:28px;
            background:
                rgba(8,29,43,.94);
            border:
                1px solid
                rgba(255,255,255,.10);
            box-shadow:
                0 35px 90px
                rgba(0,0,0,.40);
            backdrop-filter:
                blur(22px);
            color:#fff;
        }
        .mpa-logo-wrap {
            width:70px;
            height:70px;
            margin:
                0 auto 18px;
            border-radius:50%;
            overflow:hidden;
            display:flex;
            align-items:center;
            justify-content:center;
            background:#fff;
            box-shadow:
                0 10px 32px
                rgba(192,0,26,.25);
        }
        .mpa-logo {
            width:100%;
            height:100%;
            object-fit:cover;
        }
        .mpa-title {
            margin:0;
            text-align:center;
            font-size:27px;
            font-weight:800;
            letter-spacing:.5px;
        }
        .mpa-subtitle {
            margin:
                8px 0 30px;
            text-align:center;
            color:
                rgba(255,255,255,.58);
            font-size:13px;
            line-height:1.5;
        }
        .mpa-label {
            display:block;
            margin-bottom:8px;
            color:
                rgba(255,255,255,.72);
            font-size:12px;
            font-weight:700;
            letter-spacing:.35px;
        }
        .mpa-password-wrap {
            position:relative;
        }
        #mpa-password {
            width:100%;
            height:54px;
            padding:
                0 52px 0 16px;
            border:
                1px solid
                rgba(255,255,255,.14);
            border-radius:14px;
            outline:none;
            background:
                rgba(255,255,255,.055);
            color:#fff;
            font-size:16px;
            transition:
                border-color .18s ease,
                box-shadow .18s ease;
        }
        #mpa-password:focus {
            border-color:
                rgba(212,175,55,.85);
            box-shadow:
                0 0 0 3px
                rgba(212,175,55,.10);
        }
        #mpa-toggle {
            position:absolute;
            right:9px;
            top:7px;
            width:40px;
            height:40px;
            border:0;
            border-radius:10px;
            background:transparent;
            color:
                rgba(255,255,255,.72);
            cursor:pointer;
            font-size:17px;
        }
        #mpa-error {
            min-height:22px;
            margin-top:10px;
            color:#ff707d;
            font-size:12px;
            font-weight:600;
            line-height:1.45;
        }
        #mpa-submit {
            width:100%;
            height:52px;
            margin-top:10px;
            border:0;
            border-radius:14px;
            background:
                linear-gradient(
                    135deg,
                    #b40018,
                    #d0122d
                );
            color:#fff;
            font-size:14px;
            font-weight:800;
            letter-spacing:.5px;
            cursor:pointer;
            box-shadow:
                0 13px 30px
                rgba(192,0,26,.22);
        }
        #mpa-submit:hover {
            filter:brightness(1.06);
        }
        #mpa-submit:disabled {
            opacity:.65;
            cursor:wait;
        }
        .mpa-security {
            margin-top:20px;
            text-align:center;
            color:
                rgba(255,255,255,.38);
            font-size:11px;
        }
        @media(max-width:520px){
            #maranatha-prod-auth {
                padding:16px;
            }
            .mpa-card {
                padding:
                    30px 22px 26px;
                border-radius:22px;
            }
        }
    `;
    document.head.appendChild(
        style
    );
}
/* ==========================================================
   CACHER ANCIEN LOGIN
   ========================================================== */
function hideLegacyLogin(){
    document.body.classList.remove(
        "admin-login-pro-mode"
    );
    document.body.style.removeProperty(
        "overflow"
    );
    document.body.style.removeProperty(
        "height"
    );
    document.body.style.removeProperty(
        "min-height"
    );
    document.querySelectorAll(
        ".admin-login-pro-card," +
        ".admin-login-simple-card"
    )
    .forEach(function(element){
        element.style.setProperty(
            "display",
            "none",
            "important"
        );
    });
    const dashboard =
        document.getElementById(
            "dashboard"
        );
    document.querySelectorAll(
        'input[type="password"]'
    )
    .forEach(function(input){
        if(
            input.id ===
            "mpa-password"
        ){
            return;
        }
        let current =
            input;
        let root =
            input;
        while(
            current.parentElement &&
            current.parentElement !==
            document.body
        ){
            const parent =
                current.parentElement;
            if(
                dashboard &&
                parent.contains(
                    dashboard
                )
            ){
                break;
            }
            root =
                parent;
            current =
                parent;
        }
        if(
            root &&
            root !== dashboard
        ){
            root.style.setProperty(
                "display",
                "none",
                "important"
            );
        }
    });
}
/* ==========================================================
   AUTH HEADERS
   ========================================================== */
function installAuthHeaders(){
    window.authHeaders =
        function(){
            if(!STATE.password){
                return {};
            }
            return {
                "x-admin-password":
                    STATE.password
            };
        };
}
/* ==========================================================
   AFFICHER DASHBOARD
   ========================================================== */
function showDashboard(){
    hideLegacyLogin();
    const dashboard =
        document.getElementById(
            "dashboard"
        );
    if(!dashboard){
        throw new Error(
            "#dashboard introuvable"
        );
    }
    dashboard.hidden =
        false;
    dashboard.style.setProperty(
        "display",
        "block",
        "important"
    );
    dashboard.style.setProperty(
        "visibility",
        "visible",
        "important"
    );
    dashboard.style.setProperty(
        "opacity",
        "1",
        "important"
    );
    dashboard.style.removeProperty(
        "transform"
    );
    document.body.style.removeProperty(
        "overflow"
    );
    try{
        if(
            typeof switchTab ===
            "function"
        ){
            switchTab(
                "stats"
            );
        }
    }catch(error){
        console.warn(
            "[ADMIN TAB]",
            error
        );
    }
    try{
        if(
            typeof chargerTout ===
            "function"
        ){
            Promise.resolve(
                chargerTout()
            )
            .catch(function(error){
                console.warn(
                    "[ADMIN CHARGEMENT]",
                    error
                );
            });
        }
    }catch(error){
        console.warn(
            "[ADMIN CHARGEMENT]",
            error
        );
    }
    window.scrollTo(
        0,
        0
    );
}
/* ==========================================================
   ERREUR
   ========================================================== */
function setError(message){
    const zone =
        document.getElementById(
            "mpa-error"
        );
    if(zone){
        zone.textContent =
            message || "";
    }
}
/* ==========================================================
   CONNEXION
   ========================================================== */
async function login(){
    const input =
        document.getElementById(
            "mpa-password"
        );
    const button =
        document.getElementById(
            "mpa-submit"
        );
    if(
        !input ||
        !button
    ){
        return;
    }
    const password =
        String(
            input.value || ""
        );
    if(!password){
        setError(
            "Veuillez saisir le mot de passe administrateur."
        );
        input.focus();
        return;
    }
    setError("");
    button.disabled =
        true;
    const oldText =
        button.textContent;
    button.textContent =
        "VÉRIFICATION...";
    try{
        const response =
            await fetch(
                "/api/admin/verify",
                {
                    method:"GET",
                    cache:"no-store",
                    headers:{
                        "Accept":
                            "application/json",
                        "x-admin-password":
                            password
                    }
                }
            );
        let result = {};
        try{
            result =
                await response.json();
        }catch(_error){}
        if(!response.ok){
            if(
                response.status ===
                401
            ){
                setError(
                    "Mot de passe administrateur incorrect."
                );
            }else if(
                response.status ===
                403
            ){
                setError(
                    "Accès administrateur refusé."
                );
            }else if(
                response.status ===
                404
            ){
                setError(
                    "Service de connexion administrateur introuvable."
                );
            }else if(
                response.status >=
                500
            ){
                setError(
                    result.error ||
                    "Erreur interne du serveur MARANATHA."
                );
            }else{
                setError(
                    result.error ||
                    result.message ||
                    (
                        "Connexion refusée (HTTP " +
                        response.status +
                        ")."
                    )
                );
            }
            input.focus();
            input.select();
            return;
        }
        if(
            !result ||
            result.ok !== true
        ){
            setError(
                result.error ||
                result.message ||
                "Le serveur n'a pas validé la connexion."
            );
            return;
        }
        /*
         * Mot de passe uniquement en mémoire.
         */
        STATE.password =
            password;
        window.__MARANATHA_ADMIN_PASSWORD =
            password;
        try{
            adminPassword =
                password;
        }catch(_error){}
        installAuthHeaders();
        input.value =
            "";
        const overlay =
            document.getElementById(
                "maranatha-prod-auth"
            );
        if(overlay){
            overlay.remove();
        }
        showDashboard();
        console.log(
            "[MARANATHA ADMIN] Connexion production OK"
        );
    }catch(error){
        console.error(
            "[ADMIN AUTH]",
            error
        );
        setError(
            "Impossible de joindre le serveur MARANATHA."
        );
    }finally{
        button.disabled =
            false;
        button.textContent =
            oldText;
    }
}
/* ==========================================================
   CONSTRUIRE LOGIN
   ========================================================== */
function build(){
    installStyle();
    hideLegacyLogin();
    const old =
        document.getElementById(
            "maranatha-prod-auth"
        );
    if(old){
        old.remove();
    }
    const overlay =
        document.createElement(
            "div"
        );
    overlay.id =
        "maranatha-prod-auth";
    overlay.innerHTML = `
        <div class="mpa-card">
            <div class="mpa-logo-wrap">
                <img
                    class="mpa-logo"
                    src="/logo.jpg"
                    alt="MARANATHA"
                    onerror="this.style.display='none'"
                />
            </div>
            <h1 class="mpa-title">
                MARANATHA
            </h1>
            <div class="mpa-subtitle">
                Espace d'administration
                <br>
                Accès sécurisé
            </div>
            <label
                class="mpa-label"
                for="mpa-password">
                MOT DE PASSE ADMINISTRATEUR
            </label>
            <div class="mpa-password-wrap">
                <input
                    id="mpa-password"
                    type="password"
                    autocomplete="current-password"
                    placeholder="Votre mot de passe"
                />
                <button
                    id="mpa-toggle"
                    type="button"
                    aria-label="Afficher le mot de passe">
                    ◉
                </button>
            </div>
            <div
                id="mpa-error"
                role="alert"
                aria-live="polite">
            </div>
            <button
                id="mpa-submit"
                type="button">
                SE CONNECTER
            </button>
            <div class="mpa-security">
                MARANATHA • Administration sécurisée
            </div>
        </div>
    `;
    document.body.appendChild(
        overlay
    );
    const input =
        document.getElementById(
            "mpa-password"
        );
    const submit =
        document.getElementById(
            "mpa-submit"
        );
    const toggle =
        document.getElementById(
            "mpa-toggle"
        );
    submit.addEventListener(
        "click",
        login
    );
    input.addEventListener(
        "keydown",
        function(event){
            if(
                event.key ===
                "Enter"
            ){
                event.preventDefault();
                login();
            }
        }
    );
    toggle.addEventListener(
        "click",
        function(){
            const visible =
                input.type ===
                "text";
            input.type =
                visible
                    ? "password"
                    : "text";
            toggle.textContent =
                visible
                    ? "◉"
                    : "●";
            input.focus();
        }
    );
    setTimeout(
        function(){
            input.focus();
        },
        80
    );
}
/* ==========================================================
   DECONNEXION
   ========================================================== */
document.addEventListener(
    "click",
    function(event){
        const logout =
            event.target.closest(
                ".btn-logout"
            );
        if(!logout){
            return;
        }
        STATE.password =
            "";
        window.__MARANATHA_ADMIN_PASSWORD =
            "";
        setTimeout(
            function(){
                window.location.replace(
                    "/admin.html"
                );
            },
            150
        );
    },
    true
);
/* ==========================================================
   DEMARRAGE
   ========================================================== */
installAuthHeaders();
if(
    document.readyState ===
    "loading"
){
    document.addEventListener(
        "DOMContentLoaded",
        build,
        {
            once:true
        }
    );
}else{
    build();
}
})();