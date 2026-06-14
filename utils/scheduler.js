const cron = require('node-cron');
const Sermon = require('../models/Sermon');
const User = require('../models/User');

// Cette fonction va tourner TOUTES LES MINUTES (la chaîne '* * * * *' signifie chaque minute)
cron.schedule('* * * * *', async () => {
  try {
    const maintenant = new Date();
    
    // On arrondi à la minute près pour correspondre aux planifications du Pasteur
    const debutMinute = new Date(maintenant.setSeconds(0, 0));
    const finMinute = new Date(maintenant.setSeconds(59, 999));

    // 1. Chercher s'il y a une prédication planifiée pour cette minute exacte et qui n'a pas encore débuté
    const sermonAEnvoyer = await Sermon.findOne({
      dateDiffusion: { $gte: debutMinute, $lte: finMinute },
      statut: 'planifie'
    });

    if (sermonAEnvoyer) {
      console.log(`\n⏰ [HORLOGE] L'heure a sonné ! Prédication trouvée : "${sermonAEnvoyer.titre}"`);

      // Pas de modification ici : on passe le statut à "en_cours" pour éviter les doublons
      sermonAEnvoyer.statut = 'en_cours';
      await sermonAEnvoyer.save();

      // 2. Récupérer tous les fidèles qui ont activé le mode "Maranatha"
      const fideles = await User.find({ modeMaranathaActif: true, role: 'fidele' });
      
      if (fideles.length === 0) {
        console.log("[HORLOGE] Aucun fidèle disponible avec le mode Maranatha actif.");
        sermonAEnvoyer.statut = 'termine';
        await sermonAEnvoyer.save();
        return;
      }

      console.log(`[HORLOGE] Envoi du signal de réveil à ${fideles.length} fidèles...`);

      // 3. Boucler sur les jetons des fidèles (Ici on simulera l'envoi Firebase)
      fideles.forEach(fidele => {
        console.log(`🚀 [SIGNAL ENVOYÉ] Mobile de ${fidele.nom} réveillé ! Lecture de l'audio : ${sermonAEnvoyer.audioUrl}`);
      });

      // Une fois le signal envoyé, on marque la prédication comme terminée
      sermonAEnvoyer.statut = 'termine';
      await sermonAEnvoyer.save();
      console.log(`[HORLOGE] Diffusion de la prédication "${sermonAEnvoyer.titre}" terminée avec succès.\n`);
    }

  } catch (error) {
    console.error("Erreur dans le planificateur automatique :", error);
  }
});