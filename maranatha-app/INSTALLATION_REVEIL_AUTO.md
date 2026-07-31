# Maranatha — Réveil automatique

Cette version reçoit la programmation créée par l’administrateur, prépare l’audio et enregistre une alarme exacte dans Android. À l’heure prévue, la prédication démarre automatiquement avec un écran **Arrêter** / **Rappeler dans 5 minutes**.

## Installation sur le TECNO

Le changement contient du code Android natif : un simple Hot Reload ne suffit pas.

```powershell
# Dans l'ancien terminal Flutter, appuyer d'abord sur q
Set-Location "D:\projet\maranatha-reveil-auto-v2"
flutter pub get
flutter analyze
flutter run -d 148467059C008509
```

Au premier lancement :

1. Glisser vers la gauche.
2. Cocher le consentement.
3. Autoriser les notifications.
4. Autoriser **Alarmes et rappels**.
5. Autoriser l’écran plein écran et l’arrière-plan quand le téléphone les propose.
6. Activer le réveil Maranatha.

## Test recommandé

Après le déploiement du nouveau serveur :

1. Ouvrir l’administration Maranatha.
2. Ajouter un petit fichier audio.
3. Choisir une heure située au moins 5 minutes dans le futur.
4. Valider la programmation.
5. Attendre la notification de confirmation sur le téléphone.
6. Fermer l’application et verrouiller l’écran.
7. À l’heure choisie, l’audio doit démarrer automatiquement.

Le téléphone doit avoir Internet lors de la réception de la programmation. L’application essaie ensuite de télécharger l’audio avant l’heure afin de pouvoir le lire même si le réseau est faible au moment du réveil.

Ne testez pas après avoir utilisé **Forcer l’arrêt** dans les paramètres Android : Android désactive les alarmes et messages d’une application forcée à l’arrêt jusqu’à sa prochaine ouverture.
