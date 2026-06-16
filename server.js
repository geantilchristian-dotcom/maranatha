// Maranatha Server — v20260616d
const express = require('express');
const mongoose = require('mongoose');
const cors    = require('cors');
const path    = require('path');
const fs      = require('fs');
require('dotenv').config();

const userRoutes     = require('./routes/userRoutes');
const sermonRoutes   = require('./routes/sermonRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const commentRoutes  = require('./routes/commentRoutes');
const membreRoutes   = require('./routes/membreRoutes');
const priereRoutes   = require('./routes/priereRoutes');
const etudeRoutes    = require('./routes/etudeRoutes');
const livreRoutes    = require('./routes/livreRoutes');
const videoRoutes    = require('./routes/videoRoutes');
const bibleRoutes    = require('./routes/bibleRoutes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

// ── Politique de confidentialité ────────────────────────────────────────
app.get('/politique-confidentialite', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Politique de confidentialité — Maranatha</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Georgia,serif;background:#0a0a0a;color:#e8e0d5;max-width:720px;margin:0 auto;padding:40px 24px 80px}
    h1{font-size:1.8rem;color:#c8a96e;margin-bottom:8px}
    .sub{color:#888;font-size:.9rem;margin-bottom:40px}
    h2{font-size:1.1rem;color:#c8a96e;margin:32px 0 10px;text-transform:uppercase;letter-spacing:.05em}
    p,li{line-height:1.8;color:#ccc;margin-bottom:10px}
    li{margin-left:20px}
    a{color:#c8a96e}
    .footer{margin-top:60px;padding-top:20px;border-top:1px solid #333;color:#666;font-size:.85rem;text-align:center}
  </style>
</head>
<body>
  <h1>Politique de confidentialité</h1>
  <p class="sub">Application mobile Maranatha — Église CEMM &nbsp;|&nbsp; En vigueur depuis le 16 juin 2026</p>

  <h2>1. Qui sommes-nous ?</h2>
  <p>Cette application est publiée par l'Église du Centre d'Évangélisation Maranatha Ministère (CEMM). Pour toute question : <a href="mailto:contact@cemm-eglisemaranatha.site">contact@cemm-eglisemaranatha.site</a></p>

  <h2>2. Données collectées</h2>
  <p>L'application Maranatha <strong>ne collecte aucune donnée personnelle</strong> directement. Elle affiche le contenu de notre site web (sermons, prières, études bibliques) via un navigateur intégré.</p>
  <p>Notre site web peut utiliser des cookies techniques nécessaires à son fonctionnement (session, préférences). Aucun cookie publicitaire ou de traçage tiers n'est utilisé.</p>

  <h2>3. Permissions demandées</h2>
  <ul>
    <li><strong>Internet</strong> — pour charger les sermons et le contenu du ministère.</li>
    <li><strong>Notifications</strong> — pour vous alerter lors d'un culte ou sermon en direct (optionnel, vous pouvez refuser).</li>
    <li><strong>Service en arrière-plan</strong> — pour continuer la lecture audio d'un sermon même lorsque l'écran est éteint.</li>
  </ul>
  <p>Aucune permission d'accès à vos contacts, photos, localisation ou microphone n'est demandée.</p>

  <h2>4. Partage des données</h2>
  <p>Nous ne vendons, ne louons et ne partageons aucune donnée avec des tiers. Aucune régie publicitaire n'est intégrée dans l'application.</p>

  <h2>5. Stockage et sécurité</h2>
  <p>Les données de navigation (contenu des pages) transitent entre votre appareil et nos serveurs via une connexion chiffrée HTTPS. Nous ne stockons aucune information personnelle vous concernant.</p>

  <h2>6. Enfants</h2>
  <p>Notre application est destinée à un public général. Nous ne collectons sciemment aucune donnée d'enfants de moins de 13 ans.</p>

  <h2>7. Vos droits</h2>
  <p>Conformément au Règlement Général sur la Protection des Données (RGPD), vous avez le droit d'accès, de rectification et de suppression de vos données. Contactez-nous à <a href="mailto:contact@cemm-eglisemaranatha.site">contact@cemm-eglisemaranatha.site</a> pour toute demande.</p>

  <h2>8. Modifications</h2>
  <p>Cette politique peut être mise à jour. Toute modification sera publiée sur cette page avec une nouvelle date d'entrée en vigueur.</p>

  <div class="footer">© 2026 Église CEMM — Maranatha &nbsp;|&nbsp; www.cemm-eglisemaranatha.site</div>
</body>
</html>`);
});

// ── Route racine : injecte flutter-audio.js dans index.html ────────────
app.get('/', (req, res) => {
  try {
    const filePath = path.join(__dirname, 'public', 'index.html');
    let html = fs.readFileSync(filePath, 'utf8');
    html = html.replace(
      '</body>',
      '<script src="/flutter-audio.js?v=20260616d"></script></body>'
    );
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.send(html);
  } catch (e) {
    res.status(500).send('Erreur serveur : ' + e.message);
  }
});

app.use(express.static(path.join(__dirname, 'public')));

const adminAuth = (req, res, next) => {
  const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'maranatha2026';
  const pwd = req.headers['x-admin-password'];
  if (pwd !== ADMIN_PASSWORD) return res.status(401).json({ error: 'Non autorisé' });
  next();
};

app.get('/api/admin/verify', adminAuth, (req, res) => res.json({ ok: true }));

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
  res.json({ status: 'ok', version: '20260616d', mongo: states[mongoose.connection.readyState] || 'unknown' });
});

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) { console.error('ERREUR FATALE : MONGO_URI non definie !'); process.exit(1); }

mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 10000, socketTimeoutMS: 45000 })
  .then(() => {
    console.log('MongoDB connecte');
    app.listen(PORT, () => console.log('Serveur Maranatha v20260616d sur port ' + PORT));
  })
  .catch(err => { console.error('Erreur MongoDB :', err.message); process.exit(1); });
