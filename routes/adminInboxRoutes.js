const express = require("express");
const AdminNotification =
  require("../models/AdminNotification");
const router = express.Router();
const allowedTypes = new Set([
  "temoignage",
  "commentaire",
  "membre",
  "priere",
  "don_initie",
  "don_confirme",
  "offrande",
  "dime",
  "don_mensuel",
  "don_volontaire",
  "contact",
]);
function clean(value, max = 5000) {
  return String(value || "")
    .trim()
    .slice(0, max);
}
function adminOnly(req, res, next) {
  const expected =
    String(
      process.env.ADMIN_PASSWORD || ""
    );
  const received =
    String(
      req.headers["x-admin-password"] ||
      ""
    );
  if (!expected) {
    return res.status(503).json({
      success: false,
      message:
        "Mot de passe administrateur non configure.",
    });
  }
  if (received !== expected) {
    return res.status(401).json({
      success: false,
      message:
        "Acces administrateur refuse.",
    });
  }
  next();
}
/*
 * ENVOI PUBLIC
 */
router.post(
  "/public",
  async (req, res) => {
    try {
      const type =
        clean(
          req.body?.type,
          50
        ).toLowerCase();
      if (!allowedTypes.has(type)) {
        return res.status(400).json({
          success: false,
          message:
            "Type de demande invalide.",
        });
      }
      const memberId =
        clean(
          req.body?.memberId,
          100
        );
      const nom =
        clean(
          req.body?.nom ||
          req.body?.name ||
          req.body?.auteur,
          150
        );
      const adresse =
        clean(
          req.body?.adresse ||
          req.body?.address,
          300
        );
      const telephone =
        clean(
          req.body?.telephone ||
          req.body?.phone,
          100
        );
      const email =
        clean(
          req.body?.email,
          200
        );
      const message =
        clean(
          req.body?.message ||
          req.body?.contenu ||
          req.body?.texte,
          8000
        );
      const amountRaw =
        req.body?.amount;
      const amount =
        amountRaw === undefined ||
        amountRaw === null ||
        amountRaw === ""
          ? null
          : Number(amountRaw);
      const donationCategory =
        clean(
          req.body?.donationCategory ||
          req.body?.category,
          100
        );
      const reference =
        clean(
          req.body?.reference,
          200
        );
      const titles = {
        temoignage:
          "Nouveau temoignage",
        commentaire:
          "Nouveau commentaire",
        membre:
          "Nouvelle demande de membre",
        priere:
          "Nouvelle demande de priere",
        don_initie:
          "Nouveau don initie",
        don_confirme:
          "Don confirme",
        offrande:
          "Nouvelle offrande",
        dime:
          "Nouvelle dime",
        don_mensuel:
          "Nouveau don mensuel",
        don_volontaire:
          "Nouveau don volontaire",
        contact:
          "Nouveau message",
      };
      const notification =
        await AdminNotification.create({
          memberId,
          type,
          title:
            titles[type] ||
            "Nouvelle notification",
          nom,
          adresse,
          telephone,
          email,
          message,
          amount:
            Number.isFinite(amount)
              ? amount
              : null,
          currency:
            clean(
              req.body?.currency ||
              "CDF",
              10
            ),
          donationCategory,
          reference,
        });
      return res.status(201).json({
        success: true,
        id:
          String(notification._id),
        message:
          "Votre message a ete envoye.",
      });
    } catch (error) {
      console.error(
        "[PUBLIC MESSAGE]",
        error
      );
      return res.status(500).json({
        success: false,
        message:
          "Impossible d'envoyer votre message.",
      });
    }
  }
);
/*
 * HISTORIQUE PERSONNEL
 *
 * Lecture uniquement.
 * Aucun PUT/PATCH/DELETE public.
 */
router.get(
  "/public/history/:memberId",
  async (req, res) => {
    try {
      const memberId =
        clean(
          req.params.memberId,
          100
        );
      const type =
        clean(
          req.query.type,
          50
        ).toLowerCase();
      if (!memberId) {
        return res.status(400).json({
          success: false,
          message:
            "Identifiant fidele manquant.",
        });
      }
      if (
        type !== "temoignage" &&
        type !== "commentaire"
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Historique invalide.",
        });
      }
      const items =
        await AdminNotification
          .find({
            memberId,
            type,
          })
          .sort({
            createdAt: -1,
          })
          .limit(100)
          .select(
            "type nom adresse message createdAt"
          )
          .lean();
      return res.json({
        success: true,
        items,
      });
    } catch (error) {
      console.error(
        "[PUBLIC HISTORY]",
        error
      );
      return res.status(500).json({
        success: false,
        items: [],
      });
    }
  }
);
/*
 * ADMIN
 */
router.get(
  "/",
  adminOnly,
  async (_req, res) => {
    try {
      const notifications =
        await AdminNotification
          .find({})
          .sort({
            createdAt: -1,
          })
          .limit(200)
          .lean();
      const unread =
        await AdminNotification
          .countDocuments({
            read: false,
          });
      return res.json({
        success: true,
        unread,
        notifications,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
      });
    }
  }
);
router.get(
  "/count",
  adminOnly,
  async (_req, res) => {
    const unread =
      await AdminNotification
        .countDocuments({
          read: false,
        });
    return res.json({
      success: true,
      unread,
    });
  }
);
router.patch(
  "/read-all",
  adminOnly,
  async (_req, res) => {
    await AdminNotification
      .updateMany(
        {
          read: false,
        },
        {
          $set: {
            read: true,
          },
        }
      );
    return res.json({
      success: true,
    });
  }
);
router.patch(
  "/:id/read",
  adminOnly,
  async (req, res) => {
    const notification =
      await AdminNotification
        .findByIdAndUpdate(
          req.params.id,
          {
            $set: {
              read: true,
            },
          }
        );
    return res.json({
      success:
        Boolean(notification),
    });
  }
);
module.exports = router;
