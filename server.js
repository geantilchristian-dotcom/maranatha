// 1. Importation des modules nécessaires
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

// Importation des routes de l'application
const userRoutes = require('./routes/userRoutes');
const sermonRoutes = require('./routes/sermonRoutes');

const app = express();

// 2. Middlewares (Configuration pour la sécurité et la réception du JSON)
app.use(cors());
app.use(express.json());

// 3. Liaison des routes de notre API
app.use('/api/users', userRoutes);
app.use('/api/sermons', sermonRoutes);

// 4. Initialisation du planificateur de tâches automatique (L'Horloge)
require('./utils/scheduler');

// 5. Route de test globale pour vérifier que le serveur tourne
app.get('/', (req, res) => {
  res.send("Le serveur de l'église Maranatha est fonctionnel, les routes et l'horloge sont connectées !");
});

// 6. Configuration et Connexion à la base de données MongoDB
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/maranathaDB";

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log("Connexion réussie à MongoDB !");
    
    // Le serveur ne se lance que si la connexion à la base de données est établie
    app.listen(PORT, () => {
      console.log(`Serveur en cours d'exécution sur le port ${PORT}`);
    });
  })
  .catch(err => {
    console.error("Erreur critique de connexion à la base de données :", err);
  });