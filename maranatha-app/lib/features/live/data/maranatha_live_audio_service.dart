import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MaranathaLiveState {
  const MaranathaLiveState({
    this.id = '',
    this.title = '',
    this.audioUrl = '',
    this.isPlaying = false,
    this.webAutoplayBlocked = false,
  });

  final String id;
  final String title;
  final String audioUrl;
  final bool isPlaying;
  final bool webAutoplayBlocked;

  bool get hasLive => id.isNotEmpty && audioUrl.isNotEmpty;
}

class MaranathaLiveAudioService {
  MaranathaLiveAudioService._();

  static final MaranathaLiveAudioService instance =
      MaranathaLiveAudioService._();

  static const String _server = String.fromEnvironment(
    'DIRECT_API_URL',
    defaultValue: 'https://maranatha-1-k6ro.onrender.com',
  );

  static const String _api = '$_server/api';

  static const MethodChannel _channel = MethodChannel('maranatha/live_audio');

  final AudioPlayer _webPlayer = AudioPlayer();

  final StreamController<MaranathaLiveState> _stateController =
      StreamController<MaranathaLiveState>.broadcast();

  final StreamController<String> _openDirectController =
      StreamController<String>.broadcast();

  MaranathaLiveState _state = const MaranathaLiveState();

  Timer? _pollTimer;
  Timer? _syncTimer;

  bool _initialized = false;
  bool _refreshing = false;
  bool _syncing = false;

  MaranathaLiveState get state => _state;

  Stream<MaranathaLiveState> get changes => _stateController.stream;

  Stream<String> get openDirectRequests => _openDirectController.stream;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    _pollTimer?.cancel();
    _syncTimer?.cancel();

    if (_android) {
      _channel.setMethodCallHandler(_handleNativeCall);

      try {
        await _channel.invokeMethod<void>('enable');
      } catch (error) {
        debugPrint('[LIVE] enable Android: $error');
      }

      await syncSchedules();

      try {
        final pending = await _channel.invokeMethod<String>(
          'consumePendingDirect',
        );

        if (pending != null && pending.trim().isNotEmpty) {
          _openDirectController.add(pending.trim());
        }
      } catch (_) {}
    }

