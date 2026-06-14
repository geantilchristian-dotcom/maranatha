const cron = require('node-cron');
const Sermon = require('../models/Sermon');
const { envoyerNotificationMasse } = require('./firebase');

// Tache principale — toutes les minutes
// Cherche un sermon planifie dont l'heure est arrivee
cron.schedule('* * * * *', async () => {
  try {
    const maintenant = new Date();

    const debutMinute = new Date(maintenant);
    debutMinute.setSeconds(0, 0);

    const finMinute = new Date(maintenant);
    finMinute.setSeconds(59, 999);

    const sermonAEnvoyer = await Sermon.findOne({
      dateDiffusion: { $gte: debutMinute, $lte: finMinute },
      statut: 'planifie',
    });

    if (!sermonAEnvoyer) return;

    console.log(`[HORLOGE] Heure sonnee ! Predication : "${sermonAEnvoyer.titre}"`);

    // Marquer "en_cours" — reste en_cours pendant 3h
    // (la tache de nettoyage ci-dessous le marquera "termine" apres)
    sermonAEnvoyer.statut = 'en_cours';
    await sermonAEnvoyer.save();
    console.log(`[HORLOGE] Sermon "${sermonAEnvoyer.titre}" -> en_cours`);

    // Tentative d'envoi FCM (si des utilisateurs sont enregistres)
    try {
      const User = require('../models/User');
      const fideles = await User.find({ modeMaranathaActif: true, role: 'fidele' });
      const tokens = fideles.map(f => f.fcmToken).filter(t => t && t.length > 0);

      if (tokens.length > 0) {
        const resultat = await envoyerNotificationMasse(tokens, sermonAEnvoyer);
        console.log(`[FIREBASE] Succes: ${resultat.successCount} | Echecs: ${resultat.failureCount}`);
      } else {
        console.log('[HORLOGE] Aucun token FCM — diffusion web uniquement.');
      }
    } catch (fcmErr) {
      console.error('[FCM] Erreur non bloquante :', fcmErr.message);
      // On ne bloque pas — le sermon reste "en_cours" quand meme
    }

  } catch (error) {
    console.error('[HORLOGE] Erreur planificateur :', error.message);
  }
});

// Tache de nettoyage — toutes les 5 minutes
// Marque "termine" les sermons "en_cours" depuis plus de 3 heures
cron.schedule('*/5 * * * *', async () => {
  try {
    const limite = new Date(Date.now() - 3 * 60 * 60 * 1000); // il y a 3h
    const result = await Sermon.updateMany(
      { statut: 'en_cours', dateDiffusion: { $lt: limite } },
      { $set: { statut: 'termine' } }
    );
    if (result.modifiedCount > 0) {
      console.log(`[NETTOYAGE] ${result.modifiedCount} sermon(s) marques "termine".`);
    }
  } catch (err) {
    console.error('[NETTOYAGE] Erreur :', err.message);
  }
});

console.log('Planificateur Maranatha demarre — verification chaque minute.');
