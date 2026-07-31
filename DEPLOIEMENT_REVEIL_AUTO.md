# Déploiement du serveur Maranatha — Réveil automatique

Le serveur actuellement publié doit être remplacé par cette version. L’application mobile et le serveur doivent être mis à jour ensemble.

## Variables Render requises

- `MONGO_URI`
- `ADMIN_PASSWORD`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`
- `FIREBASE_SERVICE_ACCOUNT` : contenu JSON complet du compte de service Firebase
- `ALLOWED_ORIGINS` selon votre configuration

Ne placez jamais les vraies valeurs dans GitHub.

## Publication

Poussez le contenu de ce dossier dans le dépôt GitHub déjà relié au service Render, puis lancez un nouveau déploiement. Le démarrage réussi doit afficher notamment :

```text
Planificateur Maranatha démarré.
Serveur Maranatha en écoute...
```

## Fonctionnement

- `POST /api/sermons/schedule` téléverse l’audio, enregistre la date/heure et transmet la programmation aux téléphones.
- `GET /api/sermons/upcoming?days=30` permet à l’application de récupérer les alarmes manquées.
- Firebase transmet les commandes de programmation, annulation, démarrage de secours et arrêt.
- Le téléphone utilise ensuite son horloge Android locale pour le déclenchement exact.

## Test

Programmez une prédication au moins 5 minutes dans le futur. Pour un test fiable, gardez Internet actif jusqu’à ce que le téléphone affiche la confirmation **Réveil Maranatha programmé**.
