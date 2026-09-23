const mongoose = require('mongoose');
const commentSchema =
  new mongoose.Schema(
    {
      texte: {
        type: String,
        required: true,
        trim: true,
        maxlength: 1000,
      },
      type: {
        type: String,
        enum: [
          'commentaire',
          'suggestion',
        ],
        default: 'commentaire',
      },
      section: {
        type: String,
        enum: [
          'communaute',
          'parole',
          'livre',
        ],
        default: 'communaute',
        index: true,
      },
      auteur: {
        type: String,
        default: '',
        trim: true,
        maxlength: 150,
      },
      publicationId: {
        type: String,
        default: '',
        trim: true,
        maxlength: 220,
        index: true,
      },
      publicationTitre: {
        type: String,
        default: '',
        trim: true,
        maxlength: 220,
      },
      publicationDate: {
        type: Date,
        default: null,
      },
      periode: {
        type: String,
        enum: [
          '',
          'matin',
          'soir',
        ],
        default: '',
      },
      dateEnvoi: {
        type: Date,
        default: Date.now,
        index: true,
      },
      adminReponse: {
        type: String,
        default: '',
        trim: true,
        maxlength: 3000,
      },
      dateReponse: {
        type: Date,
        default: null,
      },
      traite: {
        type: Boolean,
        default: false,
        index: true,
      },
    },
    {
      minimize: false,
    }
  );
commentSchema.index({
  section: 1,
  publicationId: 1,
  dateEnvoi: -1,
});
module.exports =
  mongoose.models.Comment ||
  mongoose.model(
    'Comment',
    commentSchema
  );