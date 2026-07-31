// Serveur Maranatha — v20260731-reveil-auto
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const adminOnly = require('./utils/adminAuth');
const userRoutes = require('./routes/userRoutes');
const sermonRoutes = require('./routes/sermonRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const commentRoutes = require('./routes/commentRoutes');
const membreRoutes = require('./routes/membreRoutes');
const priereRoutes = require('./routes/priereRoutes');
const etudeRoutes = require('./routes/etudeRoutes');
const livreRoutes = require('./routes/livreRoutes');
const videoRoutes = require('./routes/videoRoutes');
const bibleRoutes = require('./routes/bibleRoutes');

const app = express();
const PORT = Number(process.env.PORT || 5000);
const MONGO_URI = process.env.MONGO_URI;
const VERSION = '20260731-reveil-auto';

app.disable('x-powered-by');
app.set('trust proxy', 1);

const allowedOrigins = String(process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Origine non autorisée'));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-admin-password'],
  }),
);
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

app.get('/politique-confidentialite', (_req, res) => {
  res.type('html').send(`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Politique de confidentialité — Maranatha</title>
  <style>
    *{box-sizing:border-box}body{margin:0;font-family:system-ui,-apple-system,Segoe UI,sans-serif;background:#071522;color:#e9edf3}main{max-width:760px;margin:auto;padding:42px 22px 80px}h1{color:#d5ae32;font-size:30px;margin:0 0 8px}.sub{color:#94a0af;margin-bottom:34px}h2{font-size:17px;color:#d5ae32;margin-top:30px}p,li{line-height:1.7;color:#c9d0da}a{color:#f2cf66}.card{background:#0d2637;border:1px solid rgba(213,174,50,.18);border-radius:16px;padding:18px;margin:14px 0}.footer{margin-top:44px;padding-top:18px;border-top:1px solid rgba(255,255,255,.1);color:#7f8b99;font-size:13px}
  </style>
</head>
<body><main>
  <h1>Politique de confidentialité</h1>
  <p class="sub">Application Maranatha — mise à jour du 30 juillet 2026</p>
  <h2>Responsable</h2>
  <p>L'application est gérée par la Communauté des Églises Missionnaires Maranatha.</p>
  <h2>Données utilisées</h2>
  <div class="card"><p>Selon les fonctions utilisées, l'application peut enregistrer un nom, un numéro de téléphone, un pays, une adresse e-mail facultative, un token de notification et les contenus envoyés volontairement, par exemple les commentaires ou demandes de prière.</p></div>
  <h2>Finalités</h2>
  <ul><li>gérer les membres et leurs préférences;</li><li>envoyer les notifications de prédication;</li><li>afficher les programmes et contenus de l'église;</li><li>répondre aux commentaires et demandes.</li></ul>
  <h2>Permissions mobiles</h2>
  <p>Internet, notifications, vibration, réveil de l'écran pour les alertes importantes et lecture audio en arrière-plan. L'application ne demande pas l'accès aux contacts, à la localisation ou au microphone.</p>
  <h2>Conservation et sécurité</h2>
  <p>Les échanges utilisent HTTPS. Les secrets d'administration sont conservés sur le serveur. Les notes personnelles sauvegardées localement restent sur l'appareil.</p>
  <h2>Suppression ou correction</h2>
  <p>Pour demander la correction ou la suppression de vos données, contactez l'administration de l'église.</p>
  <div class="footer">© 2026 Communauté des Églises Missionnaires Maranatha</div>
</main></body></html>`);
});

app.get('/', (_req, res) => {
  try {
    const filePath = path.join(__dirname, 'public', 'index.html');
    let html = fs.readFileSync(filePath, 'utf8');
    html = html.replace(
      '</body>',
      `<script src="/flutter-audio.js?v=${VERSION}"></script></body>`,
    );
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    return res.type('html').send(html);
  } catch (error) {
    console.error('[root]', error.message);
    return res.status(500).send('Interface temporairement indisponible');
  }
});

app.use(express.static(path.join(__dirname, 'public'), { maxAge: '1h' }));

app.get('/admin', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});
app.get('/api/admin/verify', adminOnly, (_req, res) => res.json({ ok: true }));

app.use('/api/users', userRoutes);
app.use('/api/sermons', sermonRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/membres', membreRoutes);
app.use('/api/prieres', priereRoutes);
app.use('/api/etudes', etudeRoutes);
app.use('/api/livres', livreRoutes);
app.use('/api/videos', videoRoutes);
app.use('/api/bible', bibleRoutes);

app.get('/api/health', (_req, res) => {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };
  res.json({
    status: mongoose.connection.readyState === 1 ? 'ok' : 'degraded',
    version: VERSION,
    database: states[mongoose.connection.readyState] || 'unknown',
  });
});

app.use('/api', (_req, res) => {
  res.status(404).json({ error: 'Route API introuvable' });
});

app.use((error, _req, res, _next) => {
  console.error('[server]', error.message);
  res.status(error.message === 'Origine non autorisée' ? 403 : 500).json({
    error: error.message === 'Origine non autorisée'
      ? error.message
      : 'Erreur interne du serveur',
  });
});

async function start() {
  if (!MONGO_URI) {
    console.error('ERREUR FATALE : MONGO_URI non définie');
    process.exit(1);
  }

  try {
    mongoose.set('strictQuery', true);
    await mongoose.connect(MONGO_URI, {
      serverSelectionTimeoutMS: 15000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
    });

    console.log('MongoDB connecté');
    require('./utils/scheduler');

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Serveur Maranatha v${VERSION} sur le port ${PORT}`);
    });
  } catch (error) {
    console.error('Erreur MongoDB :', error.message);
    process.exit(1);
  }
}

async function shutdown(signal) {
  console.log(`${signal} reçu, arrêt du serveur…`);
  try {
    await mongoose.connection.close();
  } finally {
    process.exit(0);
  }
}

process.once('SIGTERM', () => shutdown('SIGTERM'));
process.once('SIGINT', () => shutdown('SIGINT'));

start();
