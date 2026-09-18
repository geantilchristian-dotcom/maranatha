const express = require('express');
const mongoose = require('mongoose');
const Bibliotheque = require('../models/Bibliotheque');
const Livre = require('../models/Livre');
const Video = require('../models/Video');
const adminOnly = require('../utils/adminAuth');
const { cleanText, cleanHttpUrl } = require('../utils/security');
const { notifierPublicationNouvelle } = require('../utils/publicationNotifications');

const router = express.Router();
const TYPES = new Set(['video', 'photo', 'audio', 'book']);

function normaliseNew(item) {
  const obj = item.toObject ? item.toObject() : item;
  return { ...obj, source: 'bibliotheque' };
}

function normaliseLivre(item) {
  const obj = item.toObject ? item.toObject() : item;
  return {
    _id: obj._id,
    type: 'book',
    titre: obj.titre,
    auteur: obj.auteur || '',
    description: obj.description || '',
    categorie: obj.categorie || 'Général',
    couvertureUrl: obj.couvertureUrl || '',
    fichierUrl: obj.fichierUrl || obj.lienExterne || '',
    lienExterne: obj.lienExterne || '',
    telechargeable: true,
    actif: true,
    ordre: obj.ordre || 0,
    createdAt: obj.createdAt,
    updatedAt: obj.updatedAt,
    source: 'livre',
  };
}

function normaliseVideo(item) {
  const obj = item.toObject ? item.toObject() : item;
  return {
    _id: obj._id,
    type: 'video',
    titre: obj.titre,
    auteur: obj.auteur || '',
    description: obj.description || '',
    categorie: obj.categorie || 'Général',
    couvertureUrl: obj.couvertureUrl || '',
    fichierUrl: obj.fichierUrl || '',
    lienExterne: obj.youtubeUrl || obj.lienExterne || '',
    youtubeUrl: obj.youtubeUrl || '',
    telechargeable: Boolean(obj.fichierUrl),
    actif: true,
    ordre: obj.ordre || 0,
    createdAt: obj.createdAt,
    updatedAt: obj.updatedAt,
    source: 'video',
  };
}

async function getCombined(includeInactive) {
  const [current, livres, videos] = await Promise.all([
    Bibliotheque.find(includeInactive ? {} : { actif: true })
      .sort({ ordre: 1, createdAt: -1 })
      .lean(),
    Livre.find().sort({ ordre: 1, createdAt: -1 }).lean(),
    Video.find().sort({ ordre: 1, createdAt: -1 }).lean(),
  ]);

  return [
    ...current.map(normaliseNew),
    ...livres.map(normaliseLivre),
    ...videos.map(normaliseVideo),
  ].sort((a, b) => {
    const orderDiff = Number(a.ordre || 0) - Number(b.ordre || 0);
    if (orderDiff !== 0) return orderDiff;
    return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
  });
}

router.get('/', async (_req, res) => {
  try {
    return res.json(await getCombined(false));
  } catch (error) {
    console.error('[bibliotheque/list]', error.message);
    return res.status(500).json({ error: 'Bibliothèque temporairement indisponible' });
  }
});

router.get('/all', adminOnly, async (_req, res) => {
  try {
    return res.json(await getCombined(true));
  } catch (error) {
    console.error('[bibliotheque/admin-list]', error.message);
    return res.status(500).json({ error: 'Bibliothèque temporairement indisponible' });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const type = cleanText(req.body.type, 20).toLowerCase();
    const titre = cleanText(req.body.titre, 180);
    const auteur = cleanText(req.body.auteur, 160);
    const description = cleanText(req.body.description, 4000);
    const categorie = cleanText(req.body.categorie, 100) || 'Général';
    const couvertureUrl = cleanHttpUrl(req.body.couvertureUrl);
    const fichierUrl = cleanHttpUrl(req.body.fichierUrl);
    const lienExterne = cleanHttpUrl(req.body.lienExterne);
    const nomFichier = cleanText(req.body.nomFichier, 220);
    const telechargeable = req.body.telechargeable !== false;

    if (!TYPES.has(type) || !titre) {
      return res.status(400).json({ error: 'Type et titre valides obligatoires' });
    }
    if (!couvertureUrl) {
      return res.status(400).json({ error: 'Une couverture est obligatoire' });
    }
    if (!fichierUrl && !lienExterne) {
      return res.status(400).json({ error: 'Ajoutez un fichier ou un lien valide' });
    }

    const doc = await Bibliotheque.create({
      type,
      titre,
      auteur,
      description,
      categorie,
      couvertureUrl,
      fichierUrl,
      lienExterne,
      nomFichier,
      telechargeable,
      actif: req.body.actif !== false,
      ordre: Number.isFinite(Number(req.body.ordre)) ? Number(req.body.ordre) : 0,
    });

    if (doc.actif) notifierPublicationNouvelle('bibliotheque', doc);
    return res.status(201).json(normaliseNew(doc));
  } catch (error) {
    console.error('[bibliotheque/create]', error.message);
    return res.status(400).json({ error: 'Publication impossible' });
  }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    const allowed = {};
    if (req.body.titre !== undefined) allowed.titre = cleanText(req.body.titre, 180);
    if (req.body.auteur !== undefined) allowed.auteur = cleanText(req.body.auteur, 160);
    if (req.body.description !== undefined) allowed.description = cleanText(req.body.description, 4000);
    if (req.body.categorie !== undefined) allowed.categorie = cleanText(req.body.categorie, 100);
    if (typeof req.body.telechargeable === 'boolean') allowed.telechargeable = req.body.telechargeable;
    if (typeof req.body.actif === 'boolean') allowed.actif = req.body.actif;
    if (Number.isFinite(Number(req.body.ordre))) allowed.ordre = Number(req.body.ordre);

    const previous = await Bibliotheque.findById(req.params.id).select({ actif: 1 }).lean();
    const doc = await Bibliotheque.findByIdAndUpdate(
      req.params.id,
      { $set: allowed },
      { new: true, runValidators: true },
    );

    if (!doc) return res.status(404).json({ error: 'Contenu introuvable' });
    if (previous && !previous.actif && allowed.actif === true) {
      notifierPublicationNouvelle('bibliotheque', doc);
    }
    return res.json(normaliseNew(doc));
  } catch (error) {
    return res.status(400).json({ error: 'Modification impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    const source = cleanText(req.query.source, 30).toLowerCase();
    let doc = null;
    if (source === 'livre') doc = await Livre.findByIdAndDelete(req.params.id);
    else if (source === 'video') doc = await Video.findByIdAndDelete(req.params.id);
    else doc = await Bibliotheque.findByIdAndDelete(req.params.id);

    if (!doc) return res.status(404).json({ error: 'Contenu introuvable' });
    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

module.exports = router;
