const express = require("express");
const router = express.Router();
const https = require("https");

/*
 * Cache séparé par traduction :
 * FR:43:3
 * SUV:43:3
 */
const cache = new Map();


function httpsGet(url, redirectCount = 0) {

    if (redirectCount > 5) {
        return Promise.reject(
            new Error("Trop de redirections")
        );
    }


    return new Promise((resolve, reject) => {

        const parsed =
            new URL(url);


        const req =
            https.get(
                {
                    hostname:
                        parsed.hostname,

                    path:
                        parsed.pathname +
                        parsed.search,

                    headers:{
                        "User-Agent":
                            "MaranathaApp/1.0",

                        Accept:
                            "application/json"
                    }
                },

                res => {

                    if (
                        res.statusCode === 301 ||
                        res.statusCode === 302 ||
                        res.statusCode === 307 ||
                        res.statusCode === 308
                    ) {

                        const loc =
                            res.headers.location;


                        if (!loc) {

                            return reject(
                                new Error(
                                    "Redirect sans Location"
                                )
                            );
                        }


                        const next =
                            loc.startsWith("http")
                                ? loc
                                : `https://${parsed.hostname}${loc}`;


                        return httpsGet(
                            next,
                            redirectCount + 1
                        )
                        .then(resolve)
                        .catch(reject);
                    }


                    if (res.statusCode !== 200) {

                        return reject(
                            new Error(
                                "HTTP " +
                                res.statusCode
                            )
                        );
                    }


                    let raw = "";

                    res.setEncoding("utf8");

                    res.on(
                        "data",
                        chunk => raw += chunk
                    );

                    res.on(
                        "end",
                        () => resolve(raw)
                    );
                }
            );


        req.on(
            "error",
            reject
        );


        req.setTimeout(
            9000,
            () => {

                req.destroy();

                reject(
                    new Error("timeout")
                );
            }
        );
    });
}


async function fetchBolls(
    translation,
    bookNum,
    chapter
) {

    const raw =
        await httpsGet(
            `https://bolls.life/get-text/${translation}/${bookNum}/${chapter}/`
        );


    const parsed =
        JSON.parse(raw);


    if (
        !Array.isArray(parsed) ||
        !parsed.length
    ) {

        throw new Error(
            `${translation}: pas de versets`
        );
    }


    return parsed.map(
        v => ({
            verse:
                Number(v.verse),

            text:
                String(
                    v.text || ""
                ).trim()
        })
    );
}


/*
 * GET
 *
 * Français par défaut :
 * /api/bible/43/3
 *
 * Swahili :
 * /api/bible/43/3?version=SUV
 */
router.get(
    "/:bookNum/:chapter",
    async (req,res) => {

        const bookNum =
            parseInt(
                req.params.bookNum,
                10
            );


        const chapter =
            parseInt(
                req.params.chapter,
                10
            );


        if (
            !bookNum ||
            !chapter ||
            bookNum < 1 ||
            bookNum > 66 ||
            chapter < 1
        ) {

            return res
                .status(400)
                .json({
                    error:
                        "Paramètres invalides"
                });
        }


        const requested =
            String(
                req.query.version ||
                "FR"
            )
            .trim()
            .toUpperCase();


        let sources;
        let cacheLanguage;


        if (requested === "SUV") {

            sources = [
                "SUV"
            ];

            cacheLanguage =
                "SUV";

        } else if (
            requested === "BDS"
        ) {

            sources = [
                "BDS"
            ];

            cacheLanguage =
                "BDS";

        } else if (
            requested === "NBS"
        ) {

            sources = [
                "NBS",
                "BDS"
            ];

            cacheLanguage =
                "FR";

        } else {

            /*
             * Français par défaut.
             */
            sources = [
                "NBS",
                "BDS"
            ];

            cacheLanguage =
                "FR";
        }


        const key =
            `${cacheLanguage}:${bookNum}:${chapter}`;


        if (cache.has(key)) {

            const cached =
                cache.get(key);


            return res.json({
                verses:
                    cached.verses,

                version:
                    cached.version,

                cached:
                    true
            });
        }


        const errors = [];


        for (const version of sources) {

            try {

                const verses =
                    await fetchBolls(
                        version,
                        bookNum,
                        chapter
                    );


                cache.set(
                    key,
                    {
                        verses,
                        version
                    }
                );


                return res.json({
                    verses,
                    version
                });


            } catch (error) {

                errors.push(
                    `${version}: ${error.message}`
                );
            }
        }


        console.error(
            `[bible] Echec book=${bookNum} ch=${chapter}:`,
            errors
        );


        res
            .status(502)
            .json({
                error:
                    "Bible temporairement indisponible",

                details:
                    errors
            });
    }
);


module.exports = router;