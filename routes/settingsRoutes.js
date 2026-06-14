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

module.exports = router;
