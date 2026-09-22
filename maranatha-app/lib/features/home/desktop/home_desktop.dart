import '../../profile/pages/profile_page.dart';
import '../../direct/pages/direct_page.dart';
import '../../library/pages/library_page.dart';
import '../../program/pages/program_page.dart';
import '../../search/pages/global_search_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../user/pages/user_modules.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../bible/pages/bible_loading_page.dart';

class HomeDesktop extends StatelessWidget {
  const HomeDesktop({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DesktopHeader(
              onBiblePressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return const BibleLoadingPage();
                    },
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesktopHero(),
                  SizedBox(height: 14),
                  _SearchAndMember(),
                  SizedBox(height: 14),
                  _DesktopVerse(),
                  SizedBox(height: 18),
                  _ActivitiesHeader(),
                  SizedBox(height: 10),
                  _DesktopActivities(),
                  SizedBox(height: 18),
                  _WordOfDayButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.onBiblePressed});
  final VoidCallback onBiblePressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6EBF2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 9),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEMM Maranatha',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'IL VIENT BIENT\u00d4T',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.primary,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          const _DesktopNavItem(
            icon: AppIcons.home,
            label: 'Accueil',
            active: true,
          ),
          _DesktopNavItem(
            icon: AppIcons.bible,
            label: 'Bible',
            onTap: onBiblePressed,
          ),
          const _DesktopNavItem(icon: AppIcons.direct, label: 'Direct'),
          const _DesktopNavItem(icon: AppIcons.program, label: 'Programme'),
          _DesktopNavItem(
            icon: AppIcons.library,
            label: 'Biblioth\u00e8que',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LibraryPage()),
              );
            },
          ),
          const SizedBox(width: 16),
          const _HeaderCircle(icon: AppIcons.notification, filled: false),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              openProfilePage(context);
            },
            child: const _HeaderCircle(icon: AppIcons.profile, filled: true),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == 'Direct') {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DirectPage()));
            return;
          }
          if (label == 'Programme') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProgramPage()),
            );
            return;
          }
          if (label == 'Bibliotheque' || label == 'Biblioth\u00e8que') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LibraryPage()),
            );
            return;
          }
          onTap?.call();
        },
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: active
                ? const Border(
                    bottom: BorderSide(color: AppColors.primary, width: 3),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: color,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({required this.icon, required this.filled});
  final IconData icon;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: filled ? Colors.white : AppColors.primary,
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================
class _DesktopHero extends StatelessWidget {
  const _DesktopHero();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 0.18).clamp(265.0, 330.0);
        return SizedBox(
          width: double.infinity,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.homeBanner,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xCF102F52),
                        Color(0x82102F52),
                        Color(0x28102F52),
                        Color(0x00102F52),
                      ],
                      stops: [0.0, 0.34, 0.68, 1.0],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(58, 38, 35, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENSEMBLE',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.2,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Grandir dans Sa Parole',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 36,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Une foi vivante pour aujourd\u2019hui,\n'
                        'un peuple pr\u00eat pour demain.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Color(0xFFF4F7FB),
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      _VisionButton(),
                    ],
                  ),
                ),
                const Positioned(
                  right: 35,
                  bottom: 18,
                  child: Row(
                    children: [_HeroDot(active: true), _HeroDot(), _HeroDot()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VisionButton extends StatelessWidget {
  const _VisionButton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'D\u00e9couvrir notre vision',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 14),
          Icon(AppIcons.next, color: Colors.white, size: 15),
        ],
      ),
    );
  }
}

