const express = require('express');
const mongoose = require('mongoose');
const Membre = require('../models/Membre');
const adminOnly = require('../utils/adminAuth');
const {
  cleanText,
  cleanEmail,
  cleanPhone,
  createRateLimiter,
} = require('../utils/security');

const router = express.Router();

const publicMemberLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 45,
  keyPrefix: 'members-public',
});

function safeAge(value) {
  if (value === undefined || value === null || value === '') return undefined;
  const age = Number(value);
  if (!Number.isFinite(age) || age < 0 || age > 120) return undefined;
  return Math.round(age);
}

function publicMember(m) {
  return {
    _id: m._id,
    nom: m.nom,
    postNom: m.postNom,
    prenom: m.prenom,
    telephone: m.telephone,
    pays: m.pays,
    adresse: m.adresse || '',
    statut: m.statut,
    bio: m.bio || '',
    email: m.email || '',
  };
}

// GET /api/membres/phone/:tel — connexion par numéro
router.get('/phone/:tel', publicMemberLimiter, async (req, res) => {
  try {
    const telephone = cleanPhone(req.params.tel);
    if (!telephone) return res.status(400).json({ error: 'Numéro invalide' });

    const m = await Membre.findOne({ telephone });
    if (!m) return res.status(404).json({ error: 'Numéro non trouvé' });
    return res.json(publicMember(m));
  } catch (error) {
    console.error('[membres/phone]', error.message);
    return res.status(500).json({ error: 'Connexion membre impossible' });
  }
});

// GET /api/membres/count — public : comptage
router.get('/count', async (_req, res) => {
  try {
    const [inscrits, membres] = await Promise.all([
      Membre.countDocuments(),
      Membre.countDocuments({ statut: 'accepte' }),
    ]);
    return res.json({ inscrits, membres });
  } catch (error) {
    return res.status(500).json({ error: 'Comptage indisponible' });
  }
});

// GET /api/membres — admin : liste complète
router.get('/', adminOnly, async (_req, res) => {
  try {
    const membres = await Membre.find().sort({ dateInscription: -1 }).lean();
    return res.json(membres);
  } catch (error) {
    console.error('[membres/list]', error.message);
    return res.status(500).json({ error: 'Liste des membres indisponible' });
  }
});

// POST /api/membres — inscription (un seul compte par numéro)
router.post('/', publicMemberLimiter, async (req, res) => {
  try {
    const nom = cleanText(req.body?.nom || req.body?.nomComplet || req.body?.name, 120);
    const telephone = cleanPhone(req.body?.telephone || req.body?.phone);
    const postNom = cleanText(req.body?.postNom, 120);
    const prenom = cleanText(req.body?.prenom, 120) || nom;
    const emailRaw = cleanText(req.body?.email, 254);
    const email = emailRaw ? cleanEmail(emailRaw) : '';

    if (!nom || !telephone) {
      return res.status(400).json({ error: 'Nom et téléphone sont requis' });
    }
    if (emailRaw && !email) {
      return res.status(400).json({ error: 'Adresse e-mail invalide' });
    }

    const exists = await Membre.findOne({ telephone }).select('_id').lean();
    if (exists) {
      return res.status(409).json({ error: 'Ce numéro est déjà enregistré. Connectez-vous.' });
    }

    const sexe = ['Homme', 'Femme'].includes(req.body?.sexe) ? req.body.sexe : '';
    const m = await Membre.create({
      nom,
      postNom,
      prenom,
      age: safeAge(req.body?.age),
      sexe,
      telephone,
      indicatif: cleanText(req.body?.indicatif, 12),
      pays: cleanText(req.body?.pays, 100),
      adresse: cleanText(req.body?.adresse || req.body?.address, 300),
      bio: cleanText(req.body?.bio, 3000),
      email,
    });

    return res.status(201).json(publicMember(m));
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(409).json({ error: 'Ce numéro est déjà enregistré. Connectez-vous.' });
    }
    console.error('[membres/create]', error.message);
    return res.status(500).json({ error: 'Inscription membre impossible' });
  }
});

// PATCH /api/membres/:id — mise à jour profil par l'utilisateur
// Le téléphone et le statut ne sont jamais modifiables ici.
router.patch('/:id', publicMemberLimiter, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    const update = {};
    if (req.body.nom !== undefined) update.nom = cleanText(req.body.nom, 120);
    if (req.body.postNom !== undefined) update.postNom = cleanText(req.body.postNom, 120);
    if (req.body.prenom !== undefined) update.prenom = cleanText(req.body.prenom, 120);
    if (req.body.age !== undefined) update.age = safeAge(req.body.age);
    if (req.body.sexe !== undefined) {
      update.sexe = ['Homme', 'Femme'].includes(req.body.sexe) ? req.body.sexe : '';
    }
    if (req.body.pays !== undefined) update.pays = cleanText(req.body.pays, 100);
    if (req.body.adresse !== undefined) update.adresse = cleanText(req.body.adresse, 300);
    if (req.body.bio !== undefined) update.bio = cleanText(req.body.bio, 3000);
    if (req.body.indicatif !== undefined) update.indicatif = cleanText(req.body.indicatif, 12);
    if (req.body.email !== undefined) {
      const raw = cleanText(req.body.email, 254);
      const email = raw ? cleanEmail(raw) : '';
      if (raw && !email) return res.status(400).json({ error: 'Adresse e-mail invalide' });
      update.email = email;
    }

    const m = await Membre.findByIdAndUpdate(
      req.params.id,
      { $set: update },
      { new: true, runValidators: true },
    );
    if (!m) return res.status(404).json({ error: 'Membre introuvable' });
    return res.json(publicMember(m));
  } catch (error) {
    console.error('[membres/update]', error.message);
    return res.status(400).json({ error: 'Mise à jour impossible' });
  }
});

// PATCH /api/membres/:id/statut — admin : changer le statut membre
router.patch('/:id/statut', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }
    const statut = cleanText(req.body?.statut, 20);
    if (!['en_attente', 'accepte', 'refuse'].includes(statut)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }
    const m = await Membre.findByIdAndUpdate(
      req.params.id,
      { $set: { statut } },
      { new: true, runValidators: true },
    );
    if (!m) return res.status(404).json({ error: 'Membre introuvable' });
    return res.json(m);
  } catch (error) {
    return res.status(400).json({ error: 'Modification du statut impossible' });
  }
});

// DELETE /api/membres/:id — admin
router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }
    const deleted = await Membre.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Membre introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
