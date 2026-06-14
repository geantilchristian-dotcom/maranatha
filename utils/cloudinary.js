const cloudinary = require('cloudinary').v2;

let configured = false;

function getCloudinary() {
  if (!configured) {
    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      throw new Error("Variables Cloudinary manquantes sur le serveur");
    }
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key:    process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
      secure:     true,
    });
    configured = true;
    console.log("Cloudinary configure : " + process.env.CLOUDINARY_CLOUD_NAME);
  }
  return cloudinary;
}

/**
 * Upload un buffer audio vers Cloudinary
 * @param {Buffer} buffer  - Contenu binaire du fichier
 * @param {string} originalName - Nom original
 * @returns {string} URL permanente publique
 */
async function uploadAudio(buffer, originalName) {
  const cld = getCloudinary();

  // Nom unique — caracteres speciaux remplaces
  const safe = originalName.replace(/[^a-zA-Z0-9._-]/g, '_');
  const publicId = 'maranatha/predications/' + Date.now() + '_' + safe;

  return new Promise((resolve, reject) => {
    const stream = cld.uploader.upload_stream(
      {
        resource_type: 'video',   // Cloudinary classe l'audio sous "video"
        public_id:     publicId,
        overwrite:     false,
        // Pas de format — on stocke tel quel, pas de transcodage
      },
      (error, result) => {
        if (error) {
          console.error("Erreur Cloudinary:", error.message || error);
          return reject(new Error("Echec upload Cloudinary : " + (error.message || JSON.stringify(error))));
        }
        console.log("Audio stocke :", result.secure_url);
        resolve(result.secure_url);
      }
    );

    stream.end(buffer);
  });
}

module.exports = { uploadAudio };
