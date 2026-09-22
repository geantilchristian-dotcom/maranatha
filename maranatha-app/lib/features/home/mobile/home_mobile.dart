import '../../profile/pages/profile_page.dart';
import '../../search/pages/global_search_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../user/pages/user_modules.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/maranatha_drawer.dart';

class HomeMobile extends StatefulWidget {
  const HomeMobile({super.key});
  @override
  State<HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<HomeMobile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const MaranathaDrawer(),
      bottomNavigationBar: const HomeBottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 105),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _MobileHeader(
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  const SizedBox(height: 12),
                  const _MobileHero(),
                  const SizedBox(height: 12),
                  const _SearchAndMember(),
                  const SizedBox(height: 12),
                  const _MobileVerse(),
                  const SizedBox(height: 20),
                  const _ActivitiesHeader(),
                  const SizedBox(height: 10),
                  const _MobileActivities(),
                  const SizedBox(height: 16),

                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onMenuPressed});
  final VoidCallback onMenuPressed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuPressed,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppAssets.appIcon,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'CEMM Maranatha',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.navy,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {
              openProfilePage(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
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
                    Color(0xD0123154),
                    Color(0x8A123154),
                    Color(0x30123154),
                    Color(0x00123154),
                  ],
                  stops: [0.0, 0.40, 0.72, 1.0],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 14, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENSEMBLE',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.8,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Grandir\ndans Sa Parole',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontSize: 31,
                      height: 0.96,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Une foi vivante pour aujourdâ€™hui,\n'
                    'un peuple prÃªt pour demain.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Color(0xFFF5F7FA),
                      fontSize: 9.5,
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
              right: 15,
              bottom: 11,
              child: Row(children: [_Dot(active: true), _Dot(), _Dot()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisionButton extends StatelessWidget {
  const _VisionButton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DÃ©couvrir notre vision',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 9),
          Icon(AppIcons.next, color: Colors.white, size: 13),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 16 : 7,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0x88FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _SearchAndMember extends StatelessWidget {
  const _SearchAndMember();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E6F0)),
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
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'Que cherches-tu aujourdâ€™hui ?',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                ),
                prefixIcon: Icon(
                  AppIcons.search,
                  color: AppColors.navy,
                  size: 19,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              openMemberRegistration(context);
            },
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 110,
              height: 48,
              child: Center(
                child: Text(
                  'Devenir membre',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Colors.white,
                    fontSize: 9,
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

class _MobileVerse extends StatelessWidget {
  const _MobileVerse();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // ==================================================
            // BANDE BLEUE GAUCHE
            // ==================================================
            Container(
              width: 82,
              padding: const EdgeInsets.fromLTRB(12, 15, 8, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C7DFF), Color(0xFF003DF0)],
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
                      fontSize: 7.2,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 9),
                  SizedBox(
                    width: 20,
                    child: Divider(
                      color: Colors.white,
                      height: 2,
                      thickness: 1.5,
                    ),
                  ),
                  SizedBox(height: 14),
                  Icon(AppIcons.bible, color: Colors.white, size: 23),
                  Spacer(),
                  // DATE AUTOMATIQUE EN BAS
                  _AutoTodayDate(),
                ],
              ),
            ),
            // ==================================================
            // PARTIE DROITE
            // ==================================================
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
                          Color(0xC4F9FCFF),
                          Color(0x55FFFFFF),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(17, 16, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u00AB Car je connais les projets que j\u2019ai form\u00E9s '
                          'sur vous, projets de paix et non de mal, afin '
                          'de vous donner un avenir et une esp\u00E9rance. \u00BB',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.navy,
                            fontSize: 10.7,
                            height: 1.37,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'J\u00E9r\u00E9mie 29:11',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.textSecondary,
                            fontSize: 7.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        // THEME DEPLACE EN BAS DU VERSET
                        Text(
                          'UNE FOI  \u2022  UN PEUPLE  \u2022  UNE MISSION',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primary,
                            fontSize: 6.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
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
      ),
    );
  }
}

// ============================================================
// DATE AUTOMATIQUE
// ============================================================
class _AutoTodayDate extends StatefulWidget {
  const _AutoTodayDate();
  @override
  State<_AutoTodayDate> createState() => _AutoTodayDateState();
}

class _AutoTodayDateState extends State<_AutoTodayDate> {
  Timer? _timer;
  late DateTime _today;
  static const List<String> _months = <String>[
    'JANV.',
    'F\u00C9VR.',
    'MARS',
    'AVR.',
    'MAI',
    'JUIN',
    'JUIL.',
    'AO\u00DBT',
    'SEPT.',
    'OCT.',
    'NOV.',
    'D\u00C9C.',
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
    final nextDay = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _timer = Timer(nextDay.difference(now), () {
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
        fontSize: 6.2,
        height: 1.35,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _ActivitiesHeader extends StatelessWidget {
  const _ActivitiesHeader();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Programme \u00E0 venir',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          'Voir tout',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 3),
        Icon(AppIcons.next, color: AppColors.primary, size: 13),
      ],
    );
  }
}

class _MobileActivities extends StatelessWidget {
  const _MobileActivities();
  static const _items = <_ActivityData>[
    _ActivityData(
      title: 'Moment de priÃ¨re',
      subtitle: 'Un cÅ“ur tournÃ© vers Dieu',
      date: 'Hier',
      image: AppAssets.prayer,
      icon: AppIcons.prayer,
    ),
    _ActivityData(
      title: 'Enseignement',
      subtitle: 'Grandir dans la vÃ©ritÃ©',
      date: 'Il y a 2 jours',
      image: AppAssets.teaching,
      icon: AppIcons.teaching,
    ),
    _ActivityData(
      title: 'Louange',
      subtitle: 'Ã‰lever nos cÅ“urs',
      date: 'Il y a 3 jours',
      image: AppAssets.worship,
      icon: AppIcons.worship,
    ),
    _ActivityData(
      title: 'ActualitÃ©s',
      subtitle: 'Rester informÃ©',
      date: 'Il y a 5 jours',
      image: AppAssets.homeBanner,
      icon: AppIcons.library,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 9);
        },
        itemBuilder: (context, index) {
          return _ActivityCard(data: _items[index]);
        },
      ),
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
      width: 135,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                height: 101,
                child: Image.asset(
                  data.image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                left: 10,
                bottom: -14,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE0E6EF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(data.icon, color: AppColors.primary, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.navy,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              data.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 0, 9, 8),
            child: Text(
              data.date,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.textMuted,
                fontSize: 6.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FamilyStrip extends StatelessWidget {
  const _FamilyStrip();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          // Page Parole du jour a connecter ensuite.
        },
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: double.infinity,
          height: 46,
          child: Center(
            child: Text(
              'Parole du jour',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