class _HeroDot extends StatelessWidget {
  const _HeroDot({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 24 : 9,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0x88FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ============================================================
// RECHERCHE + DEVENIR MEMBRE
// ============================================================
class _SearchAndMember extends StatelessWidget {
  const _SearchAndMember();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E6EF)),
              borderRadius: BorderRadius.circular(23),
            ),
            child: TextField(
              readOnly: true,
              showCursor: false,
              onTap: () {
                openGlobalSearch(context);
              },

              style: TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: 'Que cherches-tu aujourd\u2019hui ?',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
                prefixIcon: Icon(
                  AppIcons.search,
                  color: AppColors.navy,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: () {
              openMemberRegistration(context);
            },
            borderRadius: BorderRadius.circular(9),
            child: const SizedBox(
              width: 185,
              height: 46,
              child: Center(
                child: Text(
                  'Devenir membre',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// VERSET DU JOUR PC
// ============================================================
class _DesktopVerse extends StatelessWidget {
  const _DesktopVerse();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 160,
            padding: const EdgeInsets.fromLTRB(24, 18, 18, 15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A7AFF), Color(0xFF003DF0)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VERSET\nDU JOUR',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Colors.white,
                    fontSize: 8.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 24,
                  child: Divider(
                    height: 2,
                    thickness: 1.5,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Icon(AppIcons.bible, size: 25, color: Colors.white),
                Spacer(),
                _DesktopTodayDate(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.verseBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                  filterQuality: FilterQuality.high,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFF9FCFF),
                        Color(0xF4F9FCFF),
                        Color(0xC5F9FCFF),
                        Color(0x55FFFFFF),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(30, 20, 28, 18),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u00AB Car je connais les projets que j\u2019ai form\u00E9s '
                                'sur vous, projets de paix et non de mal, afin de vous '
                                'donner un avenir et une esp\u00E9rance. \u00BB',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  color: AppColors.navy,
                                  fontSize: 15.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'J\u00E9r\u00E9mie 29:11',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'UNE FOI  \u2022  UN PEUPLE  \u2022  UNE MISSION',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
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

class _DesktopTodayDate extends StatefulWidget {
  const _DesktopTodayDate();
  @override
  State<_DesktopTodayDate> createState() => _DesktopTodayDateState();
}

class _DesktopTodayDateState extends State<_DesktopTodayDate> {
  Timer? _timer;
  late DateTime _today;
  static const List<String> _months = <String>[
    'JANV.',
    'F\u00c9VR.',
    'MARS',
    'AVR.',
    'MAI',
    'JUIN',
    'JUIL.',
    'AO\u00dbT',
    'SEPT.',
    'OCT.',
    'NOV.',
    'D\u00c9C.',
  ];
  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _scheduleNextUpdate();
  }

  void _scheduleNextUpdate() {
    _timer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _timer = Timer(tomorrow.difference(now), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _today = DateTime.now();
      });
      _scheduleNextUpdate();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = _today.day.toString().padLeft(2, '0');
    final month = _months[_today.month - 1];
    return Text(
      '$day $month\n${_today.year}',
      style: const TextStyle(
        fontFamily: 'Manrope',
        color: Colors.white,
        fontSize: 7,
        height: 1.35,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ============================================================
// ACTIVITES
// ============================================================
class _ActivitiesHeader extends StatelessWidget {
  const _ActivitiesHeader();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Activit\u00e9s r\u00e9centes',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: AppColors.navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
        Text(
          'Voir tout',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 4),
        Icon(AppIcons.next, color: AppColors.primary, size: 14),
      ],
    );
  }
}

class _DesktopActivities extends StatelessWidget {
  const _DesktopActivities();
  static const List<_ActivityData> _items = <_ActivityData>[
    _ActivityData(
      title: 'Moment de pri\u00e8re',
      subtitle: 'Un c\u0153ur tourn\u00e9 vers Dieu',
      date: 'Hier',
      image: AppAssets.prayer,
      icon: AppIcons.prayer,
    ),
    _ActivityData(
      title: 'Enseignement',
      subtitle: 'Grandir dans la v\u00e9rit\u00e9',
      date: 'Il y a 2 jours',
      image: AppAssets.teaching,
      icon: AppIcons.teaching,
    ),
    _ActivityData(
      title: 'Louange',
      subtitle: '\u00c9lever nos c\u0153urs',
      date: 'Il y a 3 jours',
      image: AppAssets.worship,
      icon: AppIcons.worship,
    ),
    _ActivityData(
      title: 'Actualit\u00e9s',
      subtitle: 'Rester inform\u00e9',
      date: 'Il y a 5 jours',
      image: AppAssets.homeBanner,
      icon: AppIcons.library,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final cardWidth = (constraints.maxWidth - gap * 3) / 4;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              SizedBox(
                width: cardWidth,
                child: _ActivityCard(data: _items[index]),
              ),
              if (index < _items.length - 1) const SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _ActivityData {
  const _ActivityData({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.image,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final String date;
  final String image;
  final IconData icon;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.data});
  final _ActivityData data;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.asset(
                  data.image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                left: 13,
                bottom: -15,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE1E7F0)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(data.icon, color: AppColors.primary, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.navy,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Text(
              data.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.textSecondary,
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 0, 13, 9),
            child: Text(
              data.date,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordOfDayButton extends StatelessWidget {
  const _WordOfDayButton();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(7),
          child: const SizedBox(
            width: 165,
            height: 42,
            child: Center(
              child: Text(
                'Parole du jour',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
