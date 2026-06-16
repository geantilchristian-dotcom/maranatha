import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late WebViewController _controller;
  final AudioPlayer _player = AudioPlayer();
  Timer? _progressTimer;

  static const String APP_URL = 'https://www.cemm-eglisemaranatha.site';

  @override
  void initState() {
    super.initState();

    _player.onPlayerComplete.listen((_) {
      _progressTimer?.cancel();
      _controller.runJavaScript(
        'if(window._sermonTermine) window._sermonTermine();',
      );
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterAudio',
        onMessageReceived: (msg) => _handleMessage(msg.message),
      )
      ..loadRequest(Uri.parse(APP_URL));
  }

  Future<void> _handleMessage(String raw) async {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final action = data['action'] as String? ?? '';
      final url = data['url'] as String? ?? '';

      switch (action) {
        case 'autoplay':
          if (url.isNotEmpty) {
            await _player.stop();
            await _player.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
            _startProgressTimer();
          }
          break;
        case 'toggle':
          if (_player.state == PlayerState.playing) {
            await _player.pause();
          } else {
            await _player.resume();
          }
          break;
        case 'seek':
          final pct = (data['pct'] as num?)?.toDouble() ?? 0;
          final dur = await _player.getDuration();
          if (dur != null) {
            await _player.seek(
              Duration(milliseconds: (dur.inMilliseconds * pct).round()),
            );
          }
          break;
        case 'skipBack':
          final pos = await _player.getCurrentPosition();
          if (pos != null) {
            final t = (pos.inSeconds - 15).clamp(0, 999999);
            await _player.seek(Duration(seconds: t));
          }
          break;
        case 'skipForward':
          final pos = await _player.getCurrentPosition();
          if (pos != null) {
            await _player.seek(Duration(seconds: pos.inSeconds + 15));
          }
          break;
        case 'stop':
          _progressTimer?.cancel();
          await _player.stop();
          break;
      }
    } catch (_) {}
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final pos = await _player.getCurrentPosition();
      final dur = await _player.getDuration();
      final playing = _player.state == PlayerState.playing;
      _controller.runJavaScript(
        'if(window._flutterUpdate)window._flutterUpdate({'
        'pos:${pos?.inSeconds ?? 0},'
        'dur:${dur?.inSeconds ?? 0},'
        'playing:$playing'
        '});',
      );
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _player.stop();
    _player.release();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
