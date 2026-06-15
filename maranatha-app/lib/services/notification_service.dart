import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.afficherNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Canal ALARM — importance maximale, réveille l'écran
  static const _androidChannel = AndroidNotificationChannel(
    'maranatha_alarme',
    'Alarmes Maranatha',
    description: 'Sonne automatiquement à l\'heure de la prédication',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  Future<void> initialiser() async {
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, announcement: true,
    );

    // Forcer la livraison des messages de données en foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    // Demander la permission d'alarme exacte (Android 12+)
    await androidPlugin?.requestExactAlarmsPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    FirebaseMessaging.onMessage.listen(afficherNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(afficherNotification);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) afficherNotification(initialMessage);
  }

  Future<void> afficherNotification(RemoteMessage message) async {
    final titre = message.data['sermon_titre'] as String?
        ?? message.notification?.title
        ?? 'Prédication en direct';
    final corps = message.data['type'] == 'PREDICATION_DIRECTE'
        ? '⛪ La prédication vient de commencer. Appuyez pour écouter.'
        : (message.notification?.body ?? '');

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔔 $titre',
      corps,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          // Réveille l'écran même si le téléphone est en veille
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          // S'affiche en bandeau en haut même si app ouverte
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

  Future<String?> obtenirTokenFCM() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }
}
