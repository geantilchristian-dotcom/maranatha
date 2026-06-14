const cron = require('node-cron');
const Sermon = require('../models/Sermon');
const User = require('../models/User');
const { envoyerNotificationMasse } = require('./firebase');

// Cette tâche tourne TOUTES LES MINUTES
cron.schedule('* * * * *', async () => {
  try {
    const maintenant = new Date();

    const debutMinute = new Date(maintenant);
    debutMinute.setSeconds(0, 0);

    const finMinute = new Date(maintenant);
    finMinute.setSeconds(59, 999);

    // 1. Chercher une prédication planifiée pour cette minute exacte
    const sermonAEnvoyer = await Sermon.findOne({
      dateDiffusion: { $gte: debutMinute, $lte: finMinute },
      statut: 'planifie',
    });

    if (!sermonAEnvoyer) return;

    console.log(`\n⏰ [HORLOGE] Heure sonnée ! Prédication : "${sermonAEnvoyer.titre}"`);

    // Marquer "en cours" immédiatement pour éviter les doublons
    sermonAEnvoyer.statut = 'en_cours';
    await sermonAEnvoyer.save();

    // 2. Récupérer tous les fidèles avec le mode Maranatha actif
    const fideles = await User.find({ modeMaranathaActif: true, role: 'fidele' });

    if (fideles.length === 0) {
      console.log('[HORLOGE] Aucun fidèle disponible avec le mode Maranatha actif.');
      sermonAEnvoyer.statut = 'termine';
      await sermonAEnvoyer.save();
      return;
    }

    // 3. Extraire les tokens FCM valides
    const tokens = fideles
      .map((f) => f.fcmToken)
      .filter((t) => t && t.length > 0);

    if (tokens.length === 0) {
      console.log('[HORLOGE] Aucun token FCM valide trouvé.');
      sermonAEnvoyer.statut = 'termine';
      await sermonAEnvoyer.save();
      return;
    }

    console.log(`[HORLOGE] Envoi Firebase à ${tokens.length} fidèle(s)...`);

    // 4. ENVOI RÉEL Firebase à tous les fidèles d'un seul coup
    const resultat = await envoyerNotificationMasse(tokens, sermonAEnvoyer);

    console.log(
      `🚀 [FIREBASE] Envoi terminé ! Succès: ${resultat.successCount} | Échecs: ${resultat.failureCount}`
    );

    if (resultat.tokensEchoues.length > 0) {
      console.log('[FIREBASE] Tokens en échec :', resultat.tokensEchoues);
    }

    // 5. Marquer la prédication comme terminée
    sermonAEnvoyer.statut = 'termine';
    await sermonAEnvoyer.save();

    console.log(`[HORLOGE] Diffusion de "${sermonAEnvoyer.titre}" terminée.\n`);

  } catch (error) {
    console.error('[HORLOGE] Erreur dans le planificateur :', error.message);
  }
});

console.log('⏰ Planificateur Maranatha démarré — vérification chaque minute.');
