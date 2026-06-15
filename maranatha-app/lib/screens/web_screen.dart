import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

    // Barre de statut transparente pour un rendu immersif
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _loading = true;
              _erreur = false;
            });
          },
          onProgress: (p) => setState(() => _progress = p),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (err) {
            // Ignorer les erreurs de sous-ressources (images, fonts, etc.)
            if (err.isForMainFrame ?? true) {
              setState(() {
                _loading = false;
                _erreur = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(APP_URL));
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false; // Empêche la fermeture de l'app
    }
    return true; // Ferme l'app si pas d'historique
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── WebView principal ──
            SafeArea(
              top: false,
              child: _erreur ? _buildErreur() : WebViewWidget(controller: _controller),
            ),

            // ── Barre de progression ──
            if (_loading && _progress < 100)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF5C5CFF),
                ),
              ),

            // ── Écran de chargement initial ──
            if (_loading && _progress < 10)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 100,
                        height: 100,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_fire_department,
                          size: 80,
                          color: Color(0xFF5C5CFF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'MARANATHA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: Color(0xFF5C5CFF),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF5C5CFF),
                        ),
                      ),
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
            const Text(
              'Impossible de charger l\'application',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vérifiez votre connexion Internet\net réessayez.',
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
              label: const Text(
                'Réessayer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _erreur = false;
                  _loading = true;
                });
                _controller.loadRequest(Uri.parse(APP_URL));
              },
            ),
          ],
        ),
      ),
    );
  }
}
