import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Handler appelé dans un isolate séparé quand l'app est FERMÉE ou TUÉE
// @pragma obligatoire : empêche le tree-shaking en mode release
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialiser Firebase dans cet isolate (requis, contexte séparé)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Initialiser flutter_local_notifications indépendamment
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // 3. Créer le canal alarme s'il n'existe pas encore dans cet isolate
  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(NotificationService._channel);

  // 4. Afficher la notification plein-écran (réveille l'écran même verrouillé)
  await NotificationService._afficher(localNotifications, message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Canal de communication natif pour les permissions système Android
// ─────────────────────────────────────────────────────────────────────────────
const _sysChannel = MethodChannel('maranatha/system');

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging           = FirebaseMessaging.instance;
  final _localNotifications  = FlutterLocalNotificationsPlugin();

  // Canal partagé — utilisé ici ET dans le background handler (isolate)
  static const _channel = AndroidNotificationChannel(
    'maranatha_alarme',
    'Alarmes Maranatha',
    description: 'Sonne automatiquement à l\'heure de la prédication',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  // ── Initialisation complète ────────────────────────────────────────────────
  Future<void> initialiser() async {

    // 1. Permissions Firebase (notifications)
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, announcement: true,
    );

    // 2. Livrer les messages de données en foreground aussi
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 3. Préparer le plugin Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Créer le canal d'alarme
    await androidPlugin?.createNotificationChannel(_channel);

    // Permission alarme exacte (Android 12+)
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}

    // Permission fullScreenIntent (Android 14+ : doit être accordée manuellement)
    // Ouvre une boîte de dialogue système si non encore accordée
    try {
      await androidPlugin?.requestFullScreenIntentPermission();
    } catch (_) {}

    // ── CRITIQUE : Exclusion optimisation batterie ──────────────────────────
    // Sans ça, Android tue le service Firebase quand l'app est fermée ou que
    // le téléphone est en veille → les messages FCM ne sont jamais reçus.
    // Cette méthode affiche une boîte de dialogue système demandant à l'utilisateur
    // d'autoriser l'app à fonctionner sans restriction de batterie.
    try {
      await _sysChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}

    // 4. Enregistrer le handler background AVANT initialize()
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Initialiser flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 6. Écouter les messages en foreground
    FirebaseMessaging.onMessage.listen(
      (msg) => _afficher(_localNotifications, msg),
    );

    // 7. App en arrière-plan : utilisateur tape la notification
    FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _afficher(_localNotifications, msg),
    );

    // 8. App était fermée : utilisateur tape la notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _afficher(_localNotifications, initialMessage);
  }

  // ── Affichage notification (statique pour être appelée depuis l'isolate) ──
  static Future<void> _afficher(
    FlutterLocalNotificationsPlugin plugin,
    RemoteMessage message,
  ) async {
    final titre = message.data['sermon_titre'] as String? ?? 'Prédication Maranatha';
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
          importance:      Importance.max,
          priority:        Priority.max,
          playSound:       true,
          enableVibration: true,
          enableLights:    true,
          // Réveille l'écran verrouillé (comme WhatsApp)
          fullScreenIntent: true,
          category:    AndroidNotificationCategory.alarm,
          visibility:  NotificationVisibility.public,
          showWhen:    true,
          // Vibreur prolongé pour s'assurer que l'utilisateur entend
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
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

  // Alias d'instance (compatibilité)
  Future<void> afficherNotification(RemoteMessage message) =>
      _afficher(_localNotifications, message);

  Future<String?> obtenirTokenFCM() async {
    try { return await _messaging.getToken(); }
    catch (e) { return null; }
  }
}
