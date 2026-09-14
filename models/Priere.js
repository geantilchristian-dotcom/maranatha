const mongoose = require('mongoose');

const priereSchema = new mongoose.Schema({
  titre: { type: String, required: true, trim: true, maxlength: 180 },
  texte: { type: String, required: true, trim: true, maxlength: 5000 },
  ordre: { type: Number, default: 0 },
  actif: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.models.Priere || mongoose.model('Priere', priereSchema);
