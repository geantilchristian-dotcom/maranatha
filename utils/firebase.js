let admin = null;

try {
  admin = require('firebase-admin');
} catch (error) {
  console.warn(
    '[Firebase] firebase-admin non disponible, notifications désactivées :',
    error.message,
  );
}

let firebaseApp;

function getFirebaseApp() {
  if (!admin) {
    throw new Error('firebase-admin non chargé');
  }

  if (firebaseApp) {
    return firebaseApp;
  }

  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!rawServiceAccount) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT manquant dans les variables d'environnement",
    );
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(rawServiceAccount);
  } catch (_error) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT contient un JSON invalide');
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log('[Firebase] Admin SDK initialisé');
  return firebaseApp;
}

function normaliserTokens(tokens) {
  return [...new Set((tokens || []).map(String).map((token) => token.trim()))]
    .filter(Boolean);
}

function decouper(tableau, taille) {
  const morceaux = [];
  for (let index = 0; index < tableau.length; index += taille) {
    morceaux.push(tableau.slice(index, index + taille));
  }
  return morceaux;
}

function transformerDonnees(data) {
  return Object.fromEntries(
    Object.entries(data).map(([cle, valeur]) => [
      cle,
      valeur === null || valeur === undefined ? '' : String(valeur),
    ]),
  );
}

async function envoyerDonneesMasse(tokens, data, options = {}) {
  const tokensUniques = normaliserTokens(tokens);

  if (tokensUniques.length === 0) {
    return {
      successCount: 0,
      failureCount: 0,
      tokensEchoues: [],
    };
  }

  const app = getFirebaseApp();
  const messaging = admin.messaging(app);
  const lots = decouper(tokensUniques, 500);

  let successCount = 0;
  let failureCount = 0;
  const tokensEchoues = [];

  for (const lot of lots) {
    const response = await messaging.sendEachForMulticast({
      tokens: lot,
      data: transformerDonnees(data),
      android: {
        priority: 'high',
        ttl: options.ttl || 28 * 24 * 60 * 60 * 1000,
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'background',
        },
        payload: {
          aps: {
            'content-available': 1,
          },
        },
      },
    });

    successCount += response.successCount;
    failureCount += response.failureCount;

    response.responses.forEach((item, index) => {
      if (!item.success) {
        tokensEchoues.push({
          token: lot[index],
          erreur: item.error?.code || 'firebase/inconnu',
        });
      }
    });
  }

  return {
    successCount,
    failureCount,
    tokensEchoues,
  };
}

async function envoyerProgrammationMasse(tokens, sermon) {
  return envoyerDonneesMasse(tokens, {
    type: 'PROGRAMMER_PREDICATION',
    sermon_id: sermon._id.toString(),
    sermon_titre: sermon.titre,
    audio_url: sermon.audioUrl,
    scheduled_at_ms: new Date(sermon.dateDiffusion).getTime(),
  });
}

async function envoyerAnnulationMasse(tokens, sermonId) {
  return envoyerDonneesMasse(tokens, {
    type: 'ANNULER_PREDICATION',
    sermon_id: sermonId.toString(),
  });
}

async function envoyerDemarrageMasse(tokens, sermon) {
  return envoyerDonneesMasse(
    tokens,
    {
      type: 'DEMARRER_PREDICATION',
      sermon_id: sermon._id.toString(),
      sermon_titre: sermon.titre,
      audio_url: sermon.audioUrl,
      scheduled_at_ms: new Date(sermon.dateDiffusion).getTime(),
    },
    { ttl: 3 * 60 * 60 * 1000 },
  );
}

async function envoyerArretMasse(tokens, sermonId) {
  return envoyerDonneesMasse(
    tokens,
    {
      type: 'ARRETER_PREDICATION',
      sermon_id: sermonId.toString(),
    },
    { ttl: 15 * 60 * 1000 },
  );
}

module.exports = {
  envoyerProgrammationMasse,
  envoyerAnnulationMasse,
  envoyerArretMasse,
  envoyerDemarrageMasse,
};
