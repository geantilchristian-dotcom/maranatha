const admin = require('firebase-admin');

let firebaseApp;

function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT manquant dans les variables d'environnement");
  }

  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: 'invisible-light-c792e.firebasestorage.app',
  });

  console.log("✅ Firebase Admin SDK initialisé (Messaging + Storage)");
  return firebaseApp;
}

/**
 * Upload un fichier audio vers Firebase Storage
 * @param {Buffer} buffer - Contenu binaire du fichier
 * @param {string} originalName - Nom original du fichier (ex: sermon.mp3)
 * @param {string} mimeType - Type MIME (audio/mpeg, audio/mp3…)
 * @returns {string} URL publique du fichier uploadé
 */
async function uploadAudioVersStorage(buffer, originalName, mimeType) {
  const app = getFirebaseApp();
  const bucket = admin.storage(app).bucket();

  // Nom unique horodaté pour éviter les collisions
  const timestamp = Date.now();
  const ext = originalName.split('.').pop() || 'mp3';
  const nomFichier = `predications/${timestamp}_${originalName.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

  const file = bucket.file(nomFichier);

  await file.save(buffer, {
    metadata: {
      contentType: mimeType || 'audio/mpeg',
      cacheControl: 'public, max-age=31536000',
    },
  });

  // Rendre le fichier public
  await file.makePublic();

  // URL publique stable
  const publicUrl = `https://storage.googleapis.com/${bucket.name}/${nomFichier}`;
  console.log(`✅ Audio uploadé : ${publicUrl}`);
  return publicUrl;
}

/**
 * Envoie une notification push à TOUS les fidèles
 */
async function envoyerNotificationMasse(tokens, sermon) {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0, tokensEchoues: [] };

  const app = getFirebaseApp();
  const messaging = admin.messaging(app);

  const message = {
    tokens,
    notification: {
      title: "⛪ Maranatha — Prédication en direct !",
      body: sermon.titre,
    },
    data: {
      sermon_id: sermon._id.toString(),
      sermon_titre: sermon.titre,
      audio_url: sermon.audioUrl,
      type: "PREDICATION_DIRECTE",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "maranatha_predication",
        priority: "max",
        defaultSound: false,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: { title: "⛪ Maranatha — Prédication en direct !", body: sermon.titre },
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
      headers: { "apns-priority": "10" },
    },
  };

  const response = await messaging.sendEachForMulticast(message);
  console.log(`📊 Résultat : ${response.successCount} succès, ${response.failureCount} échecs`);

  const tokensEchoues = [];
  response.responses.forEach((resp, index) => {
    if (!resp.success) tokensEchoues.push({ token: tokens[index], erreur: resp.error?.code });
  });

  return { successCount: response.successCount, failureCount: response.failureCount, tokensEchoues };
}

module.exports = { envoyerNotificationMasse, uploadAudioVersStorage };
