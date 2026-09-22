import 'package:flutter/material.dart';

import '../../bible/pages/bible_loading_page.dart';
import '../../direct/pages/direct_page.dart';
import '../../library/pages/library_page.dart';
import '../../program/pages/program_page.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({super.key});
  static const Color _active = Color(0xFF155EEF);
  static const Color _inactive = Color(0xFF667085);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x18000000),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  active: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Bible',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BibleLoadingPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.podcasts_rounded,
                  label: 'Direct',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DirectPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Programme',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProgramPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.video_library_rounded,
                  label: 'Biblioth\u00E8que',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LibraryPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = active
        ? HomeBottomNavigation._active
        : HomeBottomNavigation._inactive;
    return InkWell(
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: color,
                fontSize: 9.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
