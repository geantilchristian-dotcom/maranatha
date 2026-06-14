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
  // L'URL du fichier MP3 stocké en ligne (ex: Firebase Storage, Cloudinary, etc.)
  audioUrl: { 
    type: String, 
    required: true 
  },
  // La date et l'heure exactes de diffusion (ex: 2026-06-15T16:00:00)
  dateDiffusion: { 
    type: Date, 
    required: true 
  },
  // Suivi de l'état de la prédication
  statut: { 
    type: String, 
    enum: ['planifie', 'en_cours', 'termine'], 
    default: 'planifie' 
  },
  // Référence vers le Pasteur qui a publié la prédication
  creePar: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: true
  },
  dateCreation: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Sermon', sermonSchema);