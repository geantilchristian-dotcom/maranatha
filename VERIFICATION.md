# Rapport de vérification

## Réussi dans l’environnement de correction

- `npm run check`
- analyse de syntaxe Node.js des routes, modèles et utilitaires
- analyse de syntaxe des scripts intégrés aux pages HTML
- lecture valide de `package.json`, `manifest.json` et `google-services.json`
- lecture valide de tous les fichiers XML Android
- contrôle structurel des parenthèses, crochets et accolades Dart
- absence de `withOpacity`, `activeColor` et textes UTF-8 corrompus dans les fichiers corrigés
- absence de chaîne MongoDB réelle, mot de passe administrateur par défaut ou clé secrète dans le projet livré

## Non exécutable dans l’environnement de correction

Flutter et Dart ne sont pas installés dans ce conteneur. La compilation Android finale doit être confirmée sur votre ordinateur ou avec le workflow GitHub Actions inclus.
