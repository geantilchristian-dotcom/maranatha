const mongoose = require('mongoose');
const sermonSchema =
  new mongoose.Schema(
    {
      titre: {
        type: String,
        required: true,
        trim: true,
      },
      description: {
        type: String,
        trim: true,
        default: '',
      },
      pasteur: {
        type: String,
        trim: true,
        default: '',
      },
      imageUrl: {
        type: String,
        trim: true,
        default: '',
      },
      lieu: {
        type: String,
        trim: true,
        default: '',
      },
      theme: {
        type: String,
        trim: true,
        default: '',
      },
      audioUrl: {
        type: String,
        required: true,
        trim: true,
      },
      dateDiffusion: {
        type: Date,
        required: true,
      },
      heure: {
        type: String,
        default: '',
      },
      heureFin: {
        type: String,
        default: '',
      },
      dureeSecondes: {
        type: Number,
        default: 0,
        min: 0,
      },
      dateFin: {
        type: Date,
        default: null,
      },
      statut: {
        type: String,
        enum: [
          'planifie',
          'en_cours',
          'termine',
        ],
        default: 'planifie',
      },
      visible: {
        type: Boolean,
        default: true,
      },
      publierBibliotheque: {
        type: Boolean,
        default: false,
      },
      dateCreation: {
        type: Date,
        default: Date.now,
      },
    },
    {
      timestamps: true,
    }
  );
module.exports =
  mongoose.models.Sermon ||
  mongoose.model(
    'Sermon',
    sermonSchema
  );