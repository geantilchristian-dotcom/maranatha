const express = require('express');
const mongoose = require('mongoose');
const Comment = require('../models/Comment');
const adminOnly = require('../utils/adminAuth');
const { cleanText, createRateLimiter } = require('../utils/security');

const router = express.Router();
const commentLimiter = createRateLimiter({ windowMs: 10 * 60 * 1000, max: 35, keyPrefix: 'comments' });

router.get('/', async (req, res) => {
  try {
    const filter = {};
    const section = cleanText(req.query.section, 30);
    if (['communaute', 'parole'].includes(section)) filter.section = section;
    const comments = await Comment.find(filter).sort({ dateEnvoi: -1 }).limit(50).lean();
    return res.json(comments);
  } catch (error) {
    return res.status(500).json({ error: 'Commentaires temporairement indisponibles' });
  }
});

router.post('/', commentLimiter, async (req, res) => {
  try {
    const texte = cleanText(req.body?.texte, 1000);
    if (!texte) return res.status(400).json({ error: 'Texte requis' });
    const c = await Comment.create({
      texte,
      type: ['commentaire', 'suggestion'].includes(req.body?.type) ? req.body.type : 'commentaire',
      section: ['communaute', 'parole'].includes(req.body?.section) ? req.body.section : 'communaute',
      auteur: cleanText(req.body?.auteur, 150),
    });
    return res.status(201).json(c);
  } catch (error) {
    return res.status(400).json({ error: 'Envoi du commentaire impossible' });
  }
});

router.patch('/:id/reply', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const c = await Comment.findByIdAndUpdate(
      req.params.id,
      { $set: { adminReponse: cleanText(req.body?.reponse, 3000), dateReponse: new Date() } },
      { new: true, runValidators: true },
    );
    if (!c) return res.status(404).json({ error: 'Commentaire introuvable' });
    return res.json(c);
  } catch (error) {
    return res.status(400).json({ error: 'Réponse impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Identifiant invalide' });
    const c = await Comment.findByIdAndDelete(req.params.id);
    if (!c) return res.status(404).json({ error: 'Commentaire introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
