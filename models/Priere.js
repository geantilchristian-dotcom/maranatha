const mongoose = require('mongoose');
const priereSchema = new mongoose.Schema({
  titre:  { type: String, required: true },
  texte:  { type: String, required: true },
  ordre:  { type: Number, default: 0 },
  actif:  { type: Boolean, default: true },
}, { timestamps: true });
module.exports = mongoose.model('Priere', priereSchema);
