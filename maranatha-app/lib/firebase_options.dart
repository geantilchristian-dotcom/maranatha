// Fichier généré automatiquement à partir de google-services.json
// Project: MARANATHA (invisible-light-c792e)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions n\'est pas configuré pour le web. '
        'Utilisez la console Firebase pour ajouter une app Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'est pas configuré pour iOS. '
          'Ajoutez une app iOS dans la console Firebase.',
        );
      default:
        throw UnsupportedError(
          'Plateforme non supportée : $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQwMk1AAlvJaxvESjSfyW69GY1YJeHhPk',
    appId: '1:188021898620:android:da81b534ccd0fdb9fa78f9',
    messagingSenderId: '188021898620',
    projectId: 'invisible-light-c792e',
    databaseURL: 'https://invisible-light-c792e-default-rtdb.firebaseio.com',
    storageBucket: 'invisible-light-c792e.firebasestorage.app',
  );
}
