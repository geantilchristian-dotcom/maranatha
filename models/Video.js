const mongoose = require('mongoose');
const videoSchema = new mongoose.Schema({
  titre:       { type: String, required: true },
  description: { type: String, default: '' },
  categorie:   { type: String, default: 'Général' },
  youtubeUrl:  { type: String, default: '' },
  ordre:       { type: Number, default: 0 },
}, { timestamps: true });
module.exports = mongoose.model('Video', videoSchema);
