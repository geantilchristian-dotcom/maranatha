const mongoose = require('mongoose');

const etudeSchema = new mongoose.Schema(
  {
    titre: { type: String, required: true, trim: true, maxlength: 180 },
    texte: { type: String, default: '', trim: true, maxlength: 12000 },
    couvertureUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    pdfUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    pdfNom: { type: String, default: '', trim: true, maxlength: 220 },
    datePublication: { type: Date, default: Date.now, index: true },
    actif: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);

module.exports = mongoose.models.Etude || mongoose.model('Etude', etudeSchema);
