const mongoose = require('mongoose');
const livreSchema = new mongoose.Schema({
  titre:        { type: String, required: true },
  auteur:       { type: String, default: '' },
  description:  { type: String, default: '' },
  categorie:    { type: String, default: 'Général' },
  couvertureUrl:{ type: String, default: '' },
  fichierUrl:   { type: String, default: '' },
  lienExterne:  { type: String, default: '' },
  ordre:        { type: Number, default: 0 },
}, { timestamps: true });
module.exports = mongoose.model('Livre', livreSchema);
