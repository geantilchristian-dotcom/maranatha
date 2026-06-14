const express = require('express');
const router = express.Router();
const multer = require('multer');
const Sermon = require('../models/Sermon');
const { uploadAudioVersStorage } = require('../utils/firebase');

// Multer : stockage en mémoire (pas sur disque Render)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 200 * 1024 * 1024 }, // 200 Mo max
  fileFilter: (req, file, cb) => {
    const allowed = ['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/ogg', 'audio/wav', 'audio/x-m4a'];
    if (allowed.includes(file.mimetype) || file.originalname.match(/\.(mp3|mp4|ogg|wav|m4a)$/i)) {
      cb(null, true);
    } else {
      cb(new Error('Format audio non supporté. Utilisez MP3, MP4, OGG ou WAV.'));
    }
  },
});

// ROUTE 1 : Upload audio + planifier une prédication (multipart/form-data)
router.post('/schedule', upload.single('audio'), async (req, res) => {
  try {
    const { titre, description, dateDiffusion } = req.body;

    if (!titre || !dateDiffusion) {
      return res.status(400).json({ error: "Titre et date de diffusion obligatoires" });
    }

    let audioUrl = req.body.audioUrl || null;

    // Si un fichier audio a été uploadé, l'envoyer vers Firebase Storage
    if (req.file) {
      audioUrl = await uploadAudioVersStorage(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype
      );
    }

    if (!audioUrl) {
      return res.status(400).json({ error: "Aucun fichier audio ni lien fourni" });
    }

    const newSermon = new Sermon({
      titre,
      description,
      audioUrl,
      dateDiffusion,
      creePar: req.body.creePar || undefined,
    });

    await newSermon.save();
    res.status(201).json({ message: "Prédication planifiée avec succès !", sermon: newSermon });

  } catch (error) {
    console.error("Erreur planification:", error);
    res.status(500).json({ error: error.message || "Erreur lors de la planification" });
  }
});

// ROUTE 2 : Récupérer toutes les prédications
router.get('/', async (req, res) => {
  try {
    const sermons = await Sermon.find().sort({ dateDiffusion: -1 });
    res.status(200).json(sermons);
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la récupération", details: error.message });
  }
});

// ROUTE 3 : Supprimer une prédication
router.delete('/:id', async (req, res) => {
  try {
    const sermon = await Sermon.findByIdAndDelete(req.params.id);
    if (!sermon) return res.status(404).json({ error: "Prédication introuvable" });
    res.status(200).json({ message: "Prédication supprimée" });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la suppression", details: error.message });
  }
});

module.exports = router;
