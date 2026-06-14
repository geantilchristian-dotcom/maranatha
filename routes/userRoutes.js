const express = require('express');
const router = express.Router();
const User = require('../models/User');

// ROUTE 1 : Enregistrer ou connecter un utilisateur (Fidèle ou Pasteur)
router.post('/register', async (req, res) => {
  try {
    const { nom, telephone, fcmToken, role } = req.body;

    // Vérifier si l'utilisateur existe déjà avec ce numéro de téléphone
    let user = await User.findOne({ telephone });

    if (user) {
      // Si l'utilisateur existe déjà, on met juste à jour son token Firebase
      user.fcmToken = fcmToken;
      await user.save();
      return res.status(200).json({ message: "Connexion réussie, token mis à jour", user });
    }

    // Sinon, on crée un nouvel utilisateur
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

module.exports = router;