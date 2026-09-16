(function(){

"use strict";

const KEY =
    "maranatha_media_v2";


const DEFAULT_BANNERS = [
    {
        image:"/test-banners/affiche-1.svg",
        link:"#bibliotheque",
        title:"Jésus revient bientôt",
        active:true
    },
    {
        image:"/test-banners/affiche-2.svg",
        link:"#programme",
        title:"Grande célébration du dimanche",
        active:true
    },
    {
        image:"/test-banners/affiche-3.svg",
        link:"#priere",
        title:"Nuit de prière",
        active:true
    },
    {
        image:"/test-banners/affiche-4.svg",
        link:"#",
        title:"Conférence de la jeunesse",
        active:true
    },
    {
        image:"/test-banners/affiche-5.svg",
        link:"#programme",
        title:"Semaine de réveil spirituel",
        active:true
    }
];


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


if(document.readyState === "loading"){

    document.addEventListener(
        "DOMContentLoaded",
        refresh
    );

}else{

    refresh();
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