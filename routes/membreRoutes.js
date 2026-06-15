const express = require('express');
const router  = express.Router();
const Membre  = require('../models/Membre');

function adminOnly(req, res, next) {
  if (req.headers['x-admin-password'] !== process.env.ADMIN_PASSWORD)
    return res.status(401).json({ error: 'Non autorisé' });
  next();
}

// GET /api/membres/phone/:tel — public, connexion par numéro
router.get('/phone/:tel', async (req, res) => {
  try {
    const m = await Membre.findOne({ telephone: req.params.tel.trim() });
    if (!m) return res.status(404).json({ error: 'Numéro non trouvé' });
    res.json({ _id: m._id, nom: m.nom, postNom: m.postNom, prenom: m.prenom, telephone: m.telephone, statut: m.statut });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET  /api/membres  — admin seulement
router.get('/', adminOnly, async (req, res) => {
  try {
    const membres = await Membre.find().sort({ dateInscription: -1 });
    res.json(membres);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/membres  — public
router.post('/', async (req, res) => {
  try {
    const { nom, postNom, prenom, age, sexe, telephone, indicatif, pays, adresse } = req.body;
    if (!nom || !prenom || !telephone)
      return res.status(400).json({ error: 'Nom, prénom et téléphone sont requis' });
    const m = await Membre.create({
      nom:       nom.trim(),
      postNom:   (postNom  || '').trim(),
      prenom:    prenom.trim(),
      age:       age ? Number(age) : undefined,
      sexe:      sexe || '',
      telephone: telephone.trim(),
      indicatif: (indicatif || '').trim(),
      pays:      pays.trim(),
      adresse:   (adresse  || '').trim(),
    });
    res.status(201).json(m);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/membres/:id/statut  — admin seulement
router.patch('/:id/statut', adminOnly, async (req, res) => {
  try {
    const { statut } = req.body;
    const m = await Membre.findByIdAndUpdate(req.params.id, { statut }, { new: true });
    if (!m) return res.status(404).json({ error: 'Membre introuvable' });
    res.json(m);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/membres/:id  — admin seulement
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    await Membre.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
