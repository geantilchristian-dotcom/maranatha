import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../direct/pages/direct_page.dart';
import '../../library/pages/library_page.dart';
import '../../program/pages/program_page.dart';

class ChurchBanner extends StatefulWidget {
  const ChurchBanner({super.key, this.height = 220});

  final double height;

  @override
  State<ChurchBanner> createState() => _ChurchBannerState();
}

class _ChurchBannerState extends State<ChurchBanner> {
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  static const String _endpoint = '$_server/api/settings/home';

  static const Color _blue = Color(0xFF0B5CFF);

  final PageController _controller = PageController();

  Timer? _timer;

  List<Map<String, dynamic>> _banners = <Map<String, dynamic>>[];
  bool _loading = true;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _text(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  String _absoluteUrl(String raw) {
    final value = raw.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('//')) return 'https:$value';
    if (value.startsWith('/')) return '$_server$value';

    return '$_server/$value';
  }

  Future<void> _load() async {
    try {
      final response = await http
          .get(
            Uri.parse(_endpoint),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      final banners = <Map<String, dynamic>>[];

      if (decoded is Map && decoded['heroBanners'] is List) {
        for (final raw in decoded['heroBanners'] as List) {
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);

          if (item['active'] == false) continue;

          final imageUrl = _text(item, 'imageUrl');

          if (imageUrl.isEmpty) continue;

          banners.add(item);
        }
      }

      if (!mounted) return;

      setState(() {
        _banners = banners;
        _loading = false;
        _index = 0;
      });

      _startTimer();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _banners = <Map<String, dynamic>>[];
        _loading = false;
        _index = 0;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (_banners.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients || _banners.length < 2) {
        return;
      }

      final next = (_index + 1) % _banners.length;

      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _openLink(Map<String, dynamic> banner) async {
    final link = _text(banner, 'link');

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

    final uri = Uri.tryParse(_absoluteUrl(link));

    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
        ),
      );
    }

    // IMPORTANT :
    // aucun banner de test, aucun asset local de secours.
    // Sans publication admin, la zone disparaît.
    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (value) {
              setState(() {
                _index = value;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];

              final image = _absoluteUrl(_text(banner, 'imageUrl'));

              final title = _text(banner, 'title');
              final body = _text(banner, 'text');
              final reference = _text(banner, 'reference');
              final button = _text(banner, 'buttonLabel');

              return GestureDetector(
                onTap: () {
                  _openLink(banner);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) {
                        return Container(color: const Color(0xFF102A56));
                      },
                    ),

                    if (title.isNotEmpty ||
                        body.isNotEmpty ||
                        reference.isNotEmpty ||
                        button.isNotEmpty)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              Color(0xC7102A56),
                              Color(0x73102A56),
                              Color(0x18102A56),
                              Color(0x00102A56),
                            ],
                          ),
                        ),
                      ),

                    if (title.isNotEmpty ||
                        body.isNotEmpty ||
                        reference.isNotEmpty ||
                        button.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 510),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (title.isNotEmpty)
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Colors.white,
                                      fontSize: 27,
                                      height: 1.02,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),

                                if (body.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Text(
                                    body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Color(0xFFF3F6FB),
                                      fontSize: 10.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],

                                if (reference.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      reference,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        color: Color(0xFFDCE7F8),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                if (button.isNotEmpty) ...<Widget>[
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
                                        fontFamily: 'Manrope',
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          if (_banners.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_banners.length, (index) {
                  final active = index == _index;

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
      ),
    );
  }
}
