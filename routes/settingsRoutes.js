const express = require('express');
const router = express.Router();
const Settings = require('../models/Settings');

function adminOnly(req, res, next) {
  if (req.headers['x-admin-password'] !== process.env.ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Non autorisé' });
  }
  next();
}

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

module.exports = router;
