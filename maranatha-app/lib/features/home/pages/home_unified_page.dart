import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../bible/pages/bible_loading_page.dart';
import '../../direct/pages/direct_page.dart';
import '../../library/pages/library_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../program/pages/program_page.dart';
import '../../search/pages/global_search_page.dart';
import '../../user/pages/user_modules.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/maranatha_drawer.dart';

class HomeUnifiedPage extends StatefulWidget {
  const HomeUnifiedPage({super.key});

  @override
  State<HomeUnifiedPage> createState() => _HomeUnifiedPageState();
}

class _HomeUnifiedPageState extends State<HomeUnifiedPage>
    with SingleTickerProviderStateMixin {
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  static const String _api = '$_server/api';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _bannerController = PageController();

  late final AnimationController _shineController;
  Timer? _bannerTimer;

  List<Map<String, dynamic>> _banners = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _programmes = <Map<String, dynamic>>[];

  int _bannerIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();

    unawaited(_refresh());
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  String _text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final result = value.toString().trim();
      if (result.isNotEmpty) return result;
    }
    return '';
  }

  String _url(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('//')) return 'https:$value';
    if (value.startsWith('/')) return '$_server$value';
    return '$_server/$value';
  }

  Future<void> _refresh() async {
    try {
      final responses = await Future.wait<http.Response>([
        http
            .get(
              Uri.parse('$_api/settings/home'),
              headers: const <String, String>{'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 15)),
        http
            .get(
              Uri.parse('$_api/settings/programme'),
              headers: const <String, String>{'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 15)),
      ]);

      final home = jsonDecode(utf8.decode(responses[0].bodyBytes));
      final programme = jsonDecode(utf8.decode(responses[1].bodyBytes));

      final banners = <Map<String, dynamic>>[];
      if (home is Map && home['heroBanners'] is List) {
        for (final raw in home['heroBanners'] as List) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          if (item['active'] == false) continue;
          if (_text(item, const <String>['imageUrl', 'image']).isEmpty) {
            continue;
          }
          banners.add(item);
        }
      }

      final programmes = <Map<String, dynamic>>[];
      if (programme is Map && programme['items'] is List) {
        for (final raw in programme['items'] as List) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          if (item['active'] == false) continue;
          programmes.add(item);
        }
      }

      programmes.sort((a, b) {
        final da = DateTime.tryParse(
          _text(a, const <String>['date', 'dateStr']),
        );
        final db = DateTime.tryParse(
          _text(b, const <String>['date', 'dateStr']),
        );
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      if (!mounted) return;

      setState(() {
        _banners = banners;
        _programmes = programmes;
        _loading = false;
      });

      _startCarousel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banners = <Map<String, dynamic>>[];
        _programmes = <Map<String, dynamic>>[];
        _loading = false;
      });
    }
  }

  void _startCarousel() {
    _bannerTimer?.cancel();
    if (_banners.length < 2) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _openBanner(Map<String, dynamic> banner) async {
    final link = _text(banner, const <String>['link', 'url']);
    if (link.isEmpty || link == '#') return;

    if (link == '#programme') {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const ProgramPage()));
      return;
    }
    if (link == '#bibliotheque') {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const LibraryPage()));
      return;
    }
    if (link == '#direct') {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const DirectPage()));
      return;
    }

    final uri = Uri.tryParse(_url(link));
    if (uri != null) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }
  }

  void _openProgramme(Map<String, dynamic> item) {
    final id = _text(item, const <String>['_id', 'id']);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgramPage(focusId: id.isEmpty ? null : id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: desktop ? null : const MaranathaDrawer(),
      bottomNavigationBar: desktop ? null : const HomeBottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(desktop),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 28 : 12,
                    desktop ? 16 : 8,
                    desktop ? 28 : 12,
                    desktop ? 36 : 110,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _banner(desktop),
                            const SizedBox(height: 12),
                            _searchAndMember(desktop),
                            const SizedBox(height: 12),
                            _verse(desktop),
                            if (_programmes.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _programmesView(desktop),
                            ],
                          ],
                        ),
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

  Widget _header(bool desktop) {
    return Container(
      height: desktop ? 72 : 58,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6EBF2))),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            InkWell(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ClipOval(
            child: Image.asset(
              AppAssets.appIcon,
              width: desktop ? 42 : 39,
              height: desktop ? 42 : 39,
              fit: BoxFit.cover,
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
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          if (desktop) ...[
            _nav('Accueil', AppIcons.home, () {}, active: true),
            _nav('Bible', AppIcons.bible, () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BibleLoadingPage(),
                ),
              );
            }),
            _nav('Direct', AppIcons.direct, () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DirectPage()),
              );
            }),
            _nav('Programme', AppIcons.program, () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProgramPage()),
              );
            }),
            _nav('Bibliothèque', AppIcons.library, () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LibraryPage()),
              );
            }),
          ],
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
          ),
          InkWell(
            onTap: () => openProfilePage(context),
            borderRadius: BorderRadius.circular(50),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(
    String label,
    IconData icon,
    VoidCallback action, {
    bool active = false,
  }) {
    return InkWell(
      onTap: action,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: active
              ? const Border(
                  bottom: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: active ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner(bool desktop) {
    if (_loading) {
      return SizedBox(
        height: desktop ? 300 : 200,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    final height = desktop
        ? (width * 0.19).clamp(250.0, 340.0)
        : (width * 0.52).clamp(180.0, 235.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _bannerIndex = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final image = _url(
                _text(banner, const <String>['imageUrl', 'image']),
              );
              final title = _text(banner, const <String>['title']);
              final text = _text(banner, const <String>['text']);
              final reference = _text(banner, const <String>['reference']);
              final button = _text(banner, const <String>['buttonLabel']);

              return InkWell(
                onTap: () => unawaited(_openBanner(banner)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) {
                        return Image.asset(
                          AppAssets.homeBanner,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    if (title.isNotEmpty ||
                        text.isNotEmpty ||
                        reference.isNotEmpty ||
                        button.isNotEmpty)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xB8001738),
                              Color(0x52001738),
                              Color(0x00001738),
                            ],
                          ),
                        ),
                      ),
                    if (title.isNotEmpty ||
                        text.isNotEmpty ||
                        reference.isNotEmpty ||
                        button.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 50 : 18,
                          desktop ? 34 : 18,
                          18,
                          18,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: desktop ? 520 : 250,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (title.isNotEmpty)
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Colors.white,
                                      fontSize: desktop ? 34 : 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.02,
                                    ),
                                  ),
                                if (text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Colors.white,
                                      fontSize: desktop ? 13 : 10,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                                if (reference.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    reference,
                                    style: TextStyle(
                                      color: const Color(0xFFE7EEFF),
                                      fontSize: desktop ? 10 : 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (button.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Text(
                                      button,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _shineController,
                      builder: (context, child) {
                        final left = -0.45 + (1.8 * _shineController.value);
                        return FractionalTranslation(
                          translation: Offset(left, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Transform.rotate(
                              angle: -0.22,
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 0.18,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0x00FFFFFF),
                                      Color(0x0FFFFFFF),
                                      Color(0x65FFFFFF),
                                      Color(0x18FFFFFF),
                                      Color(0x00FFFFFF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          if (_banners.length > 1) ...[
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                color: const Color(0x66000000),
                child: Text(
                  '${_bannerIndex + 1}/${_banners.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_banners.length, (index) {
                  final active = index == _bannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 20 : 7,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : const Color(0x88FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchAndMember(bool desktop) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextField(
              readOnly: true,
              showCursor: false,
              onTap: () => openGlobalSearch(context),
              decoration: InputDecoration(
                hintText: 'Que cherches-tu aujourd’hui ?',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.navy,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE0E6F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: desktop ? 180 : 110,
          height: 48,
          child: FilledButton(
            onPressed: () => openMemberRegistration(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Devenir membre',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _verse(bool desktop) {
    return Container(
      width: double.infinity,
      height: desktop ? 150 : 145,
      color: const Color(0xFFF7FAFF),
      child: Row(
        children: [
          Container(
            width: desktop ? 150 : 80,
            padding: EdgeInsets.all(desktop ? 20 : 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                Spacer(),
                Icon(Icons.menu_book_rounded, color: Colors.white),
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
                  alignment: Alignment.centerRight,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF7FAFF),
                        Color(0xEAF7FAFF),
                        Color(0x77FFFFFF),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(desktop ? 24 : 15),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '« Car je connais les projets que j’ai formés sur vous, '
                        'projets de paix et non de mal, afin de vous donner '
                        'un avenir et une espérance. »',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppColors.navy,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Jérémie 29:11',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppColors.textSecondary,
                          fontSize: 9,
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

  Widget _programmesView(bool desktop) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = desktop ? (width * 0.23).clamp(260.0, 360.0) : 245.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Programme à venir',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProgramPage()),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: desktop ? 230 : 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _programmes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _programmes[index];
              return SizedBox(width: cardWidth, child: _programmeCard(item));
            },
          ),
        ),
      ],
    );
  }

  Widget _programmeCard(Map<String, dynamic> item) {
    final title = _text(item, const <String>[
      'name',
      'title',
      'titre',
      'badge',
    ]);
    final details = _text(item, const <String>[
      'details',
      'description',
      'theme',
    ]);
    final date = _text(item, const <String>['date', 'dateStr']);
    final time = _text(item, const <String>['time', 'heure', 'heureStr']);
    final place = _text(item, const <String>['location', 'lieu', 'place']);
    final image = _url(_text(item, const <String>['image', 'imageUrl']));

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openProgramme(item),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 115,
                width: double.infinity,
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFFEEF3FF),
                        child: const Icon(
                          Icons.event_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFEEF3FF),
                            child: const Icon(
                              Icons.event_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Programme' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        <String>[
                          date,
                          time,
                          place,
                        ].where((value) => value.isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
