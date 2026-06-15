import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/notification_service.dart';

const String APP_URL = 'https://maranatha-2vgy.onrender.com';

class WebScreen extends StatefulWidget {
  const WebScreen({Key? key}) : super(key: key);

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _erreur = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() { _loading = true; _erreur = false; }),
          onProgress: (p) => setState(() => _progress = p),
          onPageFinished: (_) async {
            setState(() => _loading = false);
            // Injecter le token FCM dans la WebView pour l'inscription
            final token = await NotificationService.instance.obtenirTokenFCM();
            if (token != null && token.isNotEmpty) {
              await _controller.runJavaScript(
                'window.flutterFcmToken = "$token";'
                'if(typeof window.__onFcmToken==="function") window.__onFcmToken("$token");'
              );
            }
          },
          onWebResourceError: (err) {
            if (err.isForMainFrame ?? true) {
              setState(() { _loading = false; _erreur = true; });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(APP_URL));

    // ── Autoriser l'autoplay audio/vidéo sur Android ──
    // (le WebView Android bloque par défaut la lecture sans geste)
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
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
            // ── WebView ──
            SafeArea(
              top: false,
              child: _erreur ? _buildErreur() : WebViewWidget(controller: _controller),
            ),

            // ── Barre de progression ──
            if (_loading && _progress < 100 && _progress > 0)
              Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF5C5CFF),
                ),
              ),

            // ── Écran de chargement initial ──
            if (_loading && _progress < 15)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department, size: 90, color: Color(0xFF5C5CFF)),
                      const SizedBox(height: 12),
                      const Text('MARANATHA', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        letterSpacing: 3, color: Color(0xFF5C5CFF),
                      )),
                      const SizedBox(height: 40),
                      const SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF5C5CFF)),
                      ),
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
            const Icon(Icons.wifi_off, size: 64, color: Color(0xFF5C5CFF)),
            const SizedBox(height: 24),
            const Text('Impossible de charger l\'application',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            const Text('Vérifiez votre connexion Internet\net réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C5CFF),
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
