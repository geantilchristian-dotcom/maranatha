const { envoyerPublicationNouvelleMasse } = require('./firebase');
const { obtenirTokensRecents } = require('./deviceTokens');

/**
 * Delivers a publication push without making publication requests depend on
 * Firebase or on the device-token database being available.
 */
function notifierPublicationNouvelle(publicationType, publication) {
  const id = publication?._id?.toString();
  const titre = publication?.titre;
  if (!id || !titre) {
    console.warn('[PublicationNotification] contenu ignoré: identifiant ou titre manquant');
    return;
  }

  Promise.resolve()
    .then(async () => {
      const tokens = await obtenirTokensRecents();
      const resultat = await envoyerPublicationNouvelleMasse(tokens, {
        type: publicationType,
        id,
        titre,
      });
      console.log(
        `[PublicationNotification] ${publicationType}/${id}: ${resultat.successCount} envoyé(s), ${resultat.failureCount} échec(s)`,
      );
    })
    .catch((error) => {
      console.warn(
        `[PublicationNotification] ${publicationType}/${id} indisponible:`,
        error.message,
      );
    });
}

module.exports = { notifierPublicationNouvelle };