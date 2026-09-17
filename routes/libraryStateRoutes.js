const express = require("express");
const multer = require("multer");
const LibraryState =
  require("../models/LibraryState");
const adminOnly =
  require("../utils/adminAuth");
const {
  uploadFile,
} = require("../utils/cloudinary");
const router =
  express.Router();
/* ==========================================================
   ETAT PUBLIC DE LA BIBLIOTHEQUE
   ========================================================== */
router.get(
  "/state",
  async (_req, res) => {
    try {
      const state =
        await LibraryState.findOne({
          key: "main",
        }).lean();
      return res.json({
        value:
          state
            ? state.value
            : { recent: [], live: [], audio: [], video: [], book: [] },
        updatedAt:
          state
            ? state.updatedAt
            : null,
      });
    } catch (error) {
      console.error(
        "[LIBRARY STATE GET]",
        error
      );
      return res
        .status(500)
        .json({
          error:
            "Impossible de charger la bibliothÃ¨que.",
        });
    }
  }
);
/* ==========================================================
   ENREGISTREMENT ADMIN
   ========================================================== */
router.put(
  "/state",
  adminOnly,
  async (req, res) => {
    try {
      if (
        !Object.prototype.hasOwnProperty.call(
          req.body || {},
          "value"
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              "DonnÃ©es de bibliothÃ¨que absentes.",
          });
      }
      const value =
        req.body.value;
      const serialized =
        JSON.stringify(value);
      if (
        serialized.length >
        2 * 1024 * 1024
      ) {
        return res
          .status(413)
          .json({
            error:
              "La bibliothÃ¨que est trop volumineuse.",
          });
      }
      const state =
        await LibraryState.findOneAndUpdate(
          {
            key: "main",
          },
          {
            $set: {
              value,
              updatedAt:
                new Date(),
            },
          },
          {
            new: true,
            upsert: true,
            setDefaultsOnInsert: true,
          }
        ).lean();
      return res.json({
        ok: true,
        value:
          state.value,
        updatedAt:
          state.updatedAt,
      });
    } catch (error) {
      console.error(
        "[LIBRARY STATE PUT]",
        error
      );
      return res
        .status(500)
        .json({
          error:
            "Impossible d'enregistrer la bibliothÃ¨que.",
        });
    }
  }
);
/* ==========================================================
   UPLOAD CLOUDINARY
   ========================================================== */
const upload =
  multer({
    storage:
      multer.memoryStorage(),
    limits: {
      fileSize:
        30 * 1024 * 1024,
    },
    fileFilter:
      (_req, file, callback) => {
        const type =
          String(
            file &&
            file.mimetype ||
            ""
          );
        const allowed =
          type.startsWith("image/") ||
          type.startsWith("audio/") ||
          type.startsWith("video/") ||
          type === "application/pdf";
        callback(
          allowed
            ? null
            : new Error(
                "Type de fichier non autorisÃ©."
              ),
          allowed
        );
      },
  });
function uploadParser(
  req,
  res,
  next
) {
  const contentType =
    String(
      req.headers["content-type"] ||
      ""
    );
  /*
   * Support FormData.
   */
  if (
    contentType.includes(
      "multipart/form-data"
    )
  ) {
    return upload.single(
      "file"
    )(
      req,
      res,
      error => {
        if(error){
          return res
            .status(400)
            .json({
              ok: false,
              error:
                error.message ||
                "Fichier invalide.",
            });
        }
        next();
      }
    );
  }
  /*
   * CompatibilitÃ© avec l'ancienne interface
   * qui envoyait directement le fichier brut.
   */
  return express.raw({
    type: () => true,
    limit: "30mb",
  })(
    req,
    res,
    next
  );
}
router.post(
  "/upload",
  adminOnly,
  uploadParser,
  async (req, res) => {
    try {
      let buffer =
        null;
      let originalName =
        "fichier";
      let mimetype =
        String(
          req.headers["content-type"] ||
          "application/octet-stream"
        );
      if(req.file){
        buffer =
          req.file.buffer;
        originalName =
          req.file.originalname ||
          originalName;
        mimetype =
          req.file.mimetype ||
          mimetype;
      }else if(
        Buffer.isBuffer(
          req.body
        )
      ){
        buffer =
          req.body;
        const encoded =
          String(
            req.headers["x-file-name"] ||
            "fichier"
          );
        try {
          originalName =
            decodeURIComponent(
              encoded
            );
        } catch (_error) {
          originalName =
            encoded;
        }
      }
      if(
        !buffer ||
        !buffer.length
      ){
        return res
          .status(400)
          .json({
            ok: false,
            error:
              "Aucun fichier reÃ§u.",
          });
      }
      const url =
        await uploadFile(
          buffer,
          originalName,
          mimetype
        );
      return res.json({
        ok: true,
        success: true,
        url,
        secureUrl: url,
      });
    } catch (error) {
      console.error(
        "[LIBRARY UPLOAD]",
        error
      );
      return res
        .status(500)
        .json({
          ok: false,
          error:
            error.message ||
            "TÃ©lÃ©versement impossible.",
        });
    }
  }
);

/* ==========================================================
   MARANATHA_LIBRARY_PDF_READER_ROUTE_V1
   Lecture PDF Cloudinary en mode inline
   ========================================================== */

router.get("/read-pdf", async (req, res) => {
  try {
    const rawUrl = String(req.query.url || "").trim();

    if (!rawUrl) {
      return res.status(400).json({
        ok: false,
        error: "URL PDF manquante."
      });
    }

    let parsed;

    try {
      parsed = new URL(rawUrl);
    } catch (_error) {
      return res.status(400).json({
        ok: false,
        error: "URL PDF invalide."
      });
    }

    if (
      parsed.protocol !== "https:" ||
      parsed.hostname !== "res.cloudinary.com"
    ) {
      return res.status(403).json({
        ok: false,
        error: "Source PDF non autorisee."
      });
    }

    const response = await fetch(rawUrl, {
      method: "GET",
      redirect: "follow"
    });

    if (!response.ok) {
      return res.status(502).json({
        ok: false,
        error: "Impossible de recuperer le PDF.",
        status: response.status
      });
    }

    const contentType =
      String(response.headers.get("content-type") || "")
        .toLowerCase();

    if (
      contentType &&
      !contentType.includes("application/pdf") &&
      !contentType.includes("application/octet-stream")
    ) {
      return res.status(415).json({
        ok: false,
        error: "La ressource recue n est pas un PDF."
      });
    }

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", 'inline; filename="maranatha-livre.pdf"');
    res.setHeader("X-Content-Type-Options", "nosniff");
    res.setHeader("Cache-Control", "private, max-age=300");

    const arrayBuffer = await response.arrayBuffer();
    const pdfBuffer = Buffer.from(arrayBuffer);

    res.setHeader("Content-Length", String(pdfBuffer.length));

    return res.send(pdfBuffer);

  } catch (error) {
    console.error("[LIBRARY PDF READER]", error);

    if (res.headersSent) {
      return;
    }

    return res.status(500).json({
      ok: false,
      error: "Lecture du PDF impossible."
    });
  }
});

/* MARANATHA_LIBRARY_PDF_READER_ROUTE_V1_END */

module.exports =
  router;
