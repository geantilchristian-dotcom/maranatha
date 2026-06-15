const mongoose = require('mongoose');

const membreSchema = new mongoose.Schema({
  nom:       { type: String, required: true, trim: true },
  postNom:   { type: String, default: '', trim: true },
  prenom:    { type: String, required: true, trim: true },
  age:       { type: Number },
  sexe:      { type: String, enum: ['Homme', 'Femme', ''], default: '' },
  telephone: { type: String, required: true, trim: true },
  indicatif: { type: String, default: '', trim: true },
  pays:      { type: String, default: '', trim: true },
  adresse:   { type: String, default: '', trim: true },
  statut:    { type: String, enum: ['en_attente', 'accepte', 'refuse'], default: 'en_attente' },
  dateInscription: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Membre', membreSchema);
