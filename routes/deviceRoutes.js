const express = require('express');

const Device = require('../models/Device');
const adminOnly = require('../utils/adminAuth');

const router = express.Router();

function cleanText(value, maxLength) {
  return String(value || '').trim().slice(0, maxLength);
}

router.post('/register', async (req, res) => {
  try {
    const installationId = cleanText(req.body.installationId, 220);
    const fcmToken = cleanText(req.body.fcmToken, 4096);
    const appVersion = cleanText(req.body.appVersion, 80);
    const platform = ['android', 'ios', 'web'].includes(req.body.platform)
      ? req.body.platform
      : 'android';
    const modeMaranathaActif = req.body.modeMaranathaActif === true;

    if (!installationId || !fcmToken) {
      return res.status(400).json({
        error: 'installationId et fcmToken sont obligatoires',
      });
    }

    // Un token FCM ne doit appartenir qu'à une seule installation active.
    await Device.deleteMany({
      fcmToken,
      installationId: { $ne: installationId },
    });

    const device = await Device.findOneAndUpdate(
      { installationId },
      {
        $set: {
          fcmToken,
          platform,
          appVersion,
          modeMaranathaActif,
          lastSeenAt: new Date(),
        },
      },
      {
        new: true,
        upsert: true,
        runValidators: true,
        setDefaultsOnInsert: true,
      },
    );

    return res.json({
      ok: true,
      message: modeMaranathaActif
        ? 'Réveil Maranatha activé sur cet appareil'
        : 'Appareil enregistré',
      device: {
        installationId: device.installationId,
        modeMaranathaActif: device.modeMaranathaActif,
        lastSeenAt: device.lastSeenAt,
      },
    });
  } catch (error) {
    console.error('[devices/register]', error.message);
    return res.status(500).json({ error: 'Enregistrement de l’appareil impossible' });
  }
});

router.get('/count', adminOnly, async (_req, res) => {
  try {
    const [total, actifs] = await Promise.all([
      Device.countDocuments(),
      Device.countDocuments({ modeMaranathaActif: true }),
    ]);

    return res.json({ total, actifs });
  } catch (error) {
    console.error('[devices/count]', error.message);
    return res.status(500).json({ error: 'Comptage impossible' });
  }
});

module.exports = router;
