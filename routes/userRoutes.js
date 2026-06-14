const express = require('express');
const router = express.Router();
const User = require('../models/User');

// ROUTE 1 : Enregistrer ou connecter un utilisateur (Fidèle ou Pasteur)
router.post('/register', async (req, res) => {
  try {
    const { nom, telephone, fcmToken, role } = req.body;
    let user = await User.findOne({ telephone });
    if (user) {
      user.fcmToken = fcmToken;
      await user.save();
      return res.status(200).json({ message: "Connexion réussie, token mis à jour", user });
    }
    user = new User({ nom, telephone, fcmToken, role });
    await user.save();
    res.status(201).json({ message: "Utilisateur créé avec succès", user });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de l'enregistrement", details: error.message });
  }
});

// ROUTE 2 : Activer ou désactiver le mode Maranatha (Alarme)
router.patch('/:id/toggle-maranatha', async (req, res) => {
  try {
    const { modeMaranathaActif } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { modeMaranathaActif },
      { new: true }
    );
    res.status(200).json({ message: "Préférence mise à jour", user });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors de la modification des préférences", details: error.message });
  }
});

// ROUTE 3 : Compter les fidèles inscrits (pour le tableau de bord admin)
router.get('/count', async (req, res) => {
  try {
    const count = await User.countDocuments({ role: { $ne: 'pasteur' } });
    res.status(200).json({ count });
  } catch (error) {
    res.status(500).json({ error: "Erreur lors du comptage", details: error.message });
  }
});

module.exports = router;
