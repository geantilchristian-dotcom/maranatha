(function(){

"use strict";

/* MARANATHA_PROGRAMME_USER_MONGODB_V1 */

const KEY =
    "maranatha_program_v2";


function normalize(item,index){

    item =
        item &&
        typeof item === "object"
            ? item
            : {};


    return {

        id:
            String(
                item.id ||
                item._id ||
                (
                    "programme-" +
                    Date.now() +
                    "-" +
                    index
                )
            ),

        name:
            String(
                item.name ||
                item.title ||
                item.titre ||
                item.badge ||
                "PROGRAMME"
            ),

        date:
            String(
                item.date ||
                item.dateStr ||
                ""
            ),

        time:
            String(
                item.time ||
                item.heure ||
                item.heureStr ||
                ""
            ),

        location:
            String(
                item.location ||
                item.lieu ||
                ""
            ),

        details:
            String(
                item.details ||
                item.description ||
                ""
            ),

        image:
            String(
                item.image ||
                item.imageUrl ||
                ""
            ),

        active:
            item.active !== false
    };
}


async function refreshProgramme(){

    try{

        const response =
            await fetch(
                "/api/settings/programme",
                {
                    cache:
                        "no-store"
                }
            );


        if(!response.ok){
            throw new Error(
                "HTTP " +
                response.status
            );
        }


        const payload =
            await response.json();


        const items =
            Array.isArray(
                payload.items
            )
                ? payload.items
                    .map(normalize)
                    .filter(
                        item =>
                            item.active !==
                            false
                    )
                : [];


        localStorage.setItem(
            KEY,
            JSON.stringify(
                items
            )
        );


        window.dispatchEvent(
            new Event(
                "maranatha-program-updated"
            )
        );


        console.log(
            "[MARANATHA Programme] MongoDB -> fidele :",
            items.length
        );


    }catch(error){

        console.warn(
            "[MARANATHA Programme utilisateur]",
            error
        );
    }
}


if(
    document.readyState ===
    "loading"
){

    document.addEventListener(
        "DOMContentLoaded",
        refreshProgramme,
        {
            once:true
        }
    );

}else{

    refreshProgramme();
}


document.addEventListener(
    "click",

    function(event){

        const link =
            event.target.closest(
                'a[href="#programme"],' +
                '[href="#programme"]'
            );


        if(!link){
            return;
        }


        setTimeout(
            refreshProgramme,
            0
        );
    },

    true
);


window.addEventListener(
    "focus",
    function(){

        refreshProgramme();

    }
);


/* MARANATHA_PROGRAMME_USER_MONGODB_V1_END */

})();