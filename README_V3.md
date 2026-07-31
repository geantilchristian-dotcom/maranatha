# Maranatha v3 — Réveil automatique

## Cause du problème corrigée

L’ancienne interface chargeait la prédication dans le lecteur Web, mais le navigateur pouvait refuser la lecture automatique avec son. Le backend seul ne peut pas contourner cette règle.

La version v3 utilise donc deux mécanismes :

1. **Application Android native** : l’administrateur programme la date et l’heure, puis Android enregistre une alarme exacte et démarre la prédication avec un service audio natif.
2. **Interface Web/PWA** : la lecture automatique est seulement tentée. Si le navigateur la bloque, le bouton Lecture reste nécessaire.

## Corrections incluses

- enregistrement direct de chaque téléphone dans `Device`, sans dépendre de la connexion du fidèle au site ;
- synchronisation locale des prédications programmées ;
- alarme Android exacte ;
- lecture avec le canal audio d’alarme ;
- démarrage en arrière-plan et écran verrouillé ;
- téléchargement anticipé de l’audio ;
- rejet des fichiers audio partiellement téléchargés ;
- secours vers l’URL Cloudinary si le fichier local est incomplet ;
- pont Flutter/WebView sans cache ;
- lecture WebView autorisée sans geste utilisateur ;
- relance automatique du lecteur natif ;
- reprogrammation après redémarrage et changement d’heure ;
- annulation et arrêt depuis l’administration.

## Déploiement

1. Copier le contenu de ce dossier dans le dépôt GitHub Maranatha.
2. Pousser sur la branche `main`.
3. Attendre que Render affiche `Live`.
4. Compiler et installer la nouvelle application Android située dans `maranatha-app`.
5. Sur chaque téléphone, activer le réveil Maranatha et accorder les autorisations demandées.

Le site ou la PWA ne peut pas garantir un démarrage sonore sans toucher l’écran. Pour le réveil automatique, les fidèles doivent installer l’APK Android v3.
