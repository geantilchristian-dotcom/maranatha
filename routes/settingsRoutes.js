const express = require('express');
const multer = require('multer');
const Settings = require('../models/Settings');
const adminOnly = require('../utils/adminAuth');
const { uploadImage } = require('../utils/cloudinary');
const { cleanText, cleanHttpUrl } = require('../utils/security');

const router = express.Router();

const bannerUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    const mime = String(file?.mimetype || '').toLowerCase();
    const ext = String(file?.originalname || '').toLowerCase().match(/\.[a-z0-9]+$/)?.[0] || '';
    const ok =
      mime.startsWith('image/') &&
      ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext);
    callback(ok ? null : new Error('Format invalide. Choisissez une image JPG, PNG ou WEBP.'), ok);
  },
});

function cleanRelativeOrHttp(value, maxLength = 1600) {
  const raw = cleanText(value, maxLength);
  if (!raw) return '';
  if (/^\/(?!\/)/.test(raw)) return raw;
  return cleanHttpUrl(raw, maxLength);
}

function cleanImageUrl(value) {
  const raw = cleanText(value, 900000);
  if (!raw) return '';
  const http = cleanHttpUrl(raw, 1600);
  if (http) return http;

  // Compatibilité avec les anciennes affiches déjà enregistrées en data URL.
  if (/^data:image\/(?:jpeg|jpg|png|webp);base64,[A-Za-z0-9+/=\r\n]+$/i.test(raw)) {
    return raw.slice(0, 900000);
  }
  return '';
}

function publicSettings(doc) {
  if (!doc) return {};
  const plain = doc.toObject ? doc.toObject() : doc;
  delete plain.__v;
  return plain;
}

router.get('/', async (_req, res) => {
  try {
    const [home, don, programme] = await Promise.all([
      Settings.findOne({ key: 'home' }).lean(),
      Settings.findOne({ key: 'don' }).lean(),
      Settings.findOne({ key: 'programme' }).lean(),
    ]);

    return res.json({
      home: home || {},
      don: don || {},
      programme: programme?.programme || [],
      facebookUrl: home?.facebookUrl || '',
      youtubeChannelUrl: home?.youtubeChannelUrl || '',
      tiktokUrl: home?.tiktokUrl || '',
      youtubeLinks: home?.youtubeLinks || [],
    });
  } catch (error) {
    return res.status(500).json({ error: 'Paramètres temporairement indisponibles' });
  }
});

router.get('/splash', async (_req, res) => {
  try {
    let settings = await Settings.findOne({ key: 'splash' });
    if (!settings) settings = await Settings.create({ key: 'splash' });
    return res.json(publicSettings(settings));
  } catch (error) {
    return res.status(500).json({ error: 'Paramètres temporairement indisponibles' });
  }
});

router.put('/splash', adminOnly, async (req, res) => {
  try {
    const update = {};
    if (req.body.nomEglise !== undefined) update.nomEglise = cleanText(req.body.nomEglise, 160);
    if (req.body.verset !== undefined) update.verset = cleanText(req.body.verset, 1000);
    if (req.body.sousTitre !== undefined) update.sousTitre = cleanText(req.body.sousTitre, 250);
    if (req.body.logoUrl !== undefined) update.logoUrl = cleanRelativeOrHttp(req.body.logoUrl);
    if (/^#[0-9a-f]{6}$/i.test(String(req.body.couleurFond || ''))) {
      update.couleurFond = String(req.body.couleurFond);
    }
    if (/^#[0-9a-f]{6}$/i.test(String(req.body.couleurAccent || ''))) {
      update.couleurAccent = String(req.body.couleurAccent);
    }
    if (req.body.dureeSplash !== undefined) {
      const seconds = Number(req.body.dureeSplash);
      if (Number.isFinite(seconds)) update.dureeSplash = Math.min(12, Math.max(1, seconds));
    }

    const settings = await Settings.findOneAndUpdate(
      { key: 'splash' },
      { $set: update },
      { new: true, upsert: true, runValidators: true },
    );
    return res.json(publicSettings(settings));
  } catch (error) {
    return res.status(400).json({ error: 'Enregistrement impossible' });
  }
});

router.post(
  '/home/banner-upload',
  adminOnly,
  bannerUpload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ error: 'Choisissez une image' });
      const image = await uploadImage(req.file.buffer, req.file.originalname);
      return res.status(201).json({
        success: true,
        url: image.url,
        width: image.width,
        height: image.height,
      });
    } catch (error) {
      console.error('[BANNIERE UPLOAD]', error.message || error);
      return res.status(500).json({
        error: 'Impossible de téléverser cette image',
      });
    }
  },
);

router.get('/home', async (_req, res) => {
  try {
    let settings = await Settings.findOne({ key: 'home' });
    if (!settings) settings = await Settings.create({ key: 'home' });
    return res.json(publicSettings(settings));
  } catch (error) {
    return res.status(500).json({ error: 'Paramètres temporairement indisponibles' });
  }
});

