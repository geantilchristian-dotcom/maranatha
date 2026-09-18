const express = require('express');
const mongoose = require('mongoose');
const Priere = require('../models/Priere');
const adminOnly = require('../utils/adminAuth');
const { cleanText } = require('../utils/security');
const { notifierPublicationNouvelle } = require('../utils/publicationNotifications');

const router = express.Router();

function payloadFrom(body = {}) {
  const payload = {};
  if (body.titre !== undefined) payload.titre = cleanText(body.titre, 180);
  if (body.texte !== undefined) payload.texte = cleanText(body.texte, 5000);
  if (Number.isFinite(Number(body.ordre))) payload.ordre = Number(body.ordre);
  if (typeof body.actif === 'boolean') payload.actif = body.actif;
  return payload;
}

router.get('/', async (_req, res) => {
  try {
    const list = await Priere.find({ actif: true }).sort({ ordre: 1, createdAt: 1 }).lean();
    return res.json(list);
  } catch (error) {
    return res.status(500).json({ error: 'Prières temporairement indisponibles' });
  }
});

router.get('/all', adminOnly, async (_req, res) => {
  try {
    const list = await Priere.find().sort({ ordre: 1, createdAt: 1 }).lean();
    return res.json(list);
  } catch (error) {
    return res.status(500).json({ error: 'Chargement impossible' });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const payload = payloadFrom(req.body);
    if (!payload.titre || !payload.texte) {
      return res.status(400).json({ error: 'Titre et texte obligatoires' });
    }
    const doc = await Priere.create(payload);
    const notification = doc.actif
      ? await notifierPublicationNouvelle('priere', doc)
      : null;
    return res.status(201).json({
      ...doc.toObject(),
      notification,
    });
  } catch (error) {
    return res.status(400).json({ error: 'Publication impossible' });
  }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const previous = await Priere.findById(req.params.id).select({ actif: 1 }).lean();
    const payload = payloadFrom(req.body);
    const doc = await Priere.findByIdAndUpdate(
      req.params.id,
      { $set: payload },
      { new: true, runValidators: true },
    );
    if (!doc) return res.status(404).json({ error: 'Prière introuvable' });
    let notification = null;
    if (previous && !previous.actif && payload.actif === true) {
      notification = await notifierPublicationNouvelle('priere', doc);
    }
    return res.json({
      ...doc.toObject(),
      notification,
    });
  } catch (error) {
    return res.status(400).json({ error: 'Modification impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const doc = await Priere.findByIdAndDelete(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Prière introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
