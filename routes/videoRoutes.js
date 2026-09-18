const express = require('express');
const mongoose = require('mongoose');
const Video = require('../models/Video');
const adminOnly = require('../utils/adminAuth');
const { cleanText, cleanHttpUrl } = require('../utils/security');
const { notifierPublicationNouvelle } = require('../utils/publicationNotifications');

const router = express.Router();

function payloadFrom(body = {}) {
  const payload = {};
  if (body.titre !== undefined) payload.titre = cleanText(body.titre, 180);
  if (body.auteur !== undefined) payload.auteur = cleanText(body.auteur, 160);
  if (body.description !== undefined) payload.description = cleanText(body.description, 4000);
  if (body.categorie !== undefined) payload.categorie = cleanText(body.categorie, 100) || 'Général';
  if (body.youtubeUrl !== undefined) payload.youtubeUrl = cleanHttpUrl(body.youtubeUrl);
  if (body.fichierUrl !== undefined) payload.fichierUrl = cleanHttpUrl(body.fichierUrl);
  if (body.couvertureUrl !== undefined) payload.couvertureUrl = cleanHttpUrl(body.couvertureUrl);
  if (typeof body.telechargeable === 'boolean') payload.telechargeable = body.telechargeable;
  if (Number.isFinite(Number(body.ordre))) payload.ordre = Number(body.ordre);
  return payload;
}

router.get('/', async (_req, res) => {
  try {
    const list = await Video.find().sort({ categorie: 1, ordre: 1, createdAt: -1 }).lean();
    return res.json(list);
  } catch (error) {
    return res.status(500).json({ error: 'Vidéos temporairement indisponibles' });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const payload = payloadFrom(req.body);
    if (!payload.titre) return res.status(400).json({ error: 'Titre obligatoire' });
    const doc = await Video.create(payload);
    notifierPublicationNouvelle('video', doc);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(400).json({ error: 'Publication impossible' });
  }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const doc = await Video.findByIdAndUpdate(
      req.params.id,
      { $set: payloadFrom(req.body) },
      { new: true, runValidators: true },
    );
    if (!doc) return res.status(404).json({ error: 'Vidéo introuvable' });
    return res.json(doc);
  } catch (error) {
    return res.status(400).json({ error: 'Modification impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const doc = await Video.findByIdAndDelete(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Vidéo introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
