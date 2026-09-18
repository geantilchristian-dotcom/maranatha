const { envoyerPublicationNouvelleMasse } = require('./firebase');
const { obtenirTokensRecents } = require('./deviceTokens');

/**
 * Envoie une notification de publication et retourne un résultat sans faire
 * échouer l'enregistrement du contenu si Firebase est indisponible.
 */
async function notifierPublicationNouvelle(publicationType, publication) {
  const id = publication?._id?.toString();
  const titre = publication?.titre;
  if (!id || !titre) {
    console.warn('[PublicationNotification] contenu ignoré: identifiant ou titre manquant');
    return {
      ok: false,
      successCount: 0,
      failureCount: 0,
      tokenCount: 0,
      error: 'Identifiant ou titre manquant',
    };
  }

  try {
    const tokens = await obtenirTokensRecents();
    if (tokens.length === 0) {
      console.warn(
        `[PublicationNotification] ${publicationType}/${id}: aucun appareil récent enregistré`,
      );
      return {
        ok: false,
        successCount: 0,
        failureCount: 0,
        tokenCount: 0,
        error: 'Aucun appareil récent enregistré',
      };
    }

    const resultat = await envoyerPublicationNouvelleMasse(tokens, {
      type: publicationType,
      id,
      titre,
    });
    console.log(
      `[PublicationNotification] ${publicationType}/${id}: ${resultat.successCount} envoyé(s), ${resultat.failureCount} échec(s)`,
    );
    return {
      ok: resultat.successCount > 0,
      successCount: resultat.successCount,
      failureCount: resultat.failureCount,
      tokenCount: tokens.length,
      error:
        resultat.successCount > 0
          ? null
          : 'Firebase a refusé tous les appareils enregistrés',
    };
  } catch (error) {
    console.warn(
      `[PublicationNotification] ${publicationType}/${id} indisponible:`,
      error.message,
    );
    return {
      ok: false,
      successCount: 0,
      failureCount: 0,
      tokenCount: 0,
      error: error.message,
    };
  }
}

module.exports = { notifierPublicationNouvelle };