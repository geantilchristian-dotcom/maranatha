const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const userRoutes = require('./routes/userRoutes');
const sermonRoutes = require('./routes/sermonRoutes');

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

// Routes de l'API (les routes sermon et user sont publiques pour les appareils mobile)
app.use('/api/users', userRoutes);
app.use('/api/sermons', sermonRoutes);

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
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/maranathaDB";

app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
});

mongoose.connect(MONGO_URI)
  .then(() => console.log("MongoDB connecté ✓"))
  .catch(err => console.error("Erreur MongoDB :", err.message));
