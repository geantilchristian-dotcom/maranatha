const express = require('express');
const router  = express.Router();
const Comment = require('../models/Comment');

function adminOnly(req, res, next) {
  if (req.headers['x-admin-password'] !== process.env.ADMIN_PASSWORD)
    return res.status(401).json({ error: 'Non autorisé' });
  next();
}

// GET  /api/comments  — public (50 derniers)
router.get('/', async (req, res) => {
  try {
    const comments = await Comment.find().sort({ dateEnvoi: -1 }).limit(50);
    res.json(comments);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/comments  — public
router.post('/', async (req, res) => {
  try {
    const { texte } = req.body;
    if (!texte || !texte.trim()) return res.status(400).json({ error: 'Texte requis' });
    const c = await Comment.create({ texte: texte.trim() });
    res.status(201).json(c);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/comments/:id/reply  — admin seulement
router.patch('/:id/reply', adminOnly, async (req, res) => {
  try {
    const { reponse } = req.body;
    const c = await Comment.findByIdAndUpdate(
      req.params.id,
      { adminReponse: (reponse || '').trim(), dateReponse: new Date() },
      { new: true }
    );
    if (!c) return res.status(404).json({ error: 'Commentaire introuvable' });
    res.json(c);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/comments/:id  — admin seulement
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    await Comment.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
