const express = require('express');
const mongoose = require('mongoose');
const Etude = require('../models/Etude');
const adminOnly = require('../utils/adminAuth');
const { cleanText, cleanHttpUrl } = require('../utils/security');

const router = express.Router();

function payloadFrom(body) {
  const payload = {};
  if (body.titre !== undefined) payload.titre = cleanText(body.titre, 180);
  if (body.texte !== undefined) payload.texte = cleanText(body.texte, 12000);
  if (body.couvertureUrl !== undefined) payload.couvertureUrl = cleanHttpUrl(body.couvertureUrl);
  if (body.pdfUrl !== undefined) payload.pdfUrl = cleanHttpUrl(body.pdfUrl);
  if (body.pdfNom !== undefined) payload.pdfNom = cleanText(body.pdfNom, 220);
  if (body.datePublication !== undefined) {
    const date = new Date(body.datePublication);
    if (!Number.isNaN(date.getTime())) payload.datePublication = date;
  }
  if (typeof body.actif === 'boolean') payload.actif = body.actif;
  return payload;
}

router.get('/', async (_req, res) => {
  try {
    const list = await Etude.find({ actif: true }).sort({ datePublication: -1 }).lean();
    return res.json(list);
  } catch (error) {
    return res.status(500).json({ error: 'Études temporairement indisponibles' });
  }
});

router.get('/today', async (_req, res) => {
  try {
    const etude = await Etude.findOne({ actif: true }).sort({ datePublication: -1 }).lean();
    return res.json(etude || null);
  } catch (error) {
    return res.status(500).json({ error: 'Étude temporairement indisponible' });
  }
});

router.get('/all', adminOnly, async (_req, res) => {
  try {
    const list = await Etude.find().sort({ datePublication: -1 }).lean();
    return res.json(list);
  } catch (error) {
    return res.status(500).json({ error: 'Chargement impossible' });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const payload = payloadFrom(req.body || {});
    if (!payload.titre) return res.status(400).json({ error: 'Titre obligatoire' });
    const doc = await Etude.create(payload);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(400).json({ error: 'Publication impossible' });
  }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }
    const payload = payloadFrom(req.body || {});
    const doc = await Etude.findByIdAndUpdate(
      req.params.id,
      { $set: payload },
      { new: true, runValidators: true },
    );
    if (!doc) return res.status(404).json({ error: 'Étude introuvable' });
    return res.json(doc);
  } catch (error) {
    return res.status(400).json({ error: 'Modification impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }
    const doc = await Etude.findByIdAndDelete(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Étude introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
