const express = require('express');
const mongoose = require('mongoose');
const Livre = require('../models/Livre');
const adminOnly = require('../utils/adminAuth');
const { cleanText, cleanHttpUrl } = require('../utils/security');

const router = express.Router();

function payloadFrom(body = {}) {
  const payload = {};
  if (body.titre !== undefined) payload.titre = cleanText(body.titre, 180);
  if (body.auteur !== undefined) payload.auteur = cleanText(body.auteur, 160);
  if (body.description !== undefined) payload.description = cleanText(body.description, 4000);
  if (body.categorie !== undefined) payload.categorie = cleanText(body.categorie, 100) || 'Général';
  if (body.couvertureUrl !== undefined) payload.couvertureUrl = cleanHttpUrl(body.couvertureUrl);
  if (body.fichierUrl !== undefined) payload.fichierUrl = cleanHttpUrl(body.fichierUrl);
  if (body.lienExterne !== undefined) payload.lienExterne = cleanHttpUrl(body.lienExterne);
  if (typeof body.telechargeable === 'boolean') payload.telechargeable = body.telechargeable;
  if (Number.isFinite(Number(body.ordre))) payload.ordre = Number(body.ordre);
  return payload;
}

router.get('/', async (_req, res) => {
  try {
    const list = await Livre.find().sort({ categorie: 1, ordre: 1, createdAt: -1 }).lean();
    return res.json(list);
  } catch (error) {
    return res.status(500).json({ error: 'Livres temporairement indisponibles' });
  }
});

router.get('/categories', async (_req, res) => {
  try {
    const cats = await Livre.distinct('categorie');
    return res.json(cats.sort());
  } catch (error) {
    return res.status(500).json({ error: 'Catégories indisponibles' });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const payload = payloadFrom(req.body);
    if (!payload.titre) return res.status(400).json({ error: 'Titre obligatoire' });
    const doc = await Livre.create(payload);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(400).json({ error: 'Publication impossible' });
  }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const doc = await Livre.findByIdAndUpdate(
      req.params.id,
      { $set: payloadFrom(req.body) },
      { new: true, runValidators: true },
    );
    if (!doc) return res.status(404).json({ error: 'Livre introuvable' });
    return res.json(doc);
  } catch (error) {
    return res.status(400).json({ error: 'Modification impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const doc = await Livre.findByIdAndDelete(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Livre introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
