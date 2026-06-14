const express = require('express');
const router = express.Router();
const Sermon = require('../models/Sermon');

// ROUTE 1 : Planifier une nouvelle prédication (Espace Pasteur)
router.post('/schedule', async (req, res) => {
  try {
    const { titre, description, audioUrl, dateDiffusion, creePar } = req.body;

    // Création de la prédication dans la base de données
    const newSermon = new Sermon({
      titre,
      description,
      audioUrl,
      dateDiffusion, // Format attendu : "2026-06-15T16:00:00"
      creePar // L'ID du Pasteur
    });

    await newSermon.save();
    res.status(201).json({ message: "Prédication planifiée avec succès !", sermon: newSermon });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la planification", details: error.message });
  }
});

// ROUTE 2 : Récupérer toutes les prédications planifiées ou passées
router.get('/', async (req, res) => {
  try {
    const sermons = await Sermon.find().sort({ dateDiffusion: -1 }).populate('creePar', 'nom');
    res.status(200).json(sermons);
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la récupération", details: error.message });
  }
});

module.exports = router;