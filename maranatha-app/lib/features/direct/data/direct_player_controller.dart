import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../live/data/maranatha_live_audio_service.dart';

class DirectPlayerSnapshot {
  const DirectPlayerSnapshot({
    this.id = '',
    this.title = '',
    this.audioUrl = '',
    this.isPlaying = false,
    this.isPaused = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1,
  });

  final String id;
  final String title;
  final String audioUrl;
  final bool isPlaying;
  final bool isPaused;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final double volume;

  bool get hasAudio => id.isNotEmpty && audioUrl.isNotEmpty;

  factory DirectPlayerSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const DirectPlayerSnapshot();
    }

    int readInt(String key) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double readDouble(String key, double fallback) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return DirectPlayerSnapshot(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString() ?? '',
      isPlaying: map['isPlaying'] == true,
      isPaused: map['isPaused'] == true,
      isLoading: map['isLoading'] == true,
      position: Duration(milliseconds: readInt('positionMs')),
      duration: Duration(milliseconds: readInt('durationMs')),
      volume: readDouble('volume', 1).clamp(0.0, 1.0),
    );
  }
}

class DirectPlayerController extends ChangeNotifier {
  DirectPlayerController();

  static const MethodChannel _channel = MethodChannel('maranatha/live_audio');

  Timer? _timer;

  DirectPlayerSnapshot _state = const DirectPlayerSnapshot();

  DirectPlayerSnapshot get state => _state;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    await refresh();

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      refresh();
    });
  }

  Future<void> refresh() async {
    if (!_android) {
      return;
    }

    try {
      final map = await _channel.invokeMapMethod<dynamic, dynamic>('state');

      final next = DirectPlayerSnapshot.fromMap(map);

      if (_same(_state, next)) {
        return;
      }

      _state = next;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> play({
    required String id,
    required String title,
    required String audioUrl,
  }) async {
    if (_android) {
      await _channel.invokeMethod<void>('start', <String, Object?>{
        'id': id,
        'title': title,
        'audioUrl': audioUrl,
      });

      await refresh();
      return;
    }

    await MaranathaLiveAudioService.instance.start(
      id: id,
      title: title,
      audioUrl: audioUrl,
    );
  }

  Future<void> pause() async {
    if (_android) {
      await _channel.invokeMethod<void>('pause');
      await refresh();
    }
  }

  Future<void> resume() async {
    if (_android) {
      await _channel.invokeMethod<void>('resume');
      await refresh();
    }
  }

  Future<void> toggle() async {
    if (_state.isPlaying) {
      await pause();
      return;
    }

    if (_state.isPaused) {
      await resume();
    }
  }

  Future<void> stop() async {
    if (_android) {
      await _channel.invokeMethod<void>('stop');
      await refresh();
      return;
    }

    await MaranathaLiveAudioService.instance.stop();
  }

  Future<void> seek(Duration position) async {
    if (!_android) {
      return;
    }

    final maxMs = _state.duration.inMilliseconds;

    var target = position.inMilliseconds;

    if (target < 0) {
      target = 0;
    }

    if (maxMs > 0 && target > maxMs) {
      target = maxMs;
    }

    await _channel.invokeMethod<void>('seek', <String, Object?>{
      'positionMs': target,
    });

    await refresh();
  }

  Future<void> seekBy(Duration delta) async {
    await seek(_state.position + delta);
  }

  Future<void> setVolume(double value) async {
    final safe = value.clamp(0.0, 1.0).toDouble();

    if (!_android) {
      return;
    }

    await _channel.invokeMethod<void>('volume', <String, Object?>{
      'value': safe,
    });

    await refresh();
  }

  Future<void> toggleMute() async {
    if (_state.volume <= 0.001) {
      await setVolume(1);
    } else {
      await setVolume(0);
    }
  }

  bool _same(DirectPlayerSnapshot a, DirectPlayerSnapshot b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.audioUrl == b.audioUrl &&
        a.isPlaying == b.isPlaying &&
        a.isPaused == b.isPaused &&
        a.isLoading == b.isLoading &&
        a.position.inMilliseconds == b.position.inMilliseconds &&
        a.duration.inMilliseconds == b.duration.inMilliseconds &&
        (a.volume - b.volume).abs() < 0.001;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
