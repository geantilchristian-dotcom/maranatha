// Serveur Maranatha â€” v20260731-reveil-auto
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const dns = require('node:dns');


require('dotenv').config();

/* MARANATHA_NODE_DNS_FIX */

/*
 * DNS personnalisÃ© UNIQUEMENT si
 * NODE_DNS_SERVERS est dÃ©fini.
 *
 * Exemple Windows local :
 *
 * NODE_DNS_SERVERS=1.1.1.1,8.8.8.8
 *
 * Sur Render :
 * laisser cette variable absente.
 */

try {

  const customDns =
    String(
      process.env.NODE_DNS_SERVERS || ""
    )
    .split(",")
    .map(
      value =>
        value.trim()
    )
    .filter(Boolean);


  if (
    customDns.length
  ) {

    dns.setServers(
      customDns
    );


    console.log(
      "[DNS] RÃ©solveurs personnalisÃ©s :",
      customDns.join(", ")
    );

  }else{

    console.log(
      "[DNS] RÃ©solveurs systÃ¨me."
    );
  }


}catch(error){

  console.warn(
    "[DNS]",
    error.message
  );
}

/* MARANATHA_NODE_DNS_FIX_END */


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
const libraryStateRoutes = require('./routes/libraryStateRoutes');
const bibleRoutes = require('./routes/bibleRoutes');
const deviceRoutes = require('./routes/deviceRoutes');
const Sermon = require('./models/Sermon');

const app = express();
// MARANATHA_DONS_PUBLIC_FIRST
app.use(
  "/api/dons",
  express.json({ limit: "1mb" }),
  require("./routes/donRoutes")
);
// MARANATHA_ADMIN_INBOX_PUBLIC_FIRST
app.use(
  "/api/admin-inbox",
  express.json({ limit: "1mb" }),
  require("./routes/adminInboxRoutes")
);
const PORT = Number(process.env.PORT || 5000);
const MONGO_URI = process.env.MONGO_URI;
const VERSION = '20260923-realtime-admin-v1';

app.disable('x-powered-by');
app.set('trust proxy', 1);

