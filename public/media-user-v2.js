(function(){

"use strict";

const KEY =
    "maranatha_media_v2";


const DEFAULT_BANNERS = [];


function read(){

    try{

        const raw =
            localStorage.getItem(KEY);


        if(!raw){

            return {
                banners:DEFAULT_BANNERS,
                social:{}
            };
        }


        return JSON.parse(raw);

    }catch(error){

        return {
            banners:DEFAULT_BANNERS,
            social:{}
        };
    }
}


async function loadRemote(){
    try{
        const response =
            await fetch(
                "/api/settings/home",
                {
                    cache:
                        "no-store"
                }
            );
        if(!response.ok){
            return;
        }
        const cfg =
            await response.json();
        const data = {
            banners:
                (
                    Array.isArray(
                        cfg.heroBanners
                    )
                        ? cfg.heroBanners
                        : []
                )
                .map(function(item){
                    return {
                        id:
                            item.id || "",
                        image:
                            item.imageUrl || "",
                        link:
                            item.link || "#",
                        title:
                            item.title || "",
                        active:
                            item.active !== false
                    };
                })
                .filter(function(item){
                    return item.image;
                }),
            social:{
                facebook:
                    cfg.facebookUrl || "",
                youtube:
                    cfg.youtubeChannelUrl || "",
                tiktok:
                    cfg.tiktokUrl || "",
                instagram:
                    cfg.instagramUrl || ""
            }
        };
        localStorage.setItem(
            KEY,
            JSON.stringify(data)
        );
    }catch(error){
        console.warn(
            "[MARANATHA MEDIA USER]",
            error
        );
    }
}
function renderBanners(){

    const hero =
        document.querySelector(
            ".hero"
        );


    if(!hero){
        return;
    }


    const data =
        read();


    const slides =
        (
            Array.isArray(data.banners)
                ? data.banners
                : DEFAULT_BANNERS
        )
        .filter(function(item){

            return (
                item &&
                item.active !== false &&
                item.image
            );
        });


    if(!slides.length){
        return;
    }


    hero.innerHTML = `
        <div class="maranatha-banner-carousel">

            <div class="mbc-track">

                ${
                    slides.map(
                        function(slide,index){

                            return `
                                <article
                                    class="mbc-slide"
                                    data-slide-index="${index}">

                                    <a
                                        class="mbc-slide-link"
                                        href="${slide.link || "#"}"
                                        aria-label="${slide.title || "Affiche"}">

                                        <img
                                            src="${slide.image}"
                                            alt="${slide.title || "Affiche"}"
                                            draggable="false">

                                    </a>

                                </article>
                            `;
                        }
                    ).join("")
                }

            </div>


            <div class="mbc-counter">

                <span class="mbc-current">
                    1
                </span>

                <span>
                    &nbsp;/&nbsp;
                </span>

                <span>
                    ${slides.length}
                </span>

            </div>


            <div class="mbc-dots">

                ${
                    slides.map(
                        function(_,index){

                            return `
                                <button
                                    type="button"
                                    class="mbc-dot ${
                                        index === 0
                                            ? "active"
                                            : ""
                                    }"
                                    data-banner-dot="${index}">
                                </button>
                            `;
                        }
                    ).join("")
                }

            </div>

        </div>
    `;


    const track =
        hero.querySelector(
            ".mbc-track"
        );


    const dots =
        Array.from(
            hero.querySelectorAll(
                ".mbc-dot"
            )
        );


    const label =
        hero.querySelector(
            ".mbc-current"
        );


    let current = 0;
    let timer = null;
    let startX = 0;
    let endX = 0;


    function show(index){

        current =
            (
                index +
                slides.length
            ) %
            slides.length;


        track.style.transform =
            `translateX(-${current * 100}%)`;


        dots.forEach(
            function(dot,i){

                dot.classList.toggle(
                    "active",
                    i === current
                );
            }
        );


        if(label){

            label.textContent =
                String(current + 1);
        }
    }


    function stop(){

        if(timer){

            clearInterval(timer);

            timer = null;
        }
    }


    function start(){

        stop();


        if(slides.length > 1){

            timer =
                setInterval(
                    function(){
                        show(
                            current + 1
                        );
                    },
                    5000
                );
        }
    }


    dots.forEach(
        function(dot,index){

            dot.addEventListener(
                "click",
                function(event){

                    event.preventDefault();

                    show(index);

                    start();
                }
            );
        }
    );


    const carousel =
        hero.querySelector(
            ".maranatha-banner-carousel"
        );


    carousel.addEventListener(
        "mouseenter",
        stop
    );


    carousel.addEventListener(
        "mouseleave",
        start
    );


    carousel.addEventListener(
        "touchstart",
        function(event){

            startX =
                event.touches[0].clientX;

            endX =
                startX;

            stop();

        },
        {
            passive:true
        }
    );


    carousel.addEventListener(
        "touchmove",
        function(event){

            endX =
                event.touches[0].clientX;

        },
        {
            passive:true
        }
    );


    carousel.addEventListener(
        "touchend",
        function(){

            const delta =
                endX - startX;


            if(
                Math.abs(delta) >
                45
            ){

                show(
                    current +
                    (
                        delta < 0
                            ? 1
                            : -1
                    )
                );
            }


            start();
        }
    );


    show(0);

    start();
}


function applySocial(){

    const social =
        read().social || {};


    const values = {

        Facebook:
            social.facebook || "",

        YouTube:
            social.youtube || "",

        TikTok:
            social.tiktok || "",

        Instagram:
            social.instagram || ""
    };


    Object.keys(values)
    .forEach(function(label){

        const button =
            document.querySelector(
                '.social-btn[aria-label="' +
                label +
                '"]'
            );


        if(!button){
            return;
        }


        const url =
            values[label];


        if(url){

            button.href =
                url;

            button.target =
                "_blank";

            button.rel =
                "noopener noreferrer";

        }else{

            button.href =
                "#";
        }
    });
}


function refresh(){

    renderBanners();

    applySocial();
}


function boot(){
    loadRemote()
        .finally(
            refresh
        );
}
if(document.readyState === "loading"){
    document.addEventListener(
        "DOMContentLoaded",
        boot
    );
}else{
    boot();
}


setTimeout(
    applySocial,
    600
);


window.addEventListener(
    "storage",
    function(event){

        if(event.key === KEY){

            refresh();
        }
    }
);


window.addEventListener(
    "maranatha-media-updated",
    refresh
);

})();