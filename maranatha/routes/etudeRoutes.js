const express = require('express');
const router  = express.Router();
const Etude   = require('../models/Etude');

function adminOnly(req, res, next) {
  if (req.headers['x-admin-password'] !== process.env.ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Non autorisé' });
  }
  next();
}

router.get('/', async (req, res) => {
  try {
    const list = await Etude.find({ actif: true }).sort({ datePublication: -1 });
    res.json(list);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/today', async (req, res) => {
  try {
    const etude = await Etude.findOne({ actif: true }).sort({ datePublication: -1 });
    res.json(etude || null);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/all', adminOnly, async (req, res) => {
  try {
    const list = await Etude.find().sort({ datePublication: -1 });
    res.json(list);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const doc = await Etude.create(req.body);
    res.status(201).json(doc);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    const doc = await Etude.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!doc) return res.status(404).json({ error: 'Non trouvé' });
    res.json(doc);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    await Etude.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
