import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/notification_service.dart';

const String APP_URL = 'https://www.cemm-eglisemaranatha.site';

class WebScreen extends StatefulWidget {
  const WebScreen({Key? key}) : super(key: key);
  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  bool _loading  = true;
  bool _erreur   = false;
  int  _progress = 0;

  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String   _activeUrl = '';
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;
  Timer? _progressTimer;
  Timer? _autoplayTimer;

  static const _sysChannel = MethodChannel('maranatha/system');

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    AudioPlayer.global.setAudioContext(const AudioContext(
      android: AndroidAudioContext(
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    _durSub   = _player.onDurationChanged.listen((dur) => _duration = dur);
    _posSub   = _player.onPositionChanged.listen((pos) => _position = pos);

    _stateSub = _player.onPlayerStateChanged.listen((state) async {
      final playing = state == PlayerState.playing;
      if (!mounted) return;
      try {
        await _controller.runJavaScript(
          'if(typeof window._flutterUpdate==="function")'
          ' window._flutterUpdate({pos:${_position.inSeconds},'
          'dur:${_duration.inSeconds},playing:$playing})'
        );
      } catch (_) {}
    });

    _completeSub = _player.onPlayerComplete.listen((_) async {
      _progressTimer?.cancel();
      _activeUrl = '';
      if (!mounted) return;
      try {
        await _controller.runJavaScript(
          'if(typeof setPlayIcon==="function") setPlayIcon(false);'
          'if(typeof window._flutterUpdate==="function")'
          ' window._flutterUpdate({pos:0,dur:0,playing:false});'
          'if(typeof window._sermonTermine==="function") window._sermonTermine();'
        );
        await _sysChannel.invokeMethod('stopAudioService');
      } catch (_) {}
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterAudio',
        onMessageReceived: (JavaScriptMessage msg) async {
          try {
            final data   = jsonDecode(msg.message) as Map<String, dynamic>;
            final action = data['action'] as String? ?? '';
            switch (action) {
              case 'autoplay':
                final url   = data['url']   as String? ?? '';
                final titre = data['titre'] as String? ?? 'Prédication';
                if (url.isNotEmpty) {
                  if (url == _activeUrl && _player.state == PlayerState.playing) break;
                  _activeUrl = url;
                  await _player.setReleaseMode(ReleaseMode.stop);
                  await _player.play(UrlSource(url));
                  await _sysChannel.invokeMethod('startAudioService', {'titre': titre});
                  _startProgressTimer();
                }
                break;
              case 'toggle':
                if (_player.state == PlayerState.playing) {
                  await _player.pause();
                  await _sysChannel.invokeMethod('pauseAudioService');
                } else {
                  await _player.resume();
                  await _sysChannel.invokeMethod('startAudioService', {'titre': 'Prédication'});
                }
                break;
              case 'seek':
                final pct = (data['pct'] as num?)?.toDouble() ?? 0;
                final ms  = (_duration.inMilliseconds * pct).round();
                await _player.seek(Duration(milliseconds: ms));
                break;
              case 'skipBack':
                await _player.seek(Duration(seconds: max(0, _position.inSeconds - 10)));
                break;
              case 'skipForward':
                await _player.seek(Duration(seconds: min(_duration.inSeconds, _position.inSeconds + 10)));
                break;
              case 'play':
                await _sysChannel.invokeMethod('startAudioService',
                    {'titre': data['titre'] as String? ?? 'Prédication'});
                break;
              case 'pause':
                await _sysChannel.invokeMethod('pauseAudioService');
                break;
              case 'stop':
                await _player.stop();
                _activeUrl = '';
                _progressTimer?.cancel();
                await _sysChannel.invokeMethod('stopAudioService');
                break;
            }
          } catch (_) {}
        },
      );

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _autoplayTimer?.cancel();
            setState(() { _loading = true; _erreur = false; });
          },
          onProgress: (p) => setState(() => _progress = p),
          onPageFinished: (_) async {
            setState(() => _loading = false);
            final token = await NotificationService.instance.obtenirTokenFCM();
            if (token != null && token.isNotEmpty) {
              await _controller.runJavaScript(
                'window.flutterFcmToken = "$token";'
                'if(typeof window.__onFcmToken==="function") window.__onFcmToken("$token");'
              );
            }
            _autoplayTimer?.cancel();
            _autoplayTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
              if (!mounted) return;
              try {
                await _controller.runJavaScript(
                  'if(typeof window._pendingAutoplay==="function")'
                  ' window._pendingAutoplay()'
                );
              } catch (_) {}
            });
          },
          onWebResourceError: (err) {
            if (err.isForMainFrame ?? true) {
              setState(() { _loading = false; _erreur = true; });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(APP_URL));
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final playing = _player.state == PlayerState.playing;
      try {
        await _controller.runJavaScript(
          'if(typeof window._flutterUpdate==="function")'
          ' window._flutterUpdate({pos:${_position.inSeconds},'
          'dur:${_duration.inSeconds},playing:$playing})'
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _durSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _progressTimer?.cancel();
    _autoplayTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) { await _controller.goBack(); return false; }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: _erreur ? _buildErreur() : WebViewWidget(controller: _controller),
            ),
            if (_loading && _progress < 100 && _progress > 0)
              Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  value: _progress / 100, minHeight: 3,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFC0001A),
                ),
              ),
            if (_loading && _progress < 15)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.church, size: 90, color: Color(0xFFC0001A)),
                      const SizedBox(height: 16),
                      const Text('MARANATHA', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        letterSpacing: 3, color: Color(0xFFC0001A),
                      )),
                      const SizedBox(height: 40),
                      const SizedBox(width: 32, height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFC0001A))),
                      const SizedBox(height: 16),
                      const Text('Chargement…', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Color(0xFFC0001A)),
            const SizedBox(height: 24),
            const Text("Impossible de charger l'application",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            const Text('Vérifiez votre connexion Internet et réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0001A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() { _erreur = false; _loading = true; });
                _controller.loadRequest(Uri.parse(APP_URL));
              },
            ),
          ],
        ),
      ),
    );
  }
}
