const path = require('path');
const cloudinary = require('cloudinary').v2;

let configured = false;

function getCloudinary() {
  if (!configured) {
    const cloudName = String(
      process.env.CLOUDINARY_CLOUD_NAME || '',
    ).trim();

    const apiKey = String(
      process.env.CLOUDINARY_API_KEY || '',
    ).trim();

    const apiSecret = String(
      process.env.CLOUDINARY_API_SECRET || '',
    ).trim();

    if (!cloudName || !apiKey || !apiSecret) {
      throw new Error(
        'Variables Cloudinary manquantes sur le serveur',
      );
    }

    cloudinary.config({
      cloud_name: cloudName,
      api_key: apiKey,
      api_secret: apiSecret,
      secure: true,
    });

    configured = true;

    console.log(
      `[Cloudinary] connecté au nuage ${cloudName}`,
    );
  }

  return cloudinary;
}

function nettoyerNom(originalName) {
  const nomSansExtension = path
    .parse(originalName || 'predication')
    .name;

  const nomPropre = nomSansExtension
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9_-]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 80);

  return nomPropre || 'predication';
}

async function uploadAudio(buffer, originalName) {
  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new Error('Le fichier audio est vide');
  }

  const cld = getCloudinary();

  const publicId =
    `maranatha/predications/` +
    `${Date.now()}_${nettoyerNom(originalName)}`;

  return new Promise((resolve, reject) => {
    const stream = cld.uploader.upload_stream(
      {
        resource_type: 'video',
        type: 'upload',
        public_id: publicId,
        overwrite: false,

        allowed_formats: [
          'mp3',
          'm4a',
          'wav',
          'ogg',
          'aac',
          'mp4',
        ],

        // Préparer immédiatement une version MP3
        // compatible avec Android et les navigateurs.
        eager: [
          {
            format: 'mp3',
          },
        ],

        eager_async: false,
      },
      (error, result) => {
        if (error) {
          console.error(
            '[Cloudinary/upload]',
            error.message || error,
          );

          reject(
            new Error(
              `Échec upload Cloudinary : ${
                error.message || 'erreur inconnue'
              }`,
            ),
          );

          return;
        }

        if (!result?.public_id || !result?.version) {
          reject(
            new Error(
              'Cloudinary n’a pas retourné une adresse valide',
            ),
          );

          return;
        }

        const urlTransformee =
          Array.isArray(result.eager) &&
          result.eager[0]?.secure_url
            ? result.eager[0].secure_url
            : cld.url(result.public_id, {
                resource_type: 'video',
                type: 'upload',
                secure: true,
                version: result.version,
                format: 'mp3',
              });

        console.log(
          '[Cloudinary/audio prêt]',
          urlTransformee,
        );

        resolve(urlTransformee);
      },
    );

    stream.end(buffer);
  });
}

module.exports = {
  uploadAudio,
};