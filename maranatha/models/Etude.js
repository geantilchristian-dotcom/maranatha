const mongoose = require('mongoose');
const etudeSchema = new mongoose.Schema({
  titre:           { type: String, required: true },
  texte:           { type: String, default: '' },
  pdfUrl:          { type: String, default: '' },
  datePublication: { type: Date, default: Date.now },
  actif:           { type: Boolean, default: true },
}, { timestamps: true });
module.exports = mongoose.model('Etude', etudeSchema);
