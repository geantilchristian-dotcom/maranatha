import 'package:flutter/material.dart';

import '../models/admin_section.dart';

class AdminSectionPage extends StatelessWidget {
  const AdminSectionPage({super.key, required this.section});
  final AdminSection section;
  @override
  Widget build(BuildContext context) {
    if (section == AdminSection.dashboard) {
      return const _DashboardHome();
    }
    return _ModulePlaceholder(section: section);
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tableau de bord',
            style: TextStyle(
              color: Color(0xFF10284A),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Gestion generale de MARANATHA',
            style: TextStyle(color: Color(0xFF748298), fontSize: 11),
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final count = width >= 1100
                  ? 4
                  : width >= 650
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: count,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: count == 1 ? 3.5 : 2.3,
                children: const [
                  _StatCard(
                    title: 'Membres',
                    value: '--',
                    icon: Icons.groups_outlined,
                  ),
                  _StatCard(
                    title: 'Bibliotheque',
                    value: '--',
                    icon: Icons.collections_bookmark_outlined,
                  ),
                  _StatCard(
                    title: 'Programmes',
                    value: '--',
                    icon: Icons.calendar_month_outlined,
                  ),
                  _StatCard(
                    title: 'Messages',
                    value: '--',
                    icon: Icons.forum_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Gestion rapide',
            style: TextStyle(
              color: Color(0xFF10284A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const _InformationPanel(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            color: const Color(0xFFEEF3FF),
            child: Icon(icon, color: const Color(0xFF003DF0), size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF10284A),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF748298),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationPanel extends StatelessWidget {
  const _InformationPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nouvelle administration MARANATHA',
            style: TextStyle(
              color: Color(0xFF10284A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Le tableau de bord est pret. Chaque module sera maintenant connecte a sa vraie base de donnees sans modifier la Bible integree.',
            style: TextStyle(
              color: Color(0xFF68778D),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  const _ModulePlaceholder({required this.section});
  final AdminSection section;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                color: const Color(0xFFEEF3FF),
                child: Icon(
                  section.icon,
                  color: const Color(0xFF003DF0),
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                section.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF10284A),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                section.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF738197),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Module pret a etre connecte.',
                style: TextStyle(
                  color: Color(0xFF003DF0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
