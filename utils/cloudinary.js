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
    console.log(`[Cloudinary] connectÃ© au nuage ${cloudName}`);
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
        // MARANATHA_AUDIO_TIMEOUT_V1
        timeout: 300000,
        type: 'upload',
        public_id: publicId,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          console.error('[Cloudinary/upload]', error.message || error);
          reject(
            new Error(
              `Ã‰chec upload Cloudinary : ${error.message || 'erreur inconnue'}`,
            ),
          );
          return;
        }

        if (!result?.secure_url) {
          reject(new Error('Cloudinary nâ€™a pas retournÃ© une adresse audio'));
          return;
        }

        console.log('[Cloudinary/audio prÃªt]', result.secure_url);
        resolve({
          url: result.secure_url,
          durationSeconds: Number(result.duration || 0),
        });
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
   MARANATHA_LIBRARY_CLOUDINARY_V2
   Upload robuste + diagnostic réel
   ========================================================== */

async function uploadFile(buffer, originalName, mimetype) {

  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new Error("Le fichier est vide.");
  }

  const cld = getCloudinary();

  const mime = String(mimetype || "").toLowerCase();
  const isPdf = mime === "application/pdf";

  const sizeMB =
    Math.round((buffer.length / 1024 / 1024) * 100) / 100;

  const startedAt = Date.now();

  console.log(
    `[LIBRARY UPLOAD] DEBUT | fichier=${originalName} | type=${mime} | taille=${sizeMB} Mo`
  );

  const options = {
    resource_type: isPdf ? "raw" : "auto",
    folder: "maranatha/library",
    use_filename: true,
    unique_filename: true,
    overwrite: false
  };

  return new Promise((resolve, reject) => {

    let finished = false;

    const fail = (message, error) => {

      if (finished) return;
      finished = true;

      const seconds =
        Math.round(((Date.now() - startedAt) / 1000) * 10) / 10;

      console.error(
        `[LIBRARY UPLOAD] ECHEC | ${seconds}s | ${sizeMB} Mo | ${message}`
      );

      if (error) {
        console.error("[LIBRARY UPLOAD] DETAIL :", {
          message: error.message,
          name: error.name,
          http_code: error.http_code,
          error
        });
      }

      reject(
        new Error(
          `${message} | fichier=${originalName} | taille=${sizeMB} Mo | duree=${seconds}s`
        )
      );
    };

    try {

      console.log(
        `[LIBRARY UPLOAD] CLOUDINARY | resource_type=${options.resource_type}`
      );

      const stream = cld.uploader.upload_stream(
        options,
        (error, result) => {

          if (error) {
            return fail(
              `Cloudinary : ${error.message || "erreur inconnue"}`,
              error
            );
          }

          if (!result || !result.secure_url) {
            return fail(
              "Cloudinary n'a pas retourné d'URL."
            );
          }

          if (finished) return;
          finished = true;

          const seconds =
            Math.round(((Date.now() - startedAt) / 1000) * 10) / 10;

          console.log(
            `[LIBRARY UPLOAD] SUCCES | ${seconds}s | ${sizeMB} Mo`
          );

          console.log(
            "[LIBRARY UPLOAD] URL :",
            result.secure_url
          );

          resolve(result.secure_url);
        }
      );

      stream.on("error", (error) => {
        fail(
          `Erreur du flux Cloudinary : ${error.message || error}`,
          error
        );
      });

      console.log(
        `[LIBRARY UPLOAD] ENVOI BUFFER | ${buffer.length} octets`
      );

      stream.end(buffer);

    } catch (error) {

      fail(
        `Exception avant ou pendant l'upload : ${error.message || error}`,
        error
      );

    }
  });
}

/* MARANATHA_LIBRARY_CLOUDINARY_V2_END */

module.exports = { uploadAudio, uploadImage, uploadFile };

