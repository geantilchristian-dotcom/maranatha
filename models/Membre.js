const mongoose = require('mongoose');

const membreSchema = new mongoose.Schema({
  nom:       { type: String, required: true, trim: true },
  telephone: { type: String, required: true, trim: true },
  adresse:   { type: String, required: true, trim: true },
  statut:    { type: String, enum: ['en_attente', 'accepte', 'refuse'], default: 'en_attente' },
  dateInscription: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Membre', membreSchema);
