import 'package:flutter/material.dart';

import 'web_screen.dart';
import 'embedded_bible_screen.dart';

class OfflineShellScreen extends StatefulWidget {
  const OfflineShellScreen({super.key});

  @override
  State<OfflineShellScreen> createState() => _OfflineShellScreenState();
}

class _OfflineShellScreenState extends State<OfflineShellScreen> {
  int _index = 0;

  void _openOnlineDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WebScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F8),
      appBar: AppBar(
        title: const Text('Maranatha'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _HomePanel(onBible: () => setState(() => _index = 1), onOnline: _openOnlineDashboard),
          const EmbeddedBibleScreen(),
          _NetworkRequiredPanel(title: 'Prédication en direct', icon: Icons.live_tv_rounded, description: 'Le direct sera disponible dès que la connexion Internet sera active.', onOpen: _openOnlineDashboard),
          _NetworkRequiredPanel(title: 'Prédications', icon: Icons.headphones_rounded, description: 'Les prédications et les audios récents nécessitent Internet.', onOpen: _openOnlineDashboard),
          _NetworkRequiredPanel(title: 'Téléchargements', icon: Icons.download_rounded, description: 'Les téléchargements sont désactivés hors connexion. Les onglets restent accessibles.', onOpen: _openOnlineDashboard),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Bible'),
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Direct'),
          NavigationDestination(icon: Icon(Icons.headphones_outlined), selectedIcon: Icon(Icons.headphones), label: 'Prédications'),
          NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: 'Plus'),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({required this.onBible, required this.onOnline});

  final VoidCallback onBible;
  final VoidCallback onOnline;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Text('Bienvenue dans Maranatha', style: TextStyle(color: Color(0xFF172033), fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('La Bible reste disponible même sans connexion. Les services connectés se réactivent dès que vous êtes en ligne.', style: TextStyle(color: Color(0xFF687083), fontSize: 15, height: 1.45)),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: const Color(0xFFFFF4F5),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFFC0001A), size: 34),
                  const SizedBox(height: 12),
                  const Text('Bible intégrée', style: TextStyle(color: Color(0xFF172033), fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Les textes français et swahilis sont inclus dans l’application.', style: TextStyle(color: Color(0xFF687083), height: 1.4)),
                  const SizedBox(height: 14),
                  FilledButton.icon(onPressed: onBible, icon: const Icon(Icons.menu_book), label: const Text('Ouvrir la Bible')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: onOnline, icon: const Icon(Icons.cloud_outlined), label: const Text('Ouvrir les services connectés')),
        ],
      ),
    );
  }
}

class _NetworkRequiredPanel extends StatelessWidget {
  const _NetworkRequiredPanel({required this.title, required this.icon, required this.description, required this.onOpen});

  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFC0001A), size: 58),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF172033), fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF687083), fontSize: 15, height: 1.45)),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.open_in_new), label: const Text('Ouvrir quand Internet est disponible')),
          ],
        ),
      ),
    );
  }
}
