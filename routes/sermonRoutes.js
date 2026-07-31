const express = require('express');
const mongoose = require('mongoose');
const multer = require('multer');

const Sermon = require('../models/Sermon');
const adminOnly = require('../utils/adminAuth');
const { uploadAudio } = require('../utils/cloudinary');
const {
  envoyerAnnulationMasse,
  envoyerArretMasse,
  envoyerDemarrageMasse,
  envoyerProgrammationMasse,
} = require('../utils/firebase');
const { broadcast, sseHandler } = require('../utils/sse');
const { obtenirTokensActifs } = require('../utils/deviceTokens');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 80 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    const supported =
      /\.(mp3|mp4|ogg|wav|m4a|aac)$/i.test(file.originalname) ||
      file.mimetype.startsWith('audio/') ||
      file.mimetype.startsWith('video/');

    callback(
      supported
        ? null
        : new Error('Format non supporté. Utilisez MP3, M4A, OGG ou WAV.'),
      supported,
    );
  },
});

async function notifierSansBloquer(operation, label) {
  try {
    const resultat = await operation();
    console.log(
      `[FCM/${label}] succès=${resultat.successCount} échecs=${resultat.failureCount}`,
    );
  } catch (error) {
    console.error(`[FCM/${label}]`, error.message);
  }
}

router.get('/events', sseHandler);

router.get('/upcoming', async (req, res) => {
  try {
    const joursDemandes = Number.parseInt(String(req.query.days || '30'), 10);
    const jours = Number.isFinite(joursDemandes)
      ? Math.min(Math.max(joursDemandes, 1), 90)
      : 30;

    const maintenant = new Date();
    const limite = new Date(Date.now() + jours * 24 * 60 * 60 * 1000);
    const retardMaximum = new Date(Date.now() - 15 * 60 * 1000);

    const sermons = await Sermon.find({
      $or: [
        {
          statut: 'planifie',
          dateDiffusion: { $gt: maintenant, $lte: limite },
        },
        {
          statut: { $in: ['planifie', 'en_cours'] },
          dateDiffusion: { $gte: retardMaximum, $lte: maintenant },
        },
      ],
    })
      .sort({ dateDiffusion: 1 })
      .select({ titre: 1, description: 1, audioUrl: 1, dateDiffusion: 1 })
      .lean();

    return res.json(sermons);
  } catch (error) {
    console.error('[sermons/upcoming]', error.message);
    return res.status(500).json({ error: 'Synchronisation impossible' });
  }
});

router.get('/', async (_req, res) => {
  try {
    const sermons = await Sermon.find().sort({ dateDiffusion: -1 }).lean();
    return res.json(sermons);
  } catch (error) {
    console.error('[sermons/list]', error.message);
    return res.status(500).json({ error: 'Récupération impossible' });
  }
});

router.post('/schedule', adminOnly, upload.single('audio'), async (req, res) => {
  try {
    const titre = String(req.body.titre || '').trim().slice(0, 180);
    const description = String(req.body.description || '').trim().slice(0, 3000);
    const dateDiffusion = new Date(req.body.dateDiffusion);

    if (!titre || Number.isNaN(dateDiffusion.getTime())) {
      return res.status(400).json({
        error: 'Titre et date de diffusion valides obligatoires',
      });
    }

    if (dateDiffusion.getTime() < Date.now() + 30_000) {
      return res.status(400).json({
        error: 'Choisissez une heure située dans le futur',
      });
    }

    let audioUrl = String(req.body.audioUrl || '').trim();
    if (req.file) {
      audioUrl = await uploadAudio(req.file.buffer, req.file.originalname);
    }

    if (!audioUrl) {
      return res.status(400).json({ error: 'Aucun fichier audio fourni' });
    }

    const sermon = await Sermon.create({
      titre,
      description,
      audioUrl,
      dateDiffusion,
      statut: 'planifie',
    });

    broadcast('sermon_update', { action: 'new', sermon });

    void notifierSansBloquer(async () => {
      const tokens = await obtenirTokensActifs();
      return envoyerProgrammationMasse(tokens, sermon);
    }, 'programmation');

    return res.status(201).json({
      message: 'Prédication planifiée et envoyée aux téléphones',
      sermon,
    });
  } catch (error) {
    console.error('[sermons/schedule]', error.message);
    return res.status(500).json({ error: 'Planification impossible' });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    const sermon = await Sermon.findByIdAndDelete(req.params.id);
    if (!sermon) {
      return res.status(404).json({ error: 'Prédication introuvable' });
    }

    broadcast('sermon_update', { action: 'deleted', id: req.params.id });

    void notifierSansBloquer(async () => {
      const tokens = await obtenirTokensActifs();
      return envoyerAnnulationMasse(tokens, req.params.id);
    }, 'annulation');

    return res.json({ message: 'Prédication supprimée et alarme annulée' });
  } catch (error) {
    console.error('[sermons/delete]', error.message);
    return res.status(500).json({ error: 'Suppression impossible' });
  }
});

router.patch('/:id/start', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    await Sermon.updateMany(
      { statut: 'en_cours' },
      { $set: { statut: 'termine' } },
    );

    const sermon = await Sermon.findByIdAndUpdate(
      req.params.id,
      { statut: 'en_cours' },
      { new: true, runValidators: true },
    );

    if (!sermon) {
      return res.status(404).json({ error: 'Prédication introuvable' });
    }

    broadcast('sermon_update', { action: 'started', sermon });
    broadcast('sermon_live', sermon);

    void notifierSansBloquer(async () => {
      const tokens = await obtenirTokensActifs();
      return envoyerDemarrageMasse(tokens, sermon);
    }, 'demarrage-manuel');

    return res.json(sermon);
  } catch (error) {
    console.error('[sermons/start]', error.message);
    return res.status(500).json({ error: 'Démarrage impossible' });
  }
});

router.patch('/:id/stop', adminOnly, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    const sermon = await Sermon.findByIdAndUpdate(
      req.params.id,
      { statut: 'termine' },
      { new: true, runValidators: true },
    );

    if (!sermon) {
      return res.status(404).json({ error: 'Prédication introuvable' });
    }

    broadcast('sermon_update', { action: 'stopped', sermon });

    void notifierSansBloquer(async () => {
      const tokens = await obtenirTokensActifs();
      return envoyerArretMasse(tokens, sermon._id);
    }, 'arret');

    return res.json(sermon);
  } catch (error) {
    console.error('[sermons/stop]', error.message);
    return res.status(500).json({ error: 'Arrêt impossible' });
  }
});

router.use((error, _req, res, _next) => {
  if (error instanceof multer.MulterError || error) {
    return res.status(400).json({ error: error.message || 'Fichier invalide' });
  }
  return res.status(500).json({ error: 'Erreur de téléversement' });
});

module.exports = router;
