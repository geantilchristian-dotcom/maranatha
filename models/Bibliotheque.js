const mongoose = require('mongoose');

const bibliothequeSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['video', 'photo', 'audio', 'book'],
      required: true,
      index: true,
    },
    titre: { type: String, required: true, trim: true, maxlength: 180 },
    auteur: { type: String, default: '', trim: true, maxlength: 160 },
    description: { type: String, default: '', trim: true, maxlength: 4000 },
    categorie: { type: String, default: 'Général', trim: true, maxlength: 100 },
    couvertureUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    fichierUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    lienExterne: { type: String, default: '', trim: true, maxlength: 1600 },
    nomFichier: { type: String, default: '', trim: true, maxlength: 220 },
    telechargeable: { type: Boolean, default: true },
    actif: { type: Boolean, default: true, index: true },
    ordre: { type: Number, default: 0 },
  },
  { timestamps: true },
);

bibliothequeSchema.index({ actif: 1, type: 1, ordre: 1, createdAt: -1 });

module.exports =
  mongoose.models.Bibliotheque ||
  mongoose.model('Bibliotheque', bibliothequeSchema);
