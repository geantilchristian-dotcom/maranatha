const express = require('express');
const router = express.Router();
const multer = require('multer');
const Sermon = require('../models/Sermon');
const { uploadAudio } = require('../utils/cloudinary');
const { sseHandler } = require('../utils/sse');

// Multer : stockage en memoire (pas sur disque Render)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 200 * 1024 * 1024 }, // 200 Mo max
  fileFilter: (req, file, cb) => {
    const ok = /\.(mp3|mp4|ogg|wav|m4a|aac)$/i.test(file.originalname) ||
               file.mimetype.startsWith('audio/') ||
               file.mimetype.startsWith('video/');
    ok ? cb(null, true) : cb(new Error('Format non supporte. Utilisez MP3, M4A, OGG ou WAV.'));
  },
});

// ROUTE SSE — mises a jour en temps reel pour les navigateurs
router.get('/events', sseHandler);

// ROUTE 1 : Upload audio + planifier une predication
router.post('/schedule', upload.single('audio'), async (req, res) => {
  try {
    const { titre, description, dateDiffusion } = req.body;

    if (!titre || !dateDiffusion) {
      return res.status(400).json({ error: "Titre et date de diffusion obligatoires" });
    }

    let audioUrl = req.body.audioUrl || null;

    if (req.file) {
      audioUrl = await uploadAudio(req.file.buffer, req.file.originalname);
    }

    if (!audioUrl) {
      return res.status(400).json({ error: "Aucun fichier audio fourni" });
    }

    const sermon = new Sermon({ titre, description, audioUrl, dateDiffusion });
    await sermon.save();

    const { broadcast } = require('../utils/sse');
    broadcast('sermon_update', { action: 'new', sermon });

    res.status(201).json({ message: "Predication planifiee avec succes !", sermon });

  } catch (error) {
    console.error("Erreur planification:", error.message);
    res.status(500).json({ error: error.message || "Erreur lors de la planification" });
  }
});

// ROUTE 2 : Recuperer toutes les predications
router.get('/', async (req, res) => {
  try {
    const sermons = await Sermon.find().sort({ dateDiffusion: -1 });
    res.status(200).json(sermons);
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la recuperation" });
  }
});

// ROUTE 3 : Supprimer une predication
router.delete('/:id', async (req, res) => {
  try {
    const sermon = await Sermon.findByIdAndDelete(req.params.id);
    if (!sermon) return res.status(404).json({ error: "Predication introuvable" });

    const { broadcast } = require('../utils/sse');
    broadcast('sermon_update', { action: 'deleted', id: req.params.id });

    res.status(200).json({ message: "Predication supprimee" });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la suppression" });
  }
});

// ROUTE 4 : Demarrer une predication en direct (autoplay)
// Met toutes les autres en 'termine' puis passe celle-ci en 'en_cours'
router.patch('/:id/start', async (req, res) => {
  try {
    await Sermon.updateMany({ statut: 'en_cours' }, { statut: 'termine' });
    const sermon = await Sermon.findByIdAndUpdate(
      req.params.id,
      { statut: 'en_cours' },
      { new: true }
    );
    if (!sermon) return res.status(404).json({ error: 'Predication introuvable' });
    const { broadcast } = require('../utils/sse');
    broadcast('sermon_update', { action: 'started', sermon });
    res.json(sermon);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ROUTE 5 : Terminer une predication
router.patch('/:id/stop', async (req, res) => {
  try {
    const sermon = await Sermon.findByIdAndUpdate(
      req.params.id,
      { statut: 'termine' },
      { new: true }
    );
    if (!sermon) return res.status(404).json({ error: 'Predication introuvable' });
    const { broadcast } = require('../utils/sse');
    broadcast('sermon_update', { action: 'stopped', sermon });
    res.json(sermon);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
