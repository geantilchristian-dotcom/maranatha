const path = require('path');
const cloudinary = require('cloudinary').v2;

let configured = false;

function getCloudinary() {
  if (!configured) {
    const cloudName = String(process.env.CLOUDINARY_CLOUD_NAME || '').trim();
    const apiKey = String(process.env.CLOUDINARY_API_KEY || '').trim();
    const apiSecret = String(process.env.CLOUDINARY_API_SECRET || '').trim();

    if (!cloudName || !apiKey || !apiSecret) {
      throw new Error('Variables Cloudinary manquantes sur le serveur');
    }

    cloudinary.config({
      cloud_name: cloudName,
      api_key: apiKey,
      api_secret: apiSecret,
      secure: true,
    });
    configured = true;
  }

  return cloudinary;
}

function safeBaseName(originalName, fallback = 'fichier') {
  const extension = path.extname(originalName || '').toLowerCase();
  const base = path.parse(originalName || fallback).name;
  const cleaned =
    base
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-zA-Z0-9_-]/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 80) || fallback;

  return { cleaned, extension };
}

function uploadBuffer(buffer, originalName, options = {}) {
  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new Error('Le fichier est vide');
  }

  const cld = getCloudinary();
  const resourceType = options.resourceType || 'image';
  const folder = options.folder || 'maranatha/media';
  const { cleaned, extension } = safeBaseName(originalName, 'media');
  const rawExtension = resourceType === 'raw' ? extension : '';
  const publicId = `${folder}/${Date.now()}_${cleaned}${rawExtension}`;

  return new Promise((resolve, reject) => {
    const stream = cld.uploader.upload_stream(
      {
        resource_type: resourceType,
        type: 'upload',
        public_id: publicId,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          console.error('[Cloudinary/media]', error.message || error);
          return reject(new Error('Téléversement du fichier impossible'));
        }

        if (!result?.secure_url) {
          return reject(new Error('Cloudinary n’a pas retourné l’adresse du fichier'));
        }

        return resolve({
          url: result.secure_url,
          publicId: result.public_id || '',
          resourceType,
          bytes: Number(result.bytes) || buffer.length,
          width: Number(result.width) || 0,
          height: Number(result.height) || 0,
          durationSeconds: Math.max(0, Math.ceil(Number(result.duration) || 0)),
          originalName: String(originalName || '').slice(0, 180),
        });
      },
    );

    stream.end(buffer);
  });
}

function uploadImage(buffer, originalName, folder = 'maranatha/images') {
  return uploadBuffer(buffer, originalName, {
    resourceType: 'image',
    folder,
  });
}

function uploadLibraryAsset(buffer, originalName, kind) {
  const type = String(kind || '').toLowerCase();
  const map = {
    photo: { resourceType: 'image', folder: 'maranatha/bibliotheque/photos' },
    video: { resourceType: 'video', folder: 'maranatha/bibliotheque/videos' },
    audio: { resourceType: 'video', folder: 'maranatha/bibliotheque/audios' },
    book: { resourceType: 'raw', folder: 'maranatha/bibliotheque/livres' },
    pdf: { resourceType: 'raw', folder: 'maranatha/etudes' },
  };

  const options = map[type];
  if (!options) throw new Error('Type de fichier non pris en charge');
  return uploadBuffer(buffer, originalName, options);
}

module.exports = {
  uploadBuffer,
  uploadImage,
  uploadLibraryAsset,
};
