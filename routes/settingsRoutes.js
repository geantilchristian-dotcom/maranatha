const express = require('express');
const router = express.Router();
const Settings = require('../models/Settings');

const adminOnly = require('../utils/adminAuth');
const multer = require('multer');
const { uploadImage } = require('../utils/cloudinary');


// GET /api/settings — public summary (compatibility for older interfaces)
router.get('/', async (_req, res) => {
  try {
    const [home, don, programme] = await Promise.all([
      Settings.findOne({ key: 'home' }).lean(),
      Settings.findOne({ key: 'don' }).lean(),
      Settings.findOne({ key: 'programme' }).lean(),
    ]);

    res.json({
      home: home || {},
      don: don || {},
      programme: programme?.programme || [],
      facebookUrl: home?.facebookUrl || '',
      youtubeChannelUrl: home?.youtubeChannelUrl || '',
      tiktokUrl: home?.tiktokUrl || '',
      youtubeLinks: home?.youtubeLinks || [],
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/settings/splash — public
router.get('/splash', async (req, res) => {
  try {
    let s = await Settings.findOne({ key: 'splash' });
    if (!s) s = await Settings.create({ key: 'splash' });
    res.json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/settings/splash — admin only
router.put('/splash', adminOnly, async (req, res) => {
  try {
    const allowed = ['nomEglise', 'verset', 'sousTitre', 'logoUrl', 'couleurFond', 'couleurAccent', 'dureeSplash'];
    const update = {};
    for (const k of allowed) {
      if (req.body[k] !== undefined) update[k] = req.body[k];
    }
    const s = await Settings.findOneAndUpdate(
      { key: 'splash' },
      { $set: update },
      { new: true, upsert: true }
    );
    res.json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/settings/home — public
router.get('/home', async (req, res) => {
  try {
    let s = await Settings.findOne({ key: 'home' });
    if (!s) s = await Settings.create({ key: 'home' });
    res.json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/settings/home — admin only
// Accepte youtubeLinks (tableau [{url, label}]) + rétrocompatibilité youtubeUrl/ytLabel
router.put('/home', adminOnly, async (req, res) => {
  try {
    const update = {};

    // Nouveau format : tableau de liens
    if (Array.isArray(req.body.youtubeLinks)) {
      update.youtubeLinks = req.body.youtubeLinks
        .filter(l => l && l.url && l.url.trim())
        .map(l => ({ url: l.url.trim(), label: (l.label || '').trim() || 'Regarder sur YouTube' }));
    }

    // Rétrocompatibilité : ancien format champ unique
    if (req.body.youtubeUrl !== undefined) update.youtubeUrl = req.body.youtubeUrl;
    if (req.body.ytLabel   !== undefined) update.ytLabel    = req.body.ytLabel;
    if (req.body.facebookUrl       !== undefined) update.facebookUrl       = req.body.facebookUrl;
    if (req.body.youtubeChannelUrl !== undefined) update.youtubeChannelUrl = req.body.youtubeChannelUrl;
    if (req.body.tiktokUrl         !== undefined) update.tiktokUrl         = req.body.tiktokUrl;
    if (req.body.instagramUrl       !== undefined) update.instagramUrl       = req.body.instagramUrl;
    if (Array.isArray(req.body.heroBanners)) {
      update.heroBanners =
        req.body.heroBanners
        .filter(item =>
          item &&
          item.imageUrl
        )
        .map(item => ({
          id:
            String(item.id || "").trim(),
          imageUrl:
            String(item.imageUrl || "").trim(),
          title:
            String(item.title || "").trim(),
          link:
            String(item.link || "#").trim() || "#",
          active:
            item.active !== false,
          text:
            String(item.text || "").trim(),
          reference:
            String(item.reference || "").trim(),
          buttonLabel:
            String(item.buttonLabel || "").trim()
        }));
    }
    const s = await Settings.findOneAndUpdate(
      { key: 'home' },
      { $set: update },
      { new: true, upsert: true }
    );
    res.json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/settings/don — public
router.get('/don', async (req, res) => {
  try {
    let s = await Settings.findOne({ key: 'don' });
    if (!s) s = await Settings.create({ key: 'don' });
    res.json(s);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/settings/don — admin only
router.put('/don', adminOnly, async (req, res) => {
  try {
    const allowed = ['airtel','orange','vodacom','nomTitulaire','nomBanque','numeroCompte','iban','bic','instructions','telephone1','telephone2'];
    const update = {};
    for (const k of allowed) { if (req.body[k] !== undefined) update[k] = req.body[k]; }
    const s = await Settings.findOneAndUpdate({ key: 'don' }, { $set: update }, { new: true, upsert: true });
    res.json(s);
  } catch (e) { res.status(500).json({ error: e.message }); }
});



/* ==========================================================
   MARANATHA_PROGRAMME_IMAGE_ROUTE_V1
   Upload image Programme - admin seulement
   ========================================================== */

const programmeImageUpload =
  multer({
    storage:
      multer.memoryStorage(),

    limits: {
      fileSize:
        10 * 1024 * 1024
    },

    fileFilter:
      (_req, file, callback) => {

        const valid =
          Boolean(
            file &&
            file.mimetype &&
            file.mimetype.startsWith(
              "image/"
            )
          );


        callback(
          valid
            ? null
            : new Error(
                "Le fichier doit etre une image."
              ),

          valid
        );
      }
  });


router.post(
  "/programme/upload",

  adminOnly,

  (req, res, next) => {

    programmeImageUpload.single(
      "image"
    )(
      req,
      res,

      error => {

        if (error) {

          return res
            .status(400)
            .json({
              ok: false,
              error:
                error.message ||
                "Image invalide."
            });
        }

        next();
      }
    );
  },

  async (req, res) => {

    try {

      if (!req.file) {

        return res
          .status(400)
          .json({
            ok: false,
            error:
              "Aucune image recue."
          });
      }


      const url =
        await uploadImage(
          req.file.buffer,
          req.file.originalname
        );


      return res.json({
        ok: true,
        url
      });


    } catch (error) {

      console.error(
        "[PROGRAMME IMAGE]",
        error
      );


      return res
        .status(500)
        .json({
          ok: false,
          error:
            error.message ||
            "Upload impossible."
        });
    }
  }
);

/* MARANATHA_PROGRAMME_IMAGE_ROUTE_V1_END */


// GET /api/settings/programme — public
router.get('/programme', async (req, res) => {
  try {
    let s = await Settings.findOne({ key: 'programme' });
    res.json({ items: (s && s.programme) ? s.programme : [] });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/settings/programme — admin only
router.put('/programme', adminOnly, async (req, res) => {
  try {
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    const s = await Settings.findOneAndUpdate(
      { key: 'programme' },
      { $set: { programme: items } },
      { new: true, upsert: true }
    );
    res.json({ items: s.programme || [] });
  } catch (e) { res.status(500).json({ error: e.message }); }
});


/* ==========================================================
   MARANATHA_APP_CONFIG_PRODUCTION_V1
   Configuration générale utilisée par :
   - Admin Paramètres V2
   - Interface fidèle
   ========================================================== */

const APP_CONFIG_DEFAULT = {
  identity: {
    churchName: "CEMM MARANATHA",
    ministryName:
      "Communauté des Églises Missionnaires Maranatha",
    appName: "MARANATHA",
    version: "1.2.4",
    description:
      "Application officielle de la communauté CEMM MARANATHA."
  },

  contact: {
    phone: "",
    whatsapp: "",
    email: "",
    address: ""
  },

  links: {
    website: "",
    facebook: "",
    youtube: "",
    tiktok: ""
  },

  application: {
    apkUrl: "/downloads/MARANATHA.apk",
    supportEmail: "",
    supportWhatsapp: ""
  },

  documents: {
    about: "",
    privacy: "",
    terms: "",
    help: ""
  },

  updatedAt: ""
};


function cleanAppConfig(input) {

  const source =
    input &&
    typeof input === "object"
      ? input
      : {};


  const output =
    JSON.parse(
      JSON.stringify(
        APP_CONFIG_DEFAULT
      )
    );


  const groups = {
    identity: [
      "churchName",
      "ministryName",
      "appName",
      "version",
      "description"
    ],

    contact: [
      "phone",
      "whatsapp",
      "email",
      "address"
    ],

    links: [
      "website",
      "facebook",
      "youtube",
      "tiktok"
    ],

    application: [
      "apkUrl",
      "supportEmail",
      "supportWhatsapp"
    ],

    documents: [
      "about",
      "privacy",
      "terms",
      "help"
    ]
  };


  Object.entries(groups).forEach(
    ([group, fields]) => {

      const incoming =
        source[group] &&
        typeof source[group] === "object"
          ? source[group]
          : {};


      fields.forEach(
        (field) => {

          if(
            Object.prototype.hasOwnProperty.call(
              incoming,
              field
            )
          ){

            output[group][field] =
              String(
                incoming[field] == null
                  ? ""
                  : incoming[field]
              ).trim();
          }
        }
      );
    }
  );


  return output;
}


/*
 * GET public
 * L'utilisateur doit pouvoir lire :
 * À propos, confidentialité, conditions, support, etc.
 */
router.get(
  "/app-config",
  async (_req, res) => {

    try {

      const document =
        await Settings.collection.findOne({
          key: "app-config"
        });


      const config =
        cleanAppConfig(
          document &&
          document.config
            ? document.config
            : {}
        );


      config.updatedAt =
        document &&
        document.updatedAt
          ? new Date(
              document.updatedAt
            ).toISOString()
          : "";


      return res.json(
        config
      );


    } catch (error) {

      console.error(
        "[SETTINGS APP-CONFIG GET]",
        error
      );


      return res.status(500).json({
        error:
          "Impossible de charger les paramètres."
      });
    }
  }
);


/*
 * PUT admin seulement
 */
router.put(
  "/app-config",
  adminOnly,
  async (req, res) => {

    try {

      const config =
        cleanAppConfig(
          req.body || {}
        );


      const updatedAt =
        new Date();


      await Settings.collection.updateOne(
        {
          key: "app-config"
        },
        {
          $set: {
            key: "app-config",
            config,
            updatedAt
          }
        },
        {
          upsert: true
        }
      );


      return res.json({
        success: true,

        settings: {
          ...config,

          updatedAt:
            updatedAt.toISOString()
        }
      });


    } catch (error) {

      console.error(
        "[SETTINGS APP-CONFIG PUT]",
        error
      );


      return res.status(500).json({
        success: false,
        error:
          "Impossible d'enregistrer les paramètres."
      });
    }
  }
);


/* MARANATHA_APP_CONFIG_PRODUCTION_V1_END */

module.exports = router;
