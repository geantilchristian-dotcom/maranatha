const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const User = require('../models/User');

function cleanText(value, maxLength) {
  return String(value || '').trim().slice(0, maxLength);
}

// Enregistre l'appareil d'un fidèle et met à jour son token FCM.
router.post('/register', async (req, res) => {
  try {
    const nom = cleanText(req.body.nom, 120) || 'Fidèle';
    const telephone = cleanText(req.body.telephone, 160);
    const fcmToken = cleanText(req.body.fcmToken, 4096);

    if (!telephone) {
      return res.status(400).json({ error: 'Identifiant du fidèle requis' });
    }

    const user = await User.findOneAndUpdate(
      { telephone },
      {
        $set: { nom, fcmToken, role: 'fidele' },
        $setOnInsert: {
          modeMaranathaActif: true,
          dateInscription: new Date(),
        },
      },
      { new: true, upsert: true, runValidators: true },
    );

    return res.status(200).json({
      message: 'Appareil enregistré',
      user,
    });
  } catch (error) {
    console.error('[users/register]', error.message);
    return res.status(500).json({
      error: 'Erreur lors de l’enregistrement',
    });
  }
});

router.patch('/:id/toggle-maranatha', async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Identifiant invalide' });
    }

    if (typeof req.body.modeMaranathaActif !== 'boolean') {
      return res.status(400).json({ error: 'Valeur booléenne requise' });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { modeMaranathaActif: req.body.modeMaranathaActif },
      { new: true, runValidators: true },
    );

    if (!user) return res.status(404).json({ error: 'Fidèle introuvable' });
    return res.json({ message: 'Préférence mise à jour', user });
  } catch (error) {
    console.error('[users/toggle]', error.message);
    return res.status(500).json({ error: 'Erreur lors de la modification' });
  }
});

router.get('/count', async (_req, res) => {
  try {
    const count = await User.countDocuments({ role: 'fidele' });
    return res.json({ count });
  } catch (error) {
    return res.status(500).json({ error: 'Erreur lors du comptage' });
  }
});

module.exports = router;
