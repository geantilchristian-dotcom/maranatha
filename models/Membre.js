const mongoose = require('mongoose');

const membreSchema = new mongoose.Schema({
  nom:       { type: String, required: true, trim: true, maxlength: 120 },
  postNom:   { type: String, default: '', trim: true, maxlength: 120 },
  prenom:    { type: String, required: true, trim: true, maxlength: 120 },
  age:       { type: Number, min: 0, max: 120 },
  sexe:      { type: String, enum: ['Homme', 'Femme', ''], default: '' },
  telephone: { type: String, required: true, unique: true, trim: true, maxlength: 40 },
  indicatif: { type: String, default: '', trim: true, maxlength: 12 },
  pays:      { type: String, default: '', trim: true, maxlength: 100 },
  adresse:   { type: String, default: '', trim: true, maxlength: 300 },
  bio:       { type: String, default: '', trim: true, maxlength: 3000 },
  email:     { type: String, default: '', trim: true, maxlength: 254 },
  statut:    { type: String, enum: ['en_attente', 'accepte', 'refuse'], default: 'en_attente', index: true },
  dateInscription: { type: Date, default: Date.now, index: true },
});

module.exports = mongoose.model('Membre', membreSchema);
