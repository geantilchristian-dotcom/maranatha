const admin = require('firebase-admin');

let firebaseApp;

function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT manquant dans le fichier .env"
    );
  }

  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log("✅ Firebase Admin SDK initialisé avec succès");
  return firebaseApp;
}

/**
 * Envoie une notification push à TOUS les fidèles en une seule requête Firebase
 * @param {string[]} tokens - Liste des tokens FCM des fidèles
 * @param {object} sermon - L'objet sermon (titre, audioUrl, _id)
 */
async function envoyerNotificationMasse(tokens, sermon) {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0, tokensEchoues: [] };

  const app = getFirebaseApp();
  const messaging = admin.messaging(app);

  const message = {
    tokens: tokens,
    // Notification visible dans la barre de statut du téléphone
    notification: {
      title: "⛪ Maranatha — Prédication en direct !",
      body: sermon.titre,
    },
    // Données silencieuses transmises à l'application Flutter pour lancer l'audio
    data: {
      sermon_id: sermon._id.toString(),
      sermon_titre: sermon.titre,
      audio_url: sermon.audioUrl,
      type: "PREDICATION_DIRECTE",
    },
    // Android : priorité maximale pour déclencher comme une alarme
    android: {
      priority: "high",
      notification: {
        channelId: "maranatha_predication",
        priority: "max",
        defaultSound: false,
      },
    },
    // iOS
    apns: {
      payload: {
        aps: {
          alert: {
            title: "⛪ Maranatha — Prédication en direct !",
            body: sermon.titre,
          },
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
      headers: { "apns-priority": "10" },
    },
  };

  const response = await messaging.sendEachForMulticast(message);

  console.log(
    `📊 Résultat : ${response.successCount} succès, ${response.failureCount} échecs`
  );

  const tokensEchoues = [];
  response.responses.forEach((resp, index) => {
    if (!resp.success) {
      tokensEchoues.push({ token: tokens[index], erreur: resp.error?.code });
    }
  });

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    tokensEchoues,
  };
}

module.exports = { envoyerNotificationMasse };
