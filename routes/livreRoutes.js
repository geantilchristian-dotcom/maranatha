const express = require('express');
const router  = express.Router();
const Livre   = require('../models/Livre');

const adminOnly = require('../utils/adminAuth');

router.get('/', async (req, res) => {
  try {
    const list = await Livre.find().sort({ categorie: 1, ordre: 1, createdAt: -1 });
    res.json(list);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/categories', async (req, res) => {
  try {
    const cats = await Livre.distinct('categorie');
    res.json(cats.sort());
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const doc = await Livre.create(req.body);
    res.status(201).json(doc);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    const doc = await Livre.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!doc) return res.status(404).json({ error: 'Non trouvé' });
    res.json(doc);
  } catch (e) { res.status(400).json({ error: e.message }); }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    await Livre.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