router.put('/home', adminOnly, async (req, res) => {
  try {
    const update = {};

    if (Array.isArray(req.body.youtubeLinks)) {
      update.youtubeLinks = req.body.youtubeLinks
        .slice(0, 20)
        .map((item) => ({
          url: cleanHttpUrl(item?.url),
          label: cleanText(item?.label, 120) || 'Regarder sur YouTube',
        }))
        .filter((item) => item.url);
    }

    if (Array.isArray(req.body.heroBanners)) {
      update.heroBanners = req.body.heroBanners
        .slice(0, 20)
        .map((item, index) => ({
          id: cleanText(item?.id || `banner-${Date.now()}-${index}`, 100),
          imageUrl: cleanHttpUrl(item?.imageUrl),
          title: cleanText(item?.title, 180),
          text: cleanText(item?.text, 1500),
          reference: cleanText(item?.reference, 180),
          buttonLabel: cleanText(item?.buttonLabel, 100),
        }))
        .filter((item) => item.imageUrl);
    }

    if (req.body.youtubeUrl !== undefined) update.youtubeUrl = cleanHttpUrl(req.body.youtubeUrl);
    if (req.body.ytLabel !== undefined) update.ytLabel = cleanText(req.body.ytLabel, 120);
    if (req.body.facebookUrl !== undefined) update.facebookUrl = cleanHttpUrl(req.body.facebookUrl);
    if (req.body.youtubeChannelUrl !== undefined) update.youtubeChannelUrl = cleanHttpUrl(req.body.youtubeChannelUrl);
    if (req.body.tiktokUrl !== undefined) update.tiktokUrl = cleanHttpUrl(req.body.tiktokUrl);

    const settings = await Settings.findOneAndUpdate(
      { key: 'home' },
      { $set: update },
      { new: true, upsert: true, runValidators: true },
    );
    return res.json(publicSettings(settings));
  } catch (error) {
    return res.status(400).json({ error: 'Enregistrement impossible' });
  }
});

router.get('/don', async (_req, res) => {
  try {
    let settings = await Settings.findOne({ key: 'don' });
    if (!settings) settings = await Settings.create({ key: 'don' });
    return res.json(publicSettings(settings));
  } catch (error) {
    return res.status(500).json({ error: 'Paramètres temporairement indisponibles' });
  }
});

router.put('/don', adminOnly, async (req, res) => {
  try {
    const fields = [
      'airtel', 'orange', 'vodacom', 'nomTitulaire', 'nomBanque',
      'numeroCompte', 'iban', 'bic', 'instructions', 'telephone1', 'telephone2',
    ];
    const update = {};
    for (const key of fields) {
      if (req.body[key] !== undefined) {
        update[key] = cleanText(req.body[key], key === 'instructions' ? 2000 : 300);
      }
    }

    const settings = await Settings.findOneAndUpdate(
      { key: 'don' },
      { $set: update },
      { new: true, upsert: true, runValidators: true },
    );
    return res.json(publicSettings(settings));
  } catch (error) {
    return res.status(400).json({ error: 'Enregistrement impossible' });
  }
});

router.get('/programme', async (_req, res) => {
  try {
    const settings = await Settings.findOne({ key: 'programme' }).lean();
    return res.json({ items: settings?.programme || [] });
  } catch (error) {
    return res.status(500).json({ error: 'Programme temporairement indisponible' });
  }
});

router.put('/programme', adminOnly, async (req, res) => {
  try {
    const incoming = Array.isArray(req.body.items) ? req.body.items : [];
    const items = incoming.slice(0, 80).map((item, index) => ({
      id: cleanText(item?.id || `programme-${Date.now()}-${index}`, 100),
      titre: cleanText(item?.titre, 180),
      badge: cleanText(item?.badge, 80) || 'PROGRAMME',
      dateStr: cleanText(item?.dateStr, 20),
      heureStr: cleanText(item?.heureStr, 20),
      lieu: cleanText(item?.lieu, 250),
      description: cleanText(item?.description, 4000),
      imageUrl: cleanImageUrl(item?.imageUrl),
    })).filter((item) => item.titre && item.dateStr && item.heureStr && item.lieu && item.description);

    if (incoming.length > 0 && items.length !== incoming.slice(0, 80).length) {
      return res.status(400).json({
        error: 'Chaque programme doit contenir un titre, une date, une heure, un lieu et un texte.',
      });
    }

    const settings = await Settings.findOneAndUpdate(
      { key: 'programme' },
      { $set: { programme: items } },
      { new: true, upsert: true, runValidators: true },
    );
    return res.json({ items: settings.programme || [] });
  } catch (error) {
    return res.status(400).json({ error: 'Enregistrement du programme impossible' });
  }
});

router.use((error, _req, res, _next) => {
  if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'Image trop lourde. Maximum 15 Mo.' });
  }
  return res.status(400).json({ error: 'Fichier invalide' });
});

module.exports = router;
