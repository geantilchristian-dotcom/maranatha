const mongoose = require('mongoose');

const sermonSchema = new mongoose.Schema({
  titre: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  audioUrl: {
    type: String,
    required: true
  },
  dateDiffusion: {
    type: Date,
    required: true
  },
  statut: {
    type: String,
    enum: ['planifie', 'en_cours', 'termine'],
    default: 'planifie'
  },
  dateCreation: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Sermon', sermonSchema);
