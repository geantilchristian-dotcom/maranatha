const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  key: { type: String, default: 'splash', unique: true },
  nomEglise:    { type: String, default: 'Maranatha' },
  verset:       { type: String, default: 'Viens, Seigneur Jésus — Apocalypse 22 : 20' },
  sousTitre:    { type: String, default: 'Ministère Évangélique' },
  logoUrl:      { type: String, default: '/logo.jpg' },
  couleurFond:  { type: String, default: '#001220' },
  couleurAccent:{ type: String, default: '#D4AF37' },
  dureeSplash:  { type: Number, default: 3 },
  youtubeUrl:   { type: String, default: '' },
  ytLabel:      { type: String, default: 'Regarder sur YouTube' },
  youtubeLinks: {
    type: [{
      url:   { type: String, default: '' },
      label: { type: String, default: 'Regarder sur YouTube' },
    }],
    default: [],
  },
  programme: {
    type: [{
      id:          { type: String, default: '' },
      titre:       { type: String, default: '' },
      badge:       { type: String, default: 'PRÉDICATION' },
      dateStr:     { type: String, default: '' },
      heureStr:    { type: String, default: '' },
      lieu:        { type: String, default: '' },
      description: { type: String, default: '' },
      imageUrl:    { type: String, default: '' },
    }],
    default: [],
  },
  // Don — Mobile Money
  airtel:       { type: String, default: '' },
  orange:       { type: String, default: '' },
  vodacom:      { type: String, default: '' },
  // Don — Banque
  nomTitulaire: { type: String, default: '' },
  nomBanque:    { type: String, default: '' },
  numeroCompte: { type: String, default: '' },
  iban:         { type: String, default: '' },
  bic:          { type: String, default: '' },
  instructions: { type: String, default: '' },
  // Rétrocompatibilité
  telephone1:   { type: String, default: '' },
  telephone2:   { type: String, default: '' },
  // Réseaux sociaux
  facebookUrl:       { type: String, default: '' },
  youtubeChannelUrl: { type: String, default: '' },
  tiktokUrl:         { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('Settings', settingsSchema);
