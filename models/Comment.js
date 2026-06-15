const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
  texte:        { type: String, required: true, trim: true, maxlength: 1000 },
  type:         { type: String, enum: ['commentaire', 'suggestion'], default: 'commentaire' },
  section:      { type: String, enum: ['communaute', 'parole'], default: 'communaute' },
  auteur:       { type: String, default: '', trim: true },
  dateEnvoi:    { type: Date, default: Date.now },
  adminReponse: { type: String, default: '', trim: true },
  dateReponse:  { type: Date },
});

module.exports = mongoose.model('Comment', commentSchema);
