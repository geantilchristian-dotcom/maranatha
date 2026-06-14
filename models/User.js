const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  nom: { 
    type: String, 
    required: true,
    trim: true 
  },
  telephone: { 
    type: String, 
    required: true, 
    unique: true,
    trim: true
  },
  // Le token généré par l'application mobile (Firebase Cloud Messaging)
  fcmToken: { 
    type: String, 
    required: true 
  }, 
  // Permet à l'utilisateur d'activer ou couper le mode réveil automatique
  modeMaranathaActif: { 
    type: Boolean, 
    default: true 
  },
  // Pour différencier le Pasteur (admin) des fidèles
  role: {
    type: String,
    enum: ['fidele', 'pasteur'],
    default: 'fidele'
  },
  dateInscription: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('User', userSchema);