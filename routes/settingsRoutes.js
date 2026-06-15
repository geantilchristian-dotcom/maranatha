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
router.put('/home', adminOnly, async (req, res) => {
  try {
    const allowed = ['youtubeUrl', 'ytLabel'];
    const update = {};
    for (const k of allowed) {
      if (req.body[k] !== undefined) update[k] = req.body[k];
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
    const allowed = ['telephone1','telephone2','nomTitulaire','nomBanque','numeroCompte','iban','bic','instructions'];
    const update = {};
    for (const k of allowed) { if (req.body[k] !== undefined) update[k] = req.body[k]; }
    const s = await Settings.findOneAndUpdate({ key: 'don' }, { $set: update }, { new: true, upsert: true });
    res.json(s);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
