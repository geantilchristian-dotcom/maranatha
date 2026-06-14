// 1. Importation des modules nécessaires
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const userRoutes = require('./routes/userRoutes');
const sermonRoutes = require('./routes/sermonRoutes');

const app = express();

// 2. Middlewares
app.use(cors());
app.use(express.json());

// 3. Routes
app.use('/api/users', userRoutes);
app.use('/api/sermons', sermonRoutes);

// 4. Planificateur automatique
require('./utils/scheduler');

// 5. Route de test
app.get('/', (req, res) => {
  res.send("Le serveur Maranatha est fonctionnel !");
});

// 6. Démarrage du serveur IMMÉDIATEMENT (sans attendre MongoDB)
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log('✅ Serveur démarré sur le port ' + PORT);
});

// 7. Connexion MongoDB (indépendante du démarrage)
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/maranathaDB";

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log("✅ Connexion réussie à MongoDB !");
  })
  .catch(err => {
    console.error("❌ Erreur MongoDB :", err.message);
  });
