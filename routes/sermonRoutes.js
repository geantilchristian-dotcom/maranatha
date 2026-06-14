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

    // Notifier tous les clients SSE en temps reel
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

module.exports = router;
