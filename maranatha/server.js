// Maranatha Server — v2026.06.16
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
const priereRoutes  = require('./routes/priereRoutes');
const etudeRoutes   = require('./routes/etudeRoutes');
const livreRoutes   = require('./routes/livreRoutes');
const videoRoutes   = require('./routes/videoRoutes');
const bibleRoutes   = require('./routes/bibleRoutes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const adminAuth = (req, res, next) => {
  const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'maranatha2026';
  const pwd = req.headers['x-admin-password'];
  if (pwd !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Non autorisé' });
  }
  next();
};

app.get('/api/admin/verify', adminAuth, (req, res) => {
  res.json({ ok: true });
});

app.use('/api/users',    userRoutes);
app.use('/api/sermons',  sermonRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/membres',  membreRoutes);
app.use('/api/prieres',  priereRoutes);
app.use('/api/etudes',   etudeRoutes);
app.use('/api/livres',   livreRoutes);
app.use('/api/videos',   videoRoutes);
app.use('/api/bible',    bibleRoutes);

require('./utils/scheduler');

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.get('/api/health', (req, res) => {
  const states = { 0: 'disconnected', 1: 'connected', 2: 'connecting', 3: 'disconnecting' };
  res.json({
    status: 'ok',
    version: '2026.06.16',
    mongo: states[mongoose.connection.readyState] || 'unknown',
    env: {
      MONGO_URI: process.env.MONGO_URI ? 'defini' : 'MANQUANT',
      CLOUDINARY_CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME || 'MANQUANT',
    }
  });
});

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("ERREUR FATALE : MONGO_URI non definie !");
  process.exit(1);
}

mongoose.connect(MONGO_URI, {
  serverSelectionTimeoutMS: 10000,
  socketTimeoutMS: 45000,
})
  .then(() => {
    console.log("MongoDB connecte");
    app.listen(PORT, () => console.log(`Serveur Maranatha v2026.06.16 demarre sur le port ${PORT}`));
  })
  .catch(err => {
    console.error("Erreur connexion MongoDB :", err.message);
    process.exit(1);
  });
