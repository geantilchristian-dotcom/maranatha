import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late WebViewController _controller;
  final AudioPlayer _player = AudioPlayer();

  static const String APP_URL = 'https://www.cemm-eglisemaranatha.site';

  @override
  void initState() {
    super.initState();

    _player.onPlayerComplete.listen((_) {
      // Sermon terminé — pas de boucle
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterAudio',
        onMessageReceived: (msg) => _handleAudioMessage(msg.message),
      )
      ..loadRequest(Uri.parse(APP_URL));
  }

  Future<void> _handleAudioMessage(String message) async {
    final parts = message.split('|');
    final cmd = parts[0];
    final url = parts.length > 1 ? parts[1] : '';

    switch (cmd) {
      case 'PLAY':
        if (url.isNotEmpty) {
          await _player.stop();
          await _player.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
        }
        break;
      case 'STOP':
        await _player.stop();
        await _player.release();
        break;
      case 'PAUSE':
        await _player.pause();
        break;
      case 'RESUME':
        await _player.resume();
        break;
    }
  }

  @override
  void dispose() {
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
