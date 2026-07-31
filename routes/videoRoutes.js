const express = require('express');
const router  = express.Router();
const Video   = require('../models/Video');

const adminOnly = require('../utils/adminAuth');

router.get('/', async (req, res) => {
  try {
    const list = await Video.find().sort({ categorie: 1, ordre: 1, createdAt: -1 });
    res.json(list);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const doc = await Video.create(req.body);
    res.status(201).json(doc);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    const doc = await Video.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!doc) return res.status(404).json({ error: 'Non trouvé' });
    res.json(doc);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    await Video.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
