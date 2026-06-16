const express = require('express');
const router  = express.Router();
const Membre  = require('../models/Membre');

function adminOnly(req, res, next) {
  if (req.headers['x-admin-password'] !== process.env.ADMIN_PASSWORD)
    return res.status(401).json({ error: 'Non autorisé' });
  next();
}

// GET /api/membres/phone/:tel — connexion par numéro
router.get('/phone/:tel', async (req, res) => {
  try {
    const m = await Membre.findOne({ telephone: req.params.tel.trim() });
    if (!m) return res.status(404).json({ error: 'Numéro non trouvé' });
    res.json({ _id: m._id, nom: m.nom, postNom: m.postNom, prenom: m.prenom,
               telephone: m.telephone, pays: m.pays, statut: m.statut,
               bio: m.bio || '', email: m.email || '' });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /api/membres — admin : liste complète
router.get('/', adminOnly, async (req, res) => {
  try {
    const membres = await Membre.find().sort({ dateInscription: -1 });
    res.json(membres);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /api/membres/count — public : comptage
router.get('/count', async (req, res) => {
  try {
    const count = await Membre.countDocuments();
    const membres = await Membre.countDocuments({ statut: 'accepte' });
    res.json({ inscrits: count, membres });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/membres — inscription (un seul compte par numéro)
router.post('/', async (req, res) => {
  try {
    const { nom, postNom, prenom, age, sexe, telephone, indicatif, pays, adresse, bio, email } = req.body;
    if (!nom || !telephone)
      return res.status(400).json({ error: 'Nom et téléphone sont requis' });
    const exists = await Membre.findOne({ telephone: telephone.trim() });
    if (exists)
      return res.status(409).json({ error: 'Ce numéro est déjà enregistré. Connectez-vous.' });
    const m = await Membre.create({
      nom:       nom.trim(),
      postNom:   (postNom  || '').trim(),
      prenom:    (prenom   || nom).trim(),
      age:       age ? Number(age) : undefined,
      sexe:      sexe || '',
      telephone: telephone.trim(),
      indicatif: (indicatif || '').trim(),
      pays:      (pays || '').trim(),
      adresse:   (adresse  || '').trim(),
      bio:       (bio || '').trim(),
      email:     (email || '').trim(),
    });
    res.status(201).json(m);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/membres/:id — mise à jour profil par l'utilisateur
router.patch('/:id', async (req, res) => {
  try {
    const allowed = ['nom','postNom','prenom','age','sexe','pays','adresse','bio','email','indicatif'];
    const update = {};
    for (const k of allowed) { if (req.body[k] !== undefined) update[k] = req.body[k]; }
    const m = await Membre.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!m) return res.status(404).json({ error: 'Membre introuvable' });
    res.json(m);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/membres/:id/statut — admin : changer le statut membre
router.patch('/:id/statut', adminOnly, async (req, res) => {
  try {
    const { statut } = req.body;
    const m = await Membre.findByIdAndUpdate(req.params.id, { statut }, { new: true });
    if (!m) return res.status(404).json({ error: 'Membre introuvable' });
    res.json(m);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/membres/:id — admin
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    await Membre.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
