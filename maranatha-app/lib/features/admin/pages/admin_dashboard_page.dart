import 'package:flutter/material.dart';

import '../models/admin_section.dart';
import '../services/admin_session.dart';
import 'admin_login_page.dart';
import 'admin_section_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE1E7F0);
  AdminSection _section = AdminSection.dashboard;
  bool _mobileMenu = false;
  void _select(AdminSection value) {
    setState(() {
      _section = value;
      _mobileMenu = false;
    });
  }

  void _logout() {
    AdminSession.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AdminLoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          if (desktop) {
            return Row(
              children: [
                SizedBox(
                  width: 245,
                  child: _AdminSidebar(
                    section: _section,
                    onSelected: _select,
                    onLogout: _logout,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: _border),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(desktop: true),
                      Expanded(child: AdminSectionPage(section: _section)),
                    ],
                  ),
                ),
              ],
            );
          }
          return Stack(
            children: [
              Column(
                children: [
                  _topBar(desktop: false),
                  Expanded(child: AdminSectionPage(section: _section)),
                ],
              ),
              if (_mobileMenu)
                Positioned.fill(
                  child: Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.80,
                        child: _AdminSidebar(
                          section: _section,
                          onSelected: _select,
                          onLogout: _logout,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mobileMenu = false;
                            });
                          },
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar({required bool desktop}) {
    return Container(
      height: 69,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (!desktop) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _mobileMenu = true;
                });
              },
              icon: const Icon(Icons.menu_rounded, color: _navy),
            ),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _section.title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _section.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF8491A3), fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            color: const Color(0xFFEEF3FF),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _blue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.section,
    required this.onSelected,
    required this.onLogout,
  });
  final AdminSection section;
  final ValueChanged<AdminSection> onSelected;
  final VoidCallback onLogout;
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    alignment: Alignment.center,
                    color: _blue,
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CEMM Maranatha',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ADMINISTRATION',
                          style: TextStyle(
                            color: _blue,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE1E7F0)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                children: [
                  for (final item in AdminSection.values)
                    _SidebarItem(
                      section: item,
                      selected: section == item,
                      onTap: () {
                        onSelected(item);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE1E7F0)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFF65758B),
                        size: 19,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Deconnexion',
                        style: TextStyle(
                          color: Color(0xFF44536A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });
  final AdminSection section;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? const Color(0xFFEEF3FF) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              border: selected
                  ? const Border(
                      left: BorderSide(color: Color(0xFF003DF0), width: 3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 19,
                  color: selected
                      ? const Color(0xFF003DF0)
                      : const Color(0xFF69778C),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF003DF0)
                          : const Color(0xFF44536A),
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
