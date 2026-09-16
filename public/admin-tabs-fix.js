(function(){

    "use strict";


    function clearForcedDisplays(){

        document.querySelectorAll(
            ".tab-pane"
        )
        .forEach(function(pane){

            /*
             * Notre ancien script de connexion avait
             * forcé pane-stats en display:block!important.
             *
             * On rend maintenant la gestion à switchTab().
             */

            pane.style.removeProperty(
                "display"
            );

        });
    }


    /*
     * Après la restauration de session.
     */

    setTimeout(
        clearForcedDisplays,
        500
    );


    /*
     * IMPORTANT :
     * nettoyage AVANT chaque changement d'onglet.
     */

    document.addEventListener(
        "click",
        function(event){

            const tab =
                event.target.closest(
                    ".tab-btn"
                );


            if(!tab){
                return;
            }


            clearForcedDisplays();

        },
        true
    );


    /*
     * Sécurité supplémentaire après le clic.
     */

    document.addEventListener(
        "click",
        function(event){

            if(
                !event.target.closest(
                    ".tab-btn"
                )
            ){
                return;
            }


            requestAnimationFrame(
                clearForcedDisplays
            );

        },
        false
    );

})();