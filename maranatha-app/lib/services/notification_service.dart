import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const MethodChannel _systemChannel = MethodChannel('maranatha/system');
  static const String _installationIdKey = 'maranatha_installation_id';
  static const String _appVersion = '1.2.0+7';

  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  Timer? _syncTimer;
  bool _initialized = false;
  bool _syncing = false;
  bool _registering = false;

  Stream<String> get tokenChanges => _tokenController.stream;

  Future<void> initialiser() async {
    if (_initialized) return;
    _initialized = true;

    await _publierToken();
    await enregistrerAppareil();
    await synchroniserPredications();

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) async {
        await enregistrerAppareil();
        await synchroniserPredications();
      },
    );
  }

  Future<String?> obtenirTokenFCM() async {
    try {
      final token = await _systemChannel.invokeMethod<String>('getFcmToken');
      final cleaned = token?.trim();
      return cleaned == null || cleaned.isEmpty ? null : cleaned;
    } catch (error) {
      debugPrint('Impossible d’obtenir le token FCM : $error');
      return null;
    }
  }

  Future<Map<String, bool>> obtenirEtatAutorisations() async {
    try {
      final raw = await _systemChannel.invokeMapMethod<String, dynamic>(
        'getAlarmPermissions',
      );

      return <String, bool>{
        'notifications': raw?['notifications'] == true,
        'exactAlarms': raw?['exactAlarms'] == true,
        'fullScreen': raw?['fullScreen'] == true,
        'battery': raw?['battery'] == true,
        'modeEnabled': raw?['modeEnabled'] == true,
      };
    } catch (error) {
      debugPrint('Impossible de vérifier les autorisations : $error');
      return <String, bool>{
        'notifications': false,
        'exactAlarms': false,
        'fullScreen': false,
        'battery': false,
        'modeEnabled': false,
      };
    }
  }

  Future<void> demanderNotifications() async {
    await _systemChannel.invokeMethod<void>('requestNotificationPermission');
  }

  Future<void> demanderAlarmesExactes() async {
    await _systemChannel.invokeMethod<void>('requestExactAlarmPermission');
  }

  Future<void> demanderPleinEcran() async {
    await _systemChannel.invokeMethod<void>(
      'requestFullScreenIntentPermission',
    );
  }

  Future<void> demanderExclusionBatterie() async {
    await _systemChannel.invokeMethod<void>(
      'requestIgnoreBatteryOptimizations',
    );
  }

  Future<void> activerModeMaranatha() async {
    await _systemChannel.invokeMethod<void>(
      'setAlarmModeEnabled',
      <String, Object?>{'enabled': true},
    );
    await enregistrerAppareil(enabledOverride: true);
    await synchroniserPredications();
  }

  Future<void> desactiverModeMaranatha() async {
    await _systemChannel.invokeMethod<void>(
      'setAlarmModeEnabled',
      <String, Object?>{'enabled': false},
    );
    await enregistrerAppareil(enabledOverride: false);
  }

  Future<bool> modeMaranathaActif() async {
    try {
      return await _systemChannel.invokeMethod<bool>('isAlarmModeEnabled') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> enregistrerAppareil({bool? enabledOverride}) async {
    if (_registering) return;
    _registering = true;

    try {
      final token = await obtenirTokenFCM();
      if (token == null) return;

      final installationId = await _obtenirInstallationId();
      final enabled = enabledOverride ?? await modeMaranathaActif();

      final response = await http
          .post(
            Uri.parse('$API_URL/devices/register'),
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, Object?>{
              'installationId': installationId,
              'fcmToken': token,
              'platform': 'android',
              'appVersion': _appVersion,
              'modeMaranathaActif': enabled,
            }),
          )
          .timeout(const Duration(seconds: 70));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Serveur ${response.statusCode}');
      }

      if (!_tokenController.isClosed) {
        _tokenController.add(token);
      }
    } catch (error) {
      debugPrint('Enregistrement de l’appareil impossible : $error');
    } finally {
      _registering = false;
    }
  }

  Future<int> synchroniserPredications() async {
    if (_syncing) return 0;
    _syncing = true;

    try {
      final response = await http
          .get(Uri.parse('$API_URL/sermons/upcoming?days=30'))
          .timeout(const Duration(seconds: 70));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Serveur ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Réponse des prédications invalide');
      }

      final schedules = <Map<String, Object?>>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        final id = item['_id']?.toString().trim() ?? '';
        final title = item['titre']?.toString().trim() ?? '';
        final audioUrl = item['audioUrl']?.toString().trim() ?? '';
        final rawDate = item['dateDiffusion']?.toString();
        final date = rawDate == null ? null : DateTime.tryParse(rawDate);

        if (id.isEmpty || audioUrl.isEmpty || date == null) continue;

        schedules.add(<String, Object?>{
          'id': id,
          'title': title.isEmpty ? 'Prédication Maranatha' : title,
          'audioUrl': audioUrl,
          'triggerAtMillis': date.millisecondsSinceEpoch,
        });
      }

      await _systemChannel.invokeMethod<Object?>(
        'syncSchedules',
        schedules,
      );

      return schedules.length;
    } catch (error) {
      debugPrint('Synchronisation des alarmes impossible : $error');
      return 0;
    } finally {
      _syncing = false;
    }
  }

  Future<String> _obtenirInstallationId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_installationIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final generated = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

    await preferences.setString(_installationIdKey, generated);
    return generated;
  }

  Future<void> _publierToken() async {
    final token = await obtenirTokenFCM();
    if (token != null && !_tokenController.isClosed) {
      _tokenController.add(token);
    }
  }

  Future<void> disposer() async {
    _syncTimer?.cancel();
    await _tokenController.close();
    _initialized = false;
  }
}
