const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  key: { type: String, default: 'splash', unique: true },
  nomEglise: { type: String, default: 'Maranatha' },
  verset: { type: String, default: 'Viens, Seigneur Jésus — Apocalypse 22 : 20' },
  sousTitre: { type: String, default: 'Ministère Évangélique' },
  logoUrl: { type: String, default: '/logo.jpg' },
  couleurFond: { type: String, default: '#001220' },
  couleurAccent: { type: String, default: '#D4AF37' },
  dureeSplash: { type: Number, default: 3 },
  youtubeUrl: { type: String, default: '' },
  ytLabel: { type: String, default: 'Regarder sur YouTube' },
}, { timestamps: true });

module.exports = mongoose.model('Settings', settingsSchema);
