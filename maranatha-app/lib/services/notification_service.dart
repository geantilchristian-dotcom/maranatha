import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

// ── Handler appelé quand l'app est FERMÉE ou en arrière-plan ──────────────
// @pragma('vm:entry-point') est obligatoire : Flutter conserve cette fonction
// même en mode release (tree-shaking).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase si ce n'est pas encore fait (app fermée)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser les notifications locales (contexte isolé sans UI)
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // Créer le canal alarme au cas où il n'existerait pas encore
  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(NotificationService._channel);

  // Afficher la notification plein-écran (réveille l'écran même verrouillé)
  await NotificationService._afficher(localNotifications, message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging        = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Canal partagé — utilisé ici ET dans le background handler
  static const _channel = AndroidNotificationChannel(
    'maranatha_alarme',
    'Alarmes Maranatha',
    description: 'Sonne automatiquement à l\'heure de la prédication',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  Future<void> initialiser() async {
    // Demander les permissions
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, announcement: true,
    );

    // Livrer les messages de données en foreground aussi
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestExactAlarmsPermission();

    // Enregistrer le handler background AVANT initialize()
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // App au premier plan
    FirebaseMessaging.onMessage.listen(
      (msg) => _afficher(_localNotifications, msg),
    );
    // App en arrière-plan, utilisateur tape la notif
    FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _afficher(_localNotifications, msg),
    );
    // App était fermée, utilisateur tape la notif
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _afficher(_localNotifications, initialMessage);
  }

  // ── Méthode statique pour pouvoir l'appeler depuis le background handler ──
  static Future<void> _afficher(
    FlutterLocalNotificationsPlugin plugin,
    RemoteMessage message,
  ) async {
    final titre = message.data['sermon_titre'] as String?
        ?? 'Prédication Maranatha';
    const corps = '⛪ La prédication vient de commencer. Appuyez pour écouter.';

    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔔 $titre',
      corps,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance:   Importance.max,
          priority:     Priority.max,
          playSound:    true,
          enableVibration: true,
          enableLights: true,
          // ── Réveille l'écran même verrouillé (comme WhatsApp) ──
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  // Alias d'instance pour la compatibilité avec l'ancien code
  Future<void> afficherNotification(RemoteMessage message) =>
      _afficher(_localNotifications, message);

  Future<String?> obtenirTokenFCM() async {
    try { return await _messaging.getToken(); }
    catch (e) { return null; }
  }
}
