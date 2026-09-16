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
    console.log(`[Cloudinary] connecté au nuage ${cloudName}`);
  }

  return cloudinary;
}

function nettoyerNom(originalName) {
  const nomSansExtension = path.parse(originalName || 'predication').name;

  return (
    nomSansExtension
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-zA-Z0-9_-]/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 80) || 'predication'
  );
}

async function uploadAudio(buffer, originalName) {
  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new Error('Le fichier audio est vide');
  }

  const cld = getCloudinary();
  const publicId =
    `maranatha/predications/${Date.now()}_${nettoyerNom(originalName)}`;

  return new Promise((resolve, reject) => {
    const stream = cld.uploader.upload_stream(
      {
        resource_type: 'video',
        type: 'upload',
        public_id: publicId,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          console.error('[Cloudinary/upload]', error.message || error);
          reject(
            new Error(
              `Échec upload Cloudinary : ${error.message || 'erreur inconnue'}`,
            ),
          );
          return;
        }

        if (!result?.secure_url) {
          reject(new Error('Cloudinary n’a pas retourné une adresse audio'));
          return;
        }

        console.log('[Cloudinary/audio prêt]', result.secure_url);
        resolve(result.secure_url);
      },
    );

    stream.end(buffer);
  });
}



/* ==========================================================
   MARANATHA_PROGRAMME_IMAGE_UPLOAD_V1
   ========================================================== */

async function uploadImage(
  buffer,
  originalName
) {

  if (
    !Buffer.isBuffer(buffer) ||
    buffer.length === 0
  ) {
    throw new Error(
      "L'image est vide"
    );
  }


  const cld =
    getCloudinary();


  const publicId =
    "maranatha/programmes/" +
    Date.now() +
    "_" +
    nettoyerNom(
      originalName ||
      "programme"
    );


  return new Promise(
    (resolve, reject) => {

      const stream =
        cld.uploader.upload_stream(
          {
            resource_type:
              "image",

            type:
              "upload",

            public_id:
              publicId,

            overwrite:
              false
          },

          (error, result) => {

            if (error) {

              console.error(
                "[Cloudinary/programme]",
                error.message ||
                error
              );

              reject(
                new Error(
                  "Echec upload image Cloudinary : " +
                  (
                    error.message ||
                    "erreur inconnue"
                  )
                )
              );

              return;
            }


            if (
              !result ||
              !result.secure_url
            ) {

              reject(
                new Error(
                  "Cloudinary n'a pas retourne d'adresse image"
                )
              );

              return;
            }


            console.log(
              "[Cloudinary/programme pret]",
              result.secure_url
            );


            resolve(
              result.secure_url
            );
          }
        );


      stream.end(
        buffer
      );
    }
  );
}

/* MARANATHA_PROGRAMME_IMAGE_UPLOAD_V1_END */



/* ==========================================================
   MARANATHA_LIBRARY_CLOUDINARY_V1
   ========================================================== */
async function uploadFile(
  buffer,
  originalName,
  mimetype
) {
  if (
    !Buffer.isBuffer(buffer) ||
    buffer.length === 0
  ) {
    throw new Error(
      "Le fichier est vide."
    );
  }
  const cld =
    getCloudinary();
  const options = {
    resource_type:
      "auto",
    folder:
      "maranatha/library",
    use_filename:
      true,
    unique_filename:
      true,
    overwrite:
      false,
  };
  if (
    String(mimetype || "") ===
    "application/pdf"
  ) {
    options.resource_type =
      "raw";
  }
  return new Promise(
    (resolve, reject) => {
      const stream =
        cld.uploader.upload_stream(
          options,
          (error, result) => {
            if(error){
              console.error(
                "[Cloudinary/library]",
                error.message ||
                error
              );
              reject(
                new Error(
                  "Echec upload Cloudinary : " +
                  (
                    error.message ||
                    "erreur inconnue"
                  )
                )
              );
              return;
            }
            if(
              !result ||
              !result.secure_url
            ){
              reject(
                new Error(
                  "Cloudinary n'a pas retourné d'URL."
                )
              );
              return;
            }
            console.log(
              "[Cloudinary/library prêt]",
              result.secure_url
            );
            resolve(
              result.secure_url
            );
          }
        );
      stream.end(
        buffer
      );
    }
  );
}
/* MARANATHA_LIBRARY_CLOUDINARY_V1_END */

module.exports = { uploadAudio, uploadImage, uploadFile };
