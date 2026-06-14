const cron = require('node-cron');
const Sermon = require('../models/Sermon');
const { envoyerNotificationMasse } = require('./firebase');
const { broadcast } = require('./sse');

// Tache principale — toutes les minutes
cron.schedule('* * * * *', async () => {
  try {
    const maintenant = new Date();
    const debutMinute = new Date(maintenant); debutMinute.setSeconds(0, 0);
    const finMinute   = new Date(maintenant); finMinute.setSeconds(59, 999);

    const sermon = await Sermon.findOne({
      dateDiffusion: { $gte: debutMinute, $lte: finMinute },
      statut: 'planifie',
    });

    if (!sermon) return;

    console.log(`[HORLOGE] Heure sonnee ! "${sermon.titre}"`);

    sermon.statut = 'en_cours';
    await sermon.save();

    // Pousser la mise a jour instantanement vers tous les navigateurs ouverts
    broadcast('sermon_live', {
      _id:          sermon._id,
      titre:        sermon.titre,
      description:  sermon.description,
      audioUrl:     sermon.audioUrl,
      dateDiffusion: sermon.dateDiffusion,
      statut:       'en_cours',
    });

    // Envoi FCM (non bloquant)
    try {
      const User = require('../models/User');
      const fideles = await User.find({ modeMaranathaActif: true, role: 'fidele' });
      const tokens = fideles.map(f => f.fcmToken).filter(t => t && t.length > 0);
      if (tokens.length > 0) {
        const r = await envoyerNotificationMasse(tokens, sermon);
        console.log(`[FCM] Succes: ${r.successCount} | Echecs: ${r.failureCount}`);
      } else {
        console.log('[HORLOGE] Aucun token FCM — diffusion web uniquement.');
      }
    } catch (e) {
      console.error('[FCM] Erreur non bloquante :', e.message);
    }

  } catch (err) {
    console.error('[HORLOGE] Erreur :', err.message);
  }
});

// Nettoyage — toutes les 5 min : marque "termine" les sermons en_cours depuis +3h
cron.schedule('*/5 * * * *', async () => {
  try {
    const limite = new Date(Date.now() - 3 * 60 * 60 * 1000);
    const result = await Sermon.updateMany(
      { statut: 'en_cours', dateDiffusion: { $lt: limite } },
      { $set: { statut: 'termine' } }
    );
    if (result.modifiedCount > 0) {
      console.log(`[NETTOYAGE] ${result.modifiedCount} sermon(s) -> termine.`);
      broadcast('sermon_update', { action: 'cleanup' });
    }
  } catch (err) {
    console.error('[NETTOYAGE] Erreur :', err.message);
  }
});

console.log('Planificateur Maranatha demarre.');
