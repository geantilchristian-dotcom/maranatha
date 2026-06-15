const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const userRoutes    = require('./routes/userRoutes');
const sermonRoutes  = require('./routes/sermonRoutes');
const settingsRoutes= require('./routes/settingsRoutes');
const commentRoutes = require('./routes/commentRoutes');
const membreRoutes  = require('./routes/membreRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Servir les fichiers statiques (interface admin)
app.use(express.static(path.join(__dirname, 'public')));

// Middleware de vérification du mot de passe admin
const adminAuth = (req, res, next) => {
  const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'maranatha2026';
  const pwd = req.headers['x-admin-password'];
  if (pwd !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Non autorisé' });
  }
  next();
};

// Route de vérification du mot de passe admin (utilisée par l'interface)
app.get('/api/admin/verify', adminAuth, (req, res) => {
  res.json({ ok: true });
});

// Routes de l'API
app.use('/api/users',    userRoutes);
app.use('/api/sermons',  sermonRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/membres',  membreRoutes);

// Initialisation du planificateur automatique (L'Horloge)
require('./utils/scheduler');

// Page admin — accessible via /admin
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// Route de santé
app.get('/', (req, res) => {
  res.send("Serveur Maranatha opérationnel ✓");
});

// Connexion MongoDB et démarrage du serveur
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("ERREUR FATALE : La variable d'environnement MONGO_URI n'est pas definie !");
  console.error("Configurez MONGO_URI dans les variables d'environnement Render.");
  process.exit(1);
}

// Endpoint de sante — utile pour debugger
app.get('/api/health', (req, res) => {
  const states = { 0: 'disconnected', 1: 'connected', 2: 'connecting', 3: 'disconnecting' };
  res.json({
    status: 'ok',
    mongo: states[mongoose.connection.readyState] || 'unknown',
    env: {
      MONGO_URI: MONGO_URI ? 'defini (' + MONGO_URI.substring(0, 20) + '...)' : 'MANQUANT',
      CLOUDINARY_CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME || 'MANQUANT',
    }
  });
});

mongoose.connect(MONGO_URI, {
  serverSelectionTimeoutMS: 10000,
  socketTimeoutMS: 45000,
})
  .then(() => {
    console.log("MongoDB connecte ✓");
    app.listen(PORT, () => console.log(`Serveur demarre sur le port ${PORT}`));
  })
  .catch(err => {
    console.error("Erreur connexion MongoDB :", err.message);
    process.exit(1);
  });
