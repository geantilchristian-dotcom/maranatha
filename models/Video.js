const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema(
  {
    titre: { type: String, required: true, trim: true, maxlength: 180 },
    auteur: { type: String, default: '', trim: true, maxlength: 160 },
    description: { type: String, default: '', trim: true, maxlength: 4000 },
    categorie: { type: String, default: 'Général', trim: true, maxlength: 100 },
    youtubeUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    fichierUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    couvertureUrl: { type: String, default: '', trim: true, maxlength: 1600 },
    telechargeable: { type: Boolean, default: false },
    ordre: { type: Number, default: 0 },
  },
  { timestamps: true },
);

module.exports = mongoose.models.Video || mongoose.model('Video', videoSchema);
