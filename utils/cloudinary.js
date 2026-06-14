const cloudinary = require('cloudinary').v2;

let configured = false;

function getCloudinary() {
  if (!configured) {
    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      throw new Error("Variables Cloudinary manquantes : CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET");
    }
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key:    process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
      secure: true,
    });
    configured = true;
    console.log("Cloudinary configure : cloud=" + process.env.CLOUDINARY_CLOUD_NAME);
  }
  return cloudinary;
}

/**
 * Upload un buffer audio vers Cloudinary
 * @param {Buffer} buffer - Contenu binaire du fichier
 * @param {string} originalName - Nom original du fichier
 * @returns {string} URL publique permanente
 */
async function uploadAudio(buffer, originalName) {
  const cld = getCloudinary();

  const nomFichier = 'predications/' + Date.now() + '_' + originalName.replace(/[^a-zA-Z0-9._-]/g, '_').replace(/\.[^/.]+$/, '');

  return new Promise((resolve, reject) => {
    const stream = cld.uploader.upload_stream(
      {
        resource_type: 'video', // Cloudinary classe audio sous "video"
        public_id: nomFichier,
        folder: 'maranatha',
        overwrite: false,
        format: 'mp3',
      },
      (error, result) => {
        if (error) {
          console.error("Erreur Cloudinary:", error);
          return reject(new Error("Echec upload Cloudinary : " + error.message));
        }
        console.log("Audio uploade : " + result.secure_url);
        resolve(result.secure_url);
      }
    );
    stream.end(buffer);
  });
}

module.exports = { uploadAudio };