    await refresh();

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(refresh());
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_android) {
        unawaited(syncSchedules());
      }
    });
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method != 'openDirect') {
      return null;
    }

    final arguments = call.arguments;

    String id = '';

    if (arguments is Map) {
      id = arguments['id']?.toString().trim() ?? '';
    } else if (arguments != null) {
      id = arguments.toString().trim();
    }

    _openDirectController.add(id);

    return true;
  }

  Future<void> onResume() async {
    await refresh();

    if (_android) {
      await syncSchedules();
    }
  }

  Future<void> refresh() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final response = await http
          .get(
            Uri.parse('$_api/sermons'),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! List) {
        return;
      }

      Map<String, dynamic>? active;

      for (final raw in decoded) {
        if (raw is! Map) {
          continue;
        }

        final item = Map<String, dynamic>.from(raw);

        final status =
            item['statut']?.toString().trim() ??
            item['status']?.toString().trim() ??
            '';
        if (status == 'en_cours') {
          active = item;
          break;
        }
      }

      if (active == null) {
        if (_state.hasLive) {
          await stop();
        }

        return;
      }

      final id =
          (active['_id'] ?? active['id'])?.toString().trim() ?? '';

      final title =
          (active['titre'] ?? active['title'])?.toString().trim() ?? '';

      final url = _absoluteUrl(active['audioUrl']?.toString().trim() ?? '');

      if (id.isEmpty || url.isEmpty) {
        return;
      }

      if (_android) {
        try {
          final dismissed =
              await _channel.invokeMethod<bool>(
                'isDismissed',
                <String, Object?>{'id': id},
              ) ??
              false;

          if (dismissed) {
            if (_state.id == id) {
              _emit(const MaranathaLiveState());
            }

            return;
          }
        } catch (_) {}
      }

      if (_state.id == id && (_state.isPlaying || _state.webAutoplayBlocked)) {
        return;
      }

      await start(
        id: id,
        title: title.isEmpty ? 'Direct MARANATHA' : title,
        audioUrl: url,
      );
    } catch (error) {
      debugPrint('[LIVE] refresh: $error');
    } finally {
      _refreshing = false;
    }
  }

  Future<void> start({
    required String id,
    required String title,
    required String audioUrl,
  }) async {
    final url = _absoluteUrl(audioUrl);

    if (url.isEmpty) {
      return;
    }

    if (_android) {
      try {
        await _channel.invokeMethod<void>('start', <String, Object?>{
          'id': id,
          'title': title,
          'audioUrl': url,
        });

        _emit(
          MaranathaLiveState(
            id: id,
            title: title,
            audioUrl: url,
            isPlaying: true,
          ),
        );
      } catch (error) {
        debugPrint('[LIVE] Android start: $error');
      }

      return;
    }

    await _startWeb(id: id, title: title, audioUrl: url);
  }

  Future<void> _startWeb({
    required String id,
    required String title,
    required String audioUrl,
  }) async {
    try {
      await _webPlayer.stop();

      await _webPlayer.play(UrlSource(audioUrl));

      _emit(
        MaranathaLiveState(
          id: id,
          title: title,
          audioUrl: audioUrl,
          isPlaying: true,
        ),
      );
    } catch (error) {
      debugPrint('[LIVE] navigateur bloque autoplay: $error');

      _emit(
        MaranathaLiveState(
          id: id,
          title: title,
          audioUrl: audioUrl,
          webAutoplayBlocked: true,
        ),
      );
    }
  }

  Future<void> unlockWebAudio() async {
    if (!kIsWeb || !_state.hasLive) {
      return;
    }

    await _startWeb(
      id: _state.id,
      title: _state.title,
      audioUrl: _state.audioUrl,
    );
  }

  Future<void> stop() async {
    if (_android) {
      try {
        await _channel.invokeMethod<void>('stop');
      } catch (_) {}
    } else {
      try {
        await _webPlayer.stop();
      } catch (_) {}
    }

    _emit(const MaranathaLiveState());
  }

  Future<int> syncSchedules() async {
    if (!_android || _syncing) {
      return 0;
    }

    _syncing = true;

    try {
      final response = await http
          .get(Uri.parse('$_api/sermons/upcoming?days=30'))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 0;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! List) {
        return 0;
      }

      final schedules = <Map<String, Object?>>[];

      for (final raw in decoded) {
        if (raw is! Map) {
          continue;
        }

        final id = raw['_id']?.toString().trim() ?? '';

        final title = raw['titre']?.toString().trim() ?? '';

        final audioUrl = _absoluteUrl(raw['audioUrl']?.toString().trim() ?? '');

        final date = DateTime.tryParse(raw['dateDiffusion']?.toString() ?? '');

        if (id.isEmpty || audioUrl.isEmpty || date == null) {
          continue;
        }

        schedules.add(<String, Object?>{
          'id': id,
          'title': title.isEmpty ? 'Direct MARANATHA' : title,
          'audioUrl': audioUrl,
          'triggerAtMillis': date.millisecondsSinceEpoch,
        });
      }

      final result = await _channel.invokeMethod<int>('sync', schedules);

      return result ?? schedules.length;
    } catch (error) {
      debugPrint('[LIVE] synchronisation: $error');

      return 0;
    } finally {
      _syncing = false;
    }
  }

  Future<Map<String, bool>> getPermissions() async {
    if (!_android) {
      return <String, bool>{};
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'permissions',
      );

      return <String, bool>{
        'notifications': result?['notifications'] == true,
        'exactAlarm': result?['exactAlarm'] == true,
        'battery': result?['battery'] == true,
      };
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<Map<String, bool>> getSetupStatus() async {
    if (!_android) {
      return <String, bool>{'completed': true};
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'setupStatus',
      );

      return <String, bool>{
        'notifications': result?['notifications'] == true,
        'exactAlarm': result?['exactAlarm'] == true,
        'battery': result?['battery'] == true,
        'completed': result?['completed'] == true,
      };
    } catch (_) {
      return <String, bool>{'completed': false};
    }
  }

  Future<void> requestNotificationPermission() async {
    if (!_android) {
      return;
    }

    await _channel.invokeMethod<void>('requestNotificationPermission');
  }

  Future<void> requestExactAlarmPermission() async {
    if (!_android) {
      return;
    }

    await _channel.invokeMethod<void>('requestExactAlarm');
  }

  Future<void> requestBatteryPermission() async {
    if (!_android) {
      return;
    }

    await _channel.invokeMethod<void>('requestBattery');
  }

  Future<bool> completeSetup() async {
    if (!_android) {
      return true;
    }

    try {
      return await _channel.invokeMethod<bool>('completeSetup') ?? false;
    } catch (_) {
      return false;
    }
  }

  String _absoluteUrl(String raw) {
    final value = raw.trim();

    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('https://') || value.startsWith('http://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '$_server$value';
    }

    return '$_server/$value';
  }

  void _emit(MaranathaLiveState value) {
    _state = value;

    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }
}
