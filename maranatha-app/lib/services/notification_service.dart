import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'audio_service.dart';

// Gestionnaire de fond — doit être une fonction globale (hors de toute classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.lancerPredication(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Canal Android avec priorité maximale = comportement d'alarme
  static const _androidChannel = AndroidNotificationChannel(
    'maranatha_predication',
    'Prédications Maranatha',
    description: 'Canal pour les prédications en direct',
    importance: Importance.max,
    playSound: false,
    enableVibration: true,
  );

  Future<void> initialiser() async {
    // 1. Demander la permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
    );

    // 2. Créer le canal Android haute priorité
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 3. Gestionnaire arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Initialiser les notifications locales
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // 5. Configurer les gestionnaires selon l'état de l'app
    await _configurerGestionnaires();

    print('✅ NotificationService initialisé');
  }

  Future<void> _configurerGestionnaires() async {
    // App EN PREMIER PLAN
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notification reçue (app ouverte) : ${message.data}');
      lancerPredication(message);
    });

    // App EN ARRIÈRE-PLAN — l'utilisateur tape la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Notification ouverte (arrière-plan) : ${message.data}');
      lancerPredication(message);
    });

    // App FERMÉE — vérifier si lancée via une notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('📩 App ouverte via notification : ${initialMessage.data}');
      lancerPredication(initialMessage);
    }
  }

  /// Lance la prédication automatiquement comme une alarme
  Future<void> lancerPredication(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] != 'PREDICATION_DIRECTE') return;

    final audioUrl = data['audio_url'] as String?;
    final titre = data['sermon_titre'] as String? ?? 'Prédication';

    if (audioUrl == null || audioUrl.isEmpty) {
      print('⚠️ URL audio manquante dans la notification');
      return;
    }

    print('🔊 Lancement automatique : $titre');

    // Afficher la notification visible sur l'écran
    _afficherNotificationLocale(titre);

    // Lancer l'audio automatiquement (comme une alarme)
    await AudioService.instance.jouerAudio(audioUrl, titre: titre);
  }

  void _afficherNotificationLocale(String titre) {
    _localNotifications.show(
      0,
      '⛪ Prédication en direct',
      titre,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }

  /// Récupère le token FCM de cet appareil (envoyé au backend lors de l'inscription)
  Future<String?> obtenirTokenFCM() async {
    try {
      final token = await _messaging.getToken();
      print('📱 Token FCM obtenu');
      return token;
    } catch (e) {
      print('❌ Erreur récupération token FCM : $e');
      return null;
    }
  }
}
