# Maranatha

Projet complet de la Communauté des Églises Missionnaires Maranatha.

## Structure

- `server.js`, `routes/`, `models/`, `utils/`, `public/` : serveur Node.js et tableau de bord web.
- `maranatha-app/` : application Flutter Android.

## Parcours mobile

1. L'application affiche l'introduction « Bienvenue dans l'église Maranatha ».
2. L'utilisateur glisse le bouton vers la gauche.
3. Le vrai tableau de bord web Maranatha s'ouvre dans la WebView.
4. Les notifications Firebase et la lecture audio en arrière-plan restent actives.

## Variables Render obligatoires

- `MONGO_URI`
- `ADMIN_PASSWORD`

Pour les prédications audio et notifications :

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`
- `FIREBASE_SERVICE_ACCOUNT`

Ne placez jamais les valeurs secrètes dans GitHub.

## Serveur local

```powershell
npm install
Copy-Item .env.example .env
npm start
```

Le site : `http://localhost:5000/`

L'administration : `http://localhost:5000/admin`

## Vérification du serveur

```powershell
npm run check
```

## Application Flutter

```powershell
Set-Location .\maranatha-app
flutter pub get
flutter analyze
flutter run
```

Le projet utilise Android SDK 36, Gradle 8.11.1, AGP 8.10.1, Java 17+ et NDK 28.2.13676358.

## Publication Render

Le fichier `render.yaml` est prêt. Après déploiement, vérifiez :

- `/api/health`
- `/api/sermons`
- `/admin`

Avant une publication sur Play Store, remplacez la signature debug du bloc `release` par une vraie clé de signature Android.

## Après la correction

Consultez `CHANGEMENTS.md` pour le détail des modifications et `VERIFICATION.md` pour les contrôles exécutés.

Pour republier le serveur corrigé :

```powershell
npm install
npm run check
git add .
git commit -m "Correction complète Maranatha"
git push
```

Render peut ensuite redéployer la branche `main` automatiquement.
