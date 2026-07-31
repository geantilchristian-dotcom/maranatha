const cron = require('node-cron');

const Sermon = require('../models/Sermon');
const User = require('../models/User');
const { envoyerDemarrageMasse } = require('./firebase');
const { broadcast } = require('./sse');

async function obtenirTokensActifs() {
  const utilisateurs = await User.find({
    modeMaranathaActif: true,
    role: 'fidele',
    fcmToken: { $type: 'string', $ne: '' },
  })
    .select({ fcmToken: 1 })
    .lean();

  return utilisateurs.map((utilisateur) => utilisateur.fcmToken).filter(Boolean);
}

async function demarrerPredicationsArrivees() {
  const maintenant = new Date();
  const retardMaximum = new Date(Date.now() - 15 * 60 * 1000);

  const sermons = await Sermon.find({
    statut: 'planifie',
    dateDiffusion: {
      $gte: retardMaximum,
      $lte: maintenant,
    },
  }).sort({ dateDiffusion: 1 });

  if (sermons.length === 0) {
    return;
  }

  const tokens = await obtenirTokensActifs();

  for (const sermon of sermons) {
    sermon.statut = 'en_cours';
    await sermon.save();

    console.log(`[HORLOGE] Démarrage : "${sermon.titre}"`);

    broadcast('sermon_live', {
      _id: sermon._id,
      titre: sermon.titre,
      description: sermon.description,
      audioUrl: sermon.audioUrl,
      dateDiffusion: sermon.dateDiffusion,
      statut: 'en_cours',
    });

    try {
      const resultat = await envoyerDemarrageMasse(tokens, sermon);
      console.log(
        `[FCM/démarrage] succès=${resultat.successCount} échecs=${resultat.failureCount}`,
      );
    } catch (error) {
      console.error('[FCM/démarrage]', error.message);
    }
  }
}

cron.schedule('* * * * *', async () => {
  try {
    await demarrerPredicationsArrivees();
  } catch (error) {
    console.error('[HORLOGE]', error.message);
  }
});

cron.schedule('*/5 * * * *', async () => {
  try {
    const limite = new Date(Date.now() - 3 * 60 * 60 * 1000);
    const resultat = await Sermon.updateMany(
      {
        statut: 'en_cours',
        dateDiffusion: { $lt: limite },
      },
      { $set: { statut: 'termine' } },
    );

    if (resultat.modifiedCount > 0) {
      console.log(
        `[NETTOYAGE] ${resultat.modifiedCount} prédication(s) terminée(s)`,
      );
      broadcast('sermon_update', { action: 'cleanup' });
    }
  } catch (error) {
    console.error('[NETTOYAGE]', error.message);
  }
});

console.log('Planificateur Maranatha démarré.');
