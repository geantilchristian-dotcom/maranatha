const express = require('express');
const router = express.Router();
const Sermon = require('../models/Sermon');

// ROUTE 1 : Planifier une nouvelle prédication (Espace Pasteur)
router.post('/schedule', async (req, res) => {
  try {
    const { titre, description, audioUrl, dateDiffusion, creePar } = req.body;
    const newSermon = new Sermon({ titre, description, audioUrl, dateDiffusion, creePar });
    await newSermon.save();
    res.status(201).json({ message: "Prédication planifiée avec succès !", sermon: newSermon });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la planification", details: error.message });
  }
});

// ROUTE 2 : Récupérer toutes les prédications (triées par date décroissante)
router.get('/', async (req, res) => {
  try {
    const sermons = await Sermon.find().sort({ dateDiffusion: -1 });
    res.status(200).json(sermons);
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la récupération", details: error.message });
  }
});

// ROUTE 3 : Supprimer une prédication (Espace Pasteur)
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
