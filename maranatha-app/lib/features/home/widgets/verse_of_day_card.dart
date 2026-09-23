import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_icons.dart';
import '../../content/data/maranatha_sync_service.dart';
import 'loading_skeleton.dart';

class VerseOfDayCard extends StatefulWidget {
  const VerseOfDayCard({super.key, this.height = 185});
  final double height;
  @override
  State<VerseOfDayCard> createState() => _VerseOfDayCardState();
}

class _VerseOfDayCardState extends State<VerseOfDayCard> {
  final MaranathaSyncService _sync = MaranathaSyncService.instance;
  Map<String, dynamic>? _verse;
  bool _loadingDailyWord = true;
  bool _officialDailyWordLoaded = false;

  static const String _dailyWordEndpoint =
      'https://maranatha-1-k6ro.onrender.com/api/settings/daily-word';
  @override
  void initState() {
    super.initState();

    /*
     * Afficher tout de suite la derniere valeur synchronisee
     * si elle existe, puis interroger la source officielle.
     */
    _verse = _readVerse();

    _sync.addListener(_syncChanged);

    unawaited(_sync.sync());
    unawaited(_loadOfficialDailyWord());
  }

  @override
  void dispose() {
    _sync.removeListener(_syncChanged);
    super.dispose();
  }

  void _syncChanged() {
    if (!mounted) {
      return;
    }

    /*
     * dailyVerse reste un secours pour compatibilite/offline.
     * Une reponse officielle de /daily-word reste prioritaire.
     */
    if (!_officialDailyWordLoaded) {
      setState(() {
        _verse = _readVerse();
      });
    }
  }

  Future<void> _loadOfficialDailyWord() async {
    try {
      final uri = Uri.parse(
        '$_dailyWordEndpoint?ts=${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await http
          .get(
            uri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      Map<String, dynamic>? next;

      if (decoded is Map) {
        final now = DateTime.now();

        /*
         * Matin jusqu'a 17:59.
         * Soir a partir de 18:00.
         * Si la periode courante n'existe pas, on utilise l'autre.
         */
        final preferred =
            now.hour >= 18 ? 'soir' : 'matin';

        final fallback =
            preferred == 'matin' ? 'soir' : 'matin';

        Object? raw =
            decoded[preferred];

        if (raw is! Map) {
          raw = decoded[fallback];
        }

        if (raw is Map) {
          final publication =
              Map<String, dynamic>.from(raw);

          next = <String, dynamic>{
            ...publication,
            'active':
                publication['active'] != false,
            'text':
                publication['parole'] ??
                publication['text'] ??
                '',
            'reference':
                publication['reference'] ??
                '',
            'backgroundColor':
                publication['backgroundColor'] ??
                '#F5F9FF',
            'textColor':
                publication['textColor'] ??
                '#102A56',
          };
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _officialDailyWordLoaded = true;
        _loadingDailyWord = false;

        /*
         * Si rien n'est publie dans la nouvelle API,
         * on garde la valeur offline/ancienne deja chargee.
         */
        if (next != null) {
          _verse = next;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingDailyWord = false;

        /*
         * En cas de reseau absent, _verse conserve la valeur
         * de MaranathaSyncService.
         */
      });
    }
  }

  Map<String, dynamic>? _readVerse() {
    final home = _sync.home;
    final value = home['dailyVerse'];
    if (value is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  String _text(String key) {
    return (_verse?[key]?.toString() ?? '').trim();
  }

  Color _parseColor(String raw, Color fallback) {
    var value = raw.trim();
    if (value.isEmpty) {
      return fallback;
    }
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    if (value.length != 8) {
      return fallback;
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return fallback;
    }
    return Color(parsed);
  }

  String _todayText() {
    const months = <String>[
      'JANV.',
      'FÉVR.',
      'MARS',
      'AVR.',
      'MAI',
      'JUIN',
      'JUIL.',
      'AOÛT',
      'SEPT.',
      'OCT.',
      'NOV.',
      'DÉC.',
    ];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')} '
        '${months[now.month - 1]}\n'
        '${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_verse == null && (_sync.isSyncing || _loadingDailyWord)) {
      return MaranathaSkeleton(height: widget.height, radius: 0);
    }
    final active = _verse?['active'] == true;
    final verseText = _text('text');
    final reference = _text('reference');
    if (!active || verseText.isEmpty) {
      return const SizedBox.shrink();
    }
    final backgroundColor = _parseColor(
      _text('backgroundColor'),
      const Color(0xFFF5F9FF),
    );
    final textColor = _parseColor(_text('textColor'), const Color(0xFF102A56));
    final sideColor =
        Color.lerp(backgroundColor, Colors.black, 0.16) ?? backgroundColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = width >= 900;
        final tablet = width >= 600 && width < 900;
        final sideWidth = desktop
            ? 155.0
            : tablet
            ? 125.0
            : 82.0;
        final quoteSize = desktop
            ? 15.5
            : tablet
            ? 13.5
            : 10.7;
        final titleSize = desktop
            ? 8.5
            : tablet
            ? 8.0
            : 7.2;
        final refSize = desktop
            ? 9.5
            : tablet
            ? 8.7
            : 7.8;
        final dateSize = desktop
            ? 7.0
            : tablet
            ? 6.7
            : 6.2;
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: textColor.withValues(alpha: 0.10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: sideWidth,
                padding: EdgeInsets.fromLTRB(
                  desktop ? 22 : 12,
                  desktop ? 18 : 15,
                  desktop ? 18 : 8,
                  desktop ? 15 : 12,
                ),
                decoration: BoxDecoration(color: sideColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'VERSET\nDU JOUR',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: textColor,
                        fontSize: titleSize,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: desktop ? 8 : 9),
                    Container(
                      width: desktop ? 24 : 20,
                      height: 2,
                      color: textColor,
                    ),
                    const Spacer(),
                    Icon(
                      AppIcons.bible,
                      color: textColor,
                      size: desktop ? 25 : 23,
                    ),
                    const Spacer(),
                    Text(
                      _todayText(),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: textColor,
                        fontSize: dateSize,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 30 : 17,
                    desktop ? 20 : 16,
                    desktop ? 28 : 14,
                    desktop ? 18 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '« $verseText »',
                        maxLines: desktop ? 4 : 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: textColor,
                          fontSize: quoteSize,
                          height: 1.40,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (reference.isNotEmpty) ...[
                        SizedBox(height: desktop ? 8 : 7),
                        Text(
                          reference,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: textColor.withValues(alpha: 0.72),
                            fontSize: refSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        'UNE FOI  •  UN PEUPLE  •  UNE MISSION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: textColor,
                          fontSize: desktop ? 8 : 6.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