const allowedOrigins = String(process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

function isLocalDevelopmentOrigin(origin) {
  if (!origin) {
    return false;
  }
  try {
    const url = new URL(origin);
    return (
      (url.hostname === 'localhost' ||
        url.hostname === '127.0.0.1') &&
      (url.protocol === 'http:' ||
        url.protocol === 'https:')
    );
  } catch (_error) {
    return false;
  }
}app.use(
  cors({
    origin(origin, callback) {
      if (
        !origin ||
        allowedOrigins.length === 0 ||
        allowedOrigins.includes(origin) ||
        isLocalDevelopmentOrigin(origin)
      ) {
        return callback(null, true);
      }
      return callback(new Error('Origine non autorisÃ©e'));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-admin-password'],
  }),
);
app.use(express.json({ limit: '5mb' }));

// MARANATHA_ADMIN_INBOX_CAPTURE
app.use(require('./utils/adminInboxCapture'));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

app.get('/politique-confidentialite', (_req, res) => {
  res.type('html').send(`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Politique de confidentialitÃ© â€” Maranatha</title>
  <style>
    *{box-sizing:border-box}body{margin:0;font-family:system-ui,-apple-system,Segoe UI,sans-serif;background:#071522;color:#e9edf3}main{max-width:760px;margin:auto;padding:42px 22px 80px}h1{color:#d5ae32;font-size:30px;margin:0 0 8px}.sub{color:#94a0af;margin-bottom:34px}h2{font-size:17px;color:#d5ae32;margin-top:30px}p,li{line-height:1.7;color:#c9d0da}a{color:#f2cf66}.card{background:#0d2637;border:1px solid rgba(213,174,50,.18);border-radius:16px;padding:18px;margin:14px 0}.footer{margin-top:44px;padding-top:18px;border-top:1px solid rgba(255,255,255,.1);color:#7f8b99;font-size:13px}
  </style>
</head>
<body><main>
  <h1>Politique de confidentialitÃ©</h1>
  <p class="sub">Application Maranatha â€” mise Ã  jour du 30 juillet 2026</p>
  <h2>Responsable</h2>
  <p>L'application est gÃ©rÃ©e par la CommunautÃ© des Ã‰glises Missionnaires Maranatha.</p>
  <h2>DonnÃ©es utilisÃ©es</h2>
  <div class="card"><p>Selon les fonctions utilisÃ©es, l'application peut enregistrer un nom, un numÃ©ro de tÃ©lÃ©phone, un pays, une adresse e-mail facultative, un token de notification et les contenus envoyÃ©s volontairement, par exemple les commentaires ou demandes de priÃ¨re.</p></div>
  <h2>FinalitÃ©s</h2>
  <ul><li>gÃ©rer les membres et leurs prÃ©fÃ©rences;</li><li>envoyer les notifications de prÃ©dication;</li><li>afficher les programmes et contenus de l'Ã©glise;</li><li>rÃ©pondre aux commentaires et demandes.</li></ul>
  <h2>Permissions mobiles</h2>
  <p>Internet, notifications, vibration, rÃ©veil de l'Ã©cran pour les alertes importantes et lecture audio en arriÃ¨re-plan. L'application ne demande pas l'accÃ¨s aux contacts, Ã  la localisation ou au microphone.</p>
  <h2>Conservation et sÃ©curitÃ©</h2>
  <p>Les Ã©changes utilisent HTTPS. Les secrets d'administration sont conservÃ©s sur le serveur. Les notes personnelles sauvegardÃ©es localement restent sur l'appareil.</p>
  <h2>Suppression ou correction</h2>
  <p>Pour demander la correction ou la suppression de vos donnÃ©es, contactez l'administration de l'Ã©glise.</p>
  <div class="footer">Â© 2026 CommunautÃ© des Ã‰glises Missionnaires Maranatha</div>
</main></body></html>`);
});


app.get('/flutter-audio.js', (_req, res) => {
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.sendFile(path.join(__dirname, 'public', 'flutter-audio.js'));
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

// MARANATHA_KPAY_DONS

app.use(express.static(path.join(__dirname, 'public'), { maxAge: '1h' }));

app.get('/admin', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});
app.get('/api/admin/verify', adminOnly, (_req, res) => res.json({ ok: true }));
// MARANATHA_DIRECTS_COMPAT_V1
app.get('/api/directs', async (_req, res) => {
  try {
    const sermons = await Sermon.find({
      visible: { $ne: false },
    })
      .sort({ dateDiffusion: -1 })
      .lean();
    return res.json(
      sermons.map((item) => ({
        ...item,
        id: String(item._id || ''),
        title: String(item.titre || ''),
        status: String(item.statut || ''),
        date: item.dateDiffusion || null,
      })),
    );
  } catch (error) {
    console.error('[directs/compat]', error.message);
    return res.status(500).json({
      error: 'Recuperation des directs impossible',
    });
  }
});
// MARANATHA_DIRECTS_COMPAT_V1_END

app.use('/api/users', userRoutes);
app.use('/api/sermons', sermonRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/membres', membreRoutes);
app.use('/api/prieres', priereRoutes);
app.use('/api/etudes', etudeRoutes);
app.use('/api/livres', livreRoutes);
app.use('/api/videos', videoRoutes);
app.use('/api/library', libraryStateRoutes);
app.use('/api/bible', bibleRoutes);
app.use('/api/devices', deviceRoutes);

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
  res.status(error.message === 'Origine non autorisÃ©e' ? 403 : 500).json({
    error: error.message === 'Origine non autorisÃ©e'
      ? error.message
      : 'Erreur interne du serveur',
  });
});

async function start() {
  if (!MONGO_URI) {
    console.error('ERREUR FATALE : MONGO_URI non dÃ©finie');
    process.exit(1);
  }

  try {
    mongoose.set('strictQuery', true);
    await mongoose.connect(MONGO_URI, {
      serverSelectionTimeoutMS: 15000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
    });

    console.log('MongoDB connectÃ©');
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
  console.log(`${signal} reÃ§u, arrÃªt du serveurâ€¦`);
  try {
    await mongoose.connection.close();
  } finally {
    process.exit(0);
  }
}

process.once('SIGTERM', () => shutdown('SIGTERM'));
process.once('SIGINT', () => shutdown('SIGINT'));

start();
