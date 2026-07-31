import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/app_config.dart';
import '../services/notification_service.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  static const MethodChannel _systemChannel = MethodChannel('maranatha/system');

  late final WebViewController _controller;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<String>? _tokenSubscription;
  Timer? _progressTimer;

  bool _isLoading = true;
  bool _hasMainFrameError = false;
  bool _disposed = false;
  int _progress = 0;
  String _currentTitle = 'Maranatha';
  String _currentAudioUrl = '';

  @override
  void initState() {
    super.initState();

    _tokenSubscription =
        NotificationService.instance.tokenChanges.listen((token) {
      unawaited(_injectFcmToken(token: token));
    });

    _completeSubscription = _player.onPlayerComplete.listen((_) async {
      _progressTimer?.cancel();
      await _stopNativeAudioService();
      await _runJavaScriptSafely(
        'if(window._sermonTermine) window._sermonTermine();',
      );
    });

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('MaranathaMobile/1.2 FlutterWebView')
      ..setBackgroundColor(const Color(0xFFF4F3F8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;
            setState(() => _progress = value);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasMainFrameError = false;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _progress = 100;
            });
            await _injectFcmToken();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true || !mounted) return;
            setState(() {
              _isLoading = false;
              _hasMainFrameError = true;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            final allowed = uri.scheme == 'http' ||
                uri.scheme == 'https' ||
                uri.scheme == 'about' ||
                uri.scheme == 'data' ||
                uri.scheme == 'blob';
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterAudio',
        onMessageReceived: (message) => _handleAudioMessage(message.message),
      );

    _controller = controller;

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      unawaited(
        platformController.setMediaPlaybackRequiresUserGesture(false),
      );
    }

    unawaited(controller.loadRequest(appUri));
  }

  Future<void> _injectFcmToken({String? token}) async {
    token ??= await NotificationService.instance.obtenirTokenFCM();
    if (token == null || token.isEmpty) return;

    await _runJavaScriptSafely(
      'if(window.__onFcmToken) window.__onFcmToken(${jsonEncode(token)});',
    );
  }

  Future<void> _handleAudioMessage(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final action = decoded['action']?.toString() ?? '';
      final url = decoded['url']?.toString().trim() ?? '';
      final title = decoded['titre']?.toString().trim();

      if (title != null && title.isNotEmpty) {
        _currentTitle = title;
      }

      switch (action) {
        case 'autoplay':
          if (url.isEmpty) return;
          await _playUrl(url);
          break;
        case 'toggle':
          if (_player.state == PlayerState.playing) {
            await _player.pause();
            await _systemChannel.invokeMethod<void>('pauseAudioService');
          } else if (_currentAudioUrl.isNotEmpty) {
            await _player.resume();
            if (_player.state != PlayerState.playing) {
              await _playUrl(_currentAudioUrl);
            } else {
              await _startNativeAudioService(_currentTitle);
              _startProgressTimer();
            }
          }
          break;
        case 'seek':
          final percentage = (decoded['pct'] as num?)?.toDouble() ?? 0;
          final duration = await _player.getDuration();
          if (duration != null) {
            final safePercentage = percentage.clamp(0.0, 1.0);
            await _player.seek(
              Duration(
                milliseconds:
                    (duration.inMilliseconds * safePercentage).round(),
              ),
            );
          }
          break;
        case 'skipBack':
          final position = await _player.getCurrentPosition();
          if (position != null) {
            final seconds = (position.inSeconds - 15).clamp(0, 86400).toInt();
            await _player.seek(Duration(seconds: seconds));
          }
          break;
        case 'skipForward':
          final position = await _player.getCurrentPosition();
          final duration = await _player.getDuration();
          if (position != null) {
            final target = position + const Duration(seconds: 15);
            await _player.seek(
              duration != null && target > duration ? duration : target,
            );
          }
          break;
        case 'stop':
          _progressTimer?.cancel();
          await _player.stop();
          await _stopNativeAudioService();
          break;
      }
    } catch (error) {
      debugPrint('Erreur du pont audio WebView : $error');
    }
  }

  Future<void> _playUrl(String url) async {
    _currentAudioUrl = url;
    await _player.stop();
    await _player.setVolume(1);
    await _player.play(
      UrlSource(url),
      mode: PlayerMode.mediaPlayer,
    );
    await _startNativeAudioService(_currentTitle);
    _startProgressTimer();

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!_disposed && _player.state != PlayerState.playing) {
      await _player.stop();
      await _player.play(
        UrlSource(url),
        mode: PlayerMode.mediaPlayer,
      );
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_disposed) return;
      try {
        final position = await _player.getCurrentPosition();
        final duration = await _player.getDuration();
        final playing = _player.state == PlayerState.playing;

        await _runJavaScriptSafely(
          'if(window._flutterUpdate)window._flutterUpdate({'
          'pos:${position?.inSeconds ?? 0},'
          'dur:${duration?.inSeconds ?? 0},'
          'playing:$playing'
          '});',
        );
      } catch (_) {}
    });
  }

  Future<void> _startNativeAudioService(String title) async {
    try {
      await _systemChannel.invokeMethod<void>(
        'startAudioService',
        <String, Object?>{'titre': title},
      );
    } catch (_) {}
  }

  Future<void> _stopNativeAudioService() async {
    try {
      await _systemChannel.invokeMethod<void>('stopAudioService');
    } catch (_) {}
  }

  Future<void> _runJavaScriptSafely(String script) async {
    if (_disposed) return;
    try {
      await _controller.runJavaScript(script);
    } catch (_) {}
  }

  Future<void> _retry() async {
    setState(() {
      _hasMainFrameError = false;
      _isLoading = true;
      _progress = 0;
    });
    await _controller.loadRequest(appUri);
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _disposed = true;
    _progressTimer?.cancel();
    final completeSubscription = _completeSubscription;
    if (completeSubscription != null) {
      unawaited(completeSubscription.cancel());
    }
    final tokenSubscription = _tokenSubscription;
    if (tokenSubscription != null) {
      unawaited(tokenSubscription.cancel());
    }
    unawaited(_player.stop());
    unawaited(_player.dispose());
    unawaited(_stopNativeAudioService());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F3F8),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _hasMainFrameError
                    ? _ConnectionError(onRetry: _retry)
                    : WebViewWidget(controller: _controller),
              ),
              if (_isLoading && !_hasMainFrameError)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: const Color(0xFFF4F3F8),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 34),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xFFC0001A),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Ouverture de Maranatha…',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _progress < 25
                                    ? 'Le serveur peut prendre quelques secondes au premier démarrage.'
                                    : 'Chargement du tableau de bord…',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF7B8294),
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isLoading && !_hasMainFrameError)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress / 100 : null,
                    minHeight: 2.5,
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFFC0001A),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 58,
              color: Color(0xFFC0001A),
            ),
            const SizedBox(height: 20),
            const Text(
              'Impossible d’ouvrir Maranatha',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez votre connexion Internet, puis réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7B8294),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => unawaited(onRetry()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0001A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
