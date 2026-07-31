# Corrections apportées à Maranatha

## Application Flutter

- Réparation complète de la page d’introduction cassée.
- Nouvelle introduction plein écran avec image locale, texte « Bienvenue dans l’église Maranatha » et glissement vers la gauche.
- Ouverture du vrai tableau de bord `https://maranatha-dl9d.onrender.com/` après le glissement.
- Suppression de l’ancien écran d’accueil avec le mode alarme.
- WebView améliorée : chargement, progression, gestion des erreurs réseau, bouton Réessayer et retour Android.
- Pont audio WebView/Flutter sécurisé et lecture audio conservée en arrière-plan.
- Connexion du token Firebase à l’interface web.
- Notifications restructurées avec canal Android, icône adaptée et reprise après erreur temporaire.
- Écran de lancement Android harmonisé avec le design bleu nuit de Maranatha.
- Page native des prédications conservée comme solution de secours, avec états vide et réseau propres.
- Suppression des fichiers Node inutiles qui se trouvaient dans le projet Flutter.
- Migration Gradle conservée : SDK 36, Gradle 8.11.1, AGP 8.10.1, Java 17 et NDK 28.2.13676358.

## Serveur Node.js / Render

- Suppression du mot de passe administrateur codé en dur.
- Protection commune de toutes les routes d’administration.
- Protection des créations, démarrages, arrêts et suppressions de prédications.
- Validation renforcée des utilisateurs, identifiants et données reçues.
- Page de politique de confidentialité corrigée pour refléter les données réellement utilisées.
- CORS configurable avec `ALLOWED_ORIGINS`.
- Route de santé `/api/health` modernisée.
- Arrêt propre de MongoDB et du serveur.
- Fichier `render.yaml` ajouté.
- Fichier `.env.example` ajouté sans secrets.
- Interface web recentrée et identité visuelle rouge/bordeaux modernisée.
- Manifest PWA, icônes et cache du service worker corrigés.

## Vérifications réalisées

- Syntaxe de tous les fichiers JavaScript vérifiée avec Node.js.
- Scripts JavaScript intégrés à `index.html` et `admin.html` vérifiés.
- JSON et XML vérifiés.
- Délimiteurs de tous les fichiers Dart vérifiés.
- Recherche de secrets exposés et de textes mal encodés effectuée.

## Vérification à faire sur votre ordinateur

Le conteneur utilisé pour la correction ne contient pas le SDK Flutter. Exécutez donc :

```powershell
Set-Location .\maranatha-app
flutter pub get
flutter analyze
flutter run
```

Le workflow GitHub Actions inclus effectue également `flutter analyze` et compile l’APK.

## Sécurité importante

- Changez le mot de passe MongoDB qui a été affiché dans la conversation.
- Remplacez ensuite la valeur `MONGO_URI` dans Render.
- Définissez un mot de passe long dans `ADMIN_PASSWORD` sur Render.
- Ne publiez jamais `.env`, le compte de service Firebase ou les clés Cloudinary.
