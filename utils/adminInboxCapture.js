const AdminNotification =
  require("../models/AdminNotification");
function value(body, names) {
  for (const name of names) {
    if (
      body &&
      body[name] !== undefined &&
      body[name] !== null
    ) {
      return body[name];
    }
  }
  return "";
}
module.exports =
  function adminInboxCapture(
    req,
    res,
    next
  ) {
    if (req.method !== "POST") {
      return next();
    }
    const pathname =
      String(req.path || req.url || "")
        .split("?")[0]
        .toLowerCase();
    /*
     * La route centrale cree deja elle-meme
     * sa notification.
     */
    if (
      pathname.includes(
        "/api/admin-inbox"
      )
    ) {
      return next();
    }
    let type = "";
    if (
      /\/api\/comments?\/?$/.test(
        pathname
      ) ||
      /\/api\/commentaires?\/?$/.test(
        pathname
      )
    ) {
      type =
        String(
          req.body?.type ||
          "commentaire"
        ).toLowerCase();
    }
    else if (
      /\/api\/membres?\/?$/.test(
        pathname
      )
    ) {
      type =
        "membre";
    }
    else if (
      /\/api\/prieres?\/?$/.test(
        pathname
      )
    ) {
      type =
        "priere";
    }
    if (!type) {
      return next();
    }
    const body =
      req.body || {};
    res.on(
      "finish",
      async () => {
        /*
         * Enregistrer seulement si
         * l'ancien endpoint a reussi.
         */
        if (
          res.statusCode < 200 ||
          res.statusCode >= 400
        ) {
          return;
        }
        try {
          const titles = {
            temoignage:
              "Nouveau temoignage",
            commentaire:
              "Nouveau commentaire",
            membre:
              "Nouvelle demande de membre",
            priere:
              "Nouvelle demande de priere",
          };
          await AdminNotification.create({
            type,
            title:
              titles[type] ||
              "Nouvelle demande",
            nom:
              String(
                value(
                  body,
                  [
                    "nom",
                    "name",
                    "auteur",
                    "nomComplet",
                  ]
                )
              ).slice(0, 150),
            adresse:
              String(
                value(
                  body,
                  [
                    "adresse",
                    "address",
                  ]
                )
              ).slice(0, 300),
            telephone:
              String(
                value(
                  body,
                  [
                    "telephone",
                    "phone",
                  ]
                )
              ).slice(0, 100),
            email:
              String(
                value(
                  body,
                  [
                    "email",
                  ]
                )
              ).slice(0, 200),
            message:
              String(
                value(
                  body,
                  [
                    "message",
                    "contenu",
                    "texte",
                    "priere",
                  ]
                )
              ).slice(0, 8000),
          });
        } catch (error) {
          console.error(
            "[ADMIN INBOX CAPTURE]",
            error.message
          );
        }
      }
    );
    next();
  };
