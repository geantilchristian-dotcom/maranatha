const express = require('express');
const mongoose = require('mongoose');
const Comment = require('../models/Comment');
const adminOnly = require('../utils/adminAuth');
const {
  cleanText,
  createRateLimiter,
} = require('../utils/security');
const router =
  express.Router();
const commentLimiter =
  createRateLimiter({
    windowMs:
      10 * 60 * 1000,
    max:
      35,
    keyPrefix:
      'comments',
  });
// ============================================================
// GET
// ============================================================
router.get(
  '/',
  async (req, res) => {
    try {
      const filter = {};
      const section =
        cleanText(
          req.query.section,
          30
        );
      if (
        [
          'communaute',
          'parole',
          'livre',
        ].includes(section)
      ) {
        filter.section =
          section;
      }
      const publicationId =
        cleanText(
          req.query.publicationId,
          220
        );
      if (publicationId) {
        filter.publicationId =
          publicationId;
      }
      if (
        String(
          req.query.nonTraite || ''
        ) === '1'
      ) {
        filter.traite =
          false;
      }
      const comments =
        await Comment
          .find(filter)
          .sort({
            dateEnvoi: -1,
          })
          .limit(200)
          .lean();
      return res.json(
        comments
      );
    } catch (error) {
      console.error(
        '[comments/get]',
        error.message
      );
      return res
        .status(500)
        .json({
          error:
            'Commentaires temporairement indisponibles',
        });
    }
  }
);
// ============================================================
// POST
// ============================================================
router.post(
  '/',
  commentLimiter,
  async (req, res) => {
    try {
      const texte =
        cleanText(
          req.body?.texte,
          1000
        );
      if (!texte) {
        return res
          .status(400)
          .json({
            error:
              'Texte requis',
          });
      }
      const section =
        [
          'communaute',
          'parole',
          'livre',
        ].includes(
          req.body?.section
        )
          ? req.body.section
          : 'communaute';
      const periode =
        [
          'matin',
          'soir',
        ].includes(
          req.body?.periode
        )
          ? req.body.periode
          : '';
      let publicationDate =
        null;
      if (
        req.body?.publicationDate
      ) {
        const parsed =
          new Date(
            req.body.publicationDate
          );
        if (
          !Number.isNaN(
            parsed.getTime()
          )
        ) {
          publicationDate =
            parsed;
        }
      }
      const comment =
        await Comment.create({
          texte,
          type:
            [
              'commentaire',
              'suggestion',
            ].includes(
              req.body?.type
            )
              ? req.body.type
              : 'commentaire',
          section,
          auteur:
            cleanText(
              req.body?.auteur,
              150
            ),
          publicationId:
            cleanText(
              req.body?.publicationId,
              220
            ),
          publicationTitre:
            cleanText(
              req.body?.publicationTitre,
              220
            ),
          publicationDate,
          periode,
          traite:
            false,
        });
      return res
        .status(201)
        .json(
          comment
        );
    } catch (error) {
      console.error(
        '[comments/post]',
        error.message
      );
      return res
        .status(400)
        .json({
          error:
            'Envoi du commentaire impossible',
        });
    }
  }
);
// ============================================================
// REPONSE ADMIN
// ============================================================
router.patch(
  '/:id/reply',
  adminOnly,
  async (req, res) => {
    try {
      if (
        !mongoose.isValidObjectId(
          req.params.id
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              'Identifiant invalide',
          });
      }
      const reponse =
        cleanText(
          req.body?.reponse,
          3000
        );
      const comment =
        await Comment.findByIdAndUpdate(
          req.params.id,
          {
            $set: {
              adminReponse:
                reponse,
              dateReponse:
                reponse
                  ? new Date()
                  : null,
              traite:
                Boolean(reponse),
            },
          },
          {
            new: true,
            runValidators: true,
          }
        );
      if (!comment) {
        return res
          .status(404)
          .json({
            error:
              'Commentaire introuvable',
          });
      }
      return res.json(
        comment
      );
    } catch (error) {
      return res
        .status(400)
        .json({
          error:
            'Réponse impossible',
        });
    }
  }
);
// ============================================================
// TRAITE / NON TRAITE
// ============================================================
router.patch(
  '/:id/status',
  adminOnly,
  async (req, res) => {
    try {
      if (
        !mongoose.isValidObjectId(
          req.params.id
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              'Identifiant invalide',
          });
      }
      const comment =
        await Comment.findByIdAndUpdate(
          req.params.id,
          {
            $set: {
              traite:
                req.body?.traite === true,
            },
          },
          {
            new: true,
          }
        );
      if (!comment) {
        return res
          .status(404)
          .json({
            error:
              'Commentaire introuvable',
          });
      }
      return res.json(
        comment
      );
    } catch (error) {
      return res
        .status(400)
        .json({
          error:
            'Modification impossible',
        });
    }
  }
);
// ============================================================
// DELETE
// ============================================================
router.delete(
  '/:id',
  adminOnly,
  async (req, res) => {
    try {
      if (
        !mongoose.isValidObjectId(
          req.params.id
        )
      ) {
        return res
          .status(400)
          .json({
            error:
              'Identifiant invalide',
          });
      }
      const comment =
        await Comment.findByIdAndDelete(
          req.params.id
        );
      if (!comment) {
        return res
          .status(404)
          .json({
            error:
              'Commentaire introuvable',
          });
      }
      return res.json({
        ok: true,
      });
    } catch (error) {
      return res
        .status(500)
        .json({
          error:
            'Suppression impossible',
        });
    }
  }
);
module.exports =
  router;