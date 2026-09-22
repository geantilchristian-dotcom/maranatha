import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../bible/pages/bible_loading_page.dart';
import '../../direct/pages/direct_page.dart';
import '../../library/pages/library_page.dart';
import '../../program/pages/program_page.dart';
import '../../user/pages/user_modules.dart';

class MaranathaDrawer extends StatelessWidget {
  const MaranathaDrawer({super.key});
  void _open(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  ClipOval(
                    child: Image.asset(
                      AppAssets.appIcon,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'CEMM MARANATHA',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: <Widget>[
                  _Item(
                    icon: Icons.home_rounded,
                    title: 'Accueil',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _Item(
                    icon: Icons.menu_book_rounded,
                    title: 'Bible',
                    onTap: () => _open(context, const BibleLoadingPage()),
                  ),
                  _Item(
                    icon: Icons.podcasts_rounded,
                    title: 'Direct',
                    onTap: () => _open(context, const DirectPage()),
                  ),
                  _Item(
                    icon: Icons.calendar_month_rounded,
                    title: 'Programme',
                    onTap: () => _open(context, const ProgramPage()),
                  ),
                  _Item(
                    icon: Icons.video_library_rounded,
                    title: 'Bibliothèque',
                    onTap: () => _open(context, const LibraryPage()),
                  ),
                  const Divider(indent: 18, endIndent: 18),
                  _Item(
                    icon: Icons.edit_note_rounded,
                    title: 'Bloc-note',
                    onTap: () => _open(context, const NotesPage()),
                  ),
                  _Item(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Don',
                    onTap: () => _open(context, const DonationPage()),
                  ),
                  _Item(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Commentaire',
                    onTap: () => _open(context, const CommentsPage()),
                  ),
                  _Item(
                    icon: Icons.settings_rounded,
                    title: 'Paramètres',
                    onTap: () => _open(context, const SettingsPage()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF10284A)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
