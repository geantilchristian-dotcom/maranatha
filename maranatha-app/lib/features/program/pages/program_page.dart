import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key, this.focusId});

  final String? focusId;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  static const String _api =
      'https://maranatha-1-k6ro.onrender.com/api/settings/programme';
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  static const String _cacheKey = 'maranatha_programme_admin_v3';

  static const Color _blue = Color(0xFF0B5CFF);
  static const Color _navy = Color(0xFF102A56);
  static const Color _muted = Color(0xFF71809A);
  static const Color _line = Color(0xFFE2E9F3);
  static const Color _soft = Color(0xFFF4F7FC);

  static const List<_ProgramFilter> _filters = <_ProgramFilter>[
    _ProgramFilter('all', 'À venir'),
    _ProgramFilter('culte', 'Cultes'),
    _ProgramFilter('jeunes', 'Jeunes'),
    _ProgramFilter('priere', 'Prière'),
    _ProgramFilter('enseignement', 'Enseignements'),
  ];

  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _refreshing = false;
  String _selected = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  String _id(Map<String, dynamic> item) {
    return _text(item, const <String>['_id', 'id']);
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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_cacheKey);

    if (cache != null && cache.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(cache);

        if (decoded is List) {
          _items = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;

    if (mounted) {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse(_api),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('programme_http_${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final list = <Map<String, dynamic>>[];

      if (decoded is Map && decoded['items'] is List) {
        for (final raw in decoded['items'] as List) {
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);

          if (item['active'] == false) continue;

          list.add(item);
        }
      }

      list.sort((a, b) {
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(list));

      if (!mounted) return;

      setState(() {
        _items = list;
      });
    } catch (_) {
      // Pas de programme fictif : on garde seulement le cache admin.
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  String _category(Map<String, dynamic> item) {
    final raw = <String>[
      _text(item, const <String>['category', 'categorie', 'type', 'badge']),
      _text(item, const <String>['name', 'title', 'titre']),
    ].join(' ').toLowerCase();

    if (raw.contains('jeune')) return 'jeunes';
    if (raw.contains('prière') || raw.contains('priere')) return 'priere';
    if (raw.contains('enseign')) return 'enseignement';
    if (raw.contains('culte')) return 'culte';

    return 'autre';
  }

  String _badgeLabel(Map<String, dynamic> item) {
    switch (_category(item)) {
      case 'jeunes':
        return 'JEUNES';
      case 'priere':
        return 'PRIÈRE';
      case 'enseignement':
        return 'ENSEIGNEMENT';
      case 'culte':
        return 'CULTE';
      default:
        return 'PROGRAMME';
    }
  }

  Color _badgeBackground(Map<String, dynamic> item) {
    switch (_category(item)) {
      case 'priere':
        return const Color(0xFFFFF0C9);
      case 'enseignement':
        return const Color(0xFFEEE9FF);
      default:
        return const Color(0xFFE6F0FF);
    }
  }

  Color _badgeForeground(Map<String, dynamic> item) {
    switch (_category(item)) {
      case 'priere':
        return const Color(0xFFB36A00);
      case 'enseignement':
        return const Color(0xFF5940D9);
      default:
        return _blue;
    }
  }

  List<Map<String, dynamic>> get _visibleItems {
    final source = _selected == 'all'
        ? List<Map<String, dynamic>>.from(_items)
        : _items.where((item) => _category(item) == _selected).toList();

    final focus = widget.focusId;
    if (focus != null && focus.isNotEmpty) {
      source.sort((a, b) {
        final aa = _id(a) == focus;
        final bb = _id(b) == focus;

        if (aa == bb) return 0;
        return aa ? -1 : 1;
      });
    }

    return source;
  }

  DateTime? _dateOf(Map<String, dynamic> item) {
    return DateTime.tryParse(_text(item, const <String>['date', 'dateStr']));
  }

  String _dayName(DateTime date) {
    const names = <String>[
      'LUN.',
      'MAR.',
      'MER.',
      'JEU.',
      'VEN.',
      'SAM.',
      'DIM.',
    ];

    return names[date.weekday - 1];
  }

  String _month(DateTime date) {
    const months = <String>[
      'JAN.',
      'FÉV.',
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

    return months[date.month - 1];
  }

  String _longDate(DateTime date) {
    const days = <String>[
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    const months = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${days[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _details(Map<String, dynamic> item) {
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
    final date = _dateOf(item);
    final time = _text(item, const <String>['time', 'heure', 'heureStr']);
    final place = _text(item, const <String>['location', 'lieu', 'place']);
    final image = _url(_text(item, const <String>['image', 'imageUrl']));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (image.isNotEmpty) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: _soft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.event_rounded,
                              color: _blue,
                              size: 42,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(
                  title.isEmpty ? 'Programme' : title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (details.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 7),
                  Text(
                    details,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _muted,
                      height: 1.45,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (date != null)
                  _detailLine(Icons.calendar_month_rounded, _longDate(date)),
                _detailLine(Icons.schedule_rounded, time),
                _detailLine(Icons.location_on_outlined, place),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailLine(IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: _blue),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Programme',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _blue,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2.3),
            )
          : SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(14, 14, 14, 6),
                        child: Text(
                          'Les rendez-vous publiés par l’administration.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: _muted,
                            fontSize: 11.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _filterBar(),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Text(
                                    'Aucun programme publié par l’administration.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: _muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  28,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, __) {
                                  return const SizedBox(height: 10);
                                },
                                itemBuilder: (context, index) {
                                  return _programCard(items[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final selected = filter.keyName == _selected;

            return _ProgramTab(
              label: filter.label,
              selected: selected,
              onTap: () {
                setState(() {
                  _selected = filter.keyName;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _programCard(Map<String, dynamic> item) {
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
    final date = _dateOf(item);
    final time = _text(item, const <String>['time', 'heure', 'heureStr']);
    final place = _text(item, const <String>['location', 'lieu', 'place']);
    final image = _url(_text(item, const <String>['image', 'imageUrl']));

    final focused =
        widget.focusId != null &&
        widget.focusId!.isNotEmpty &&
        _id(item) == widget.focusId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () {
          _details(item);
        },
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: focused ? _blue : _line,
              width: focused ? 1.4 : 1,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x080D2340),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 86,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (image.isNotEmpty)
                        Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(color: const Color(0xFF194F93));
                          },
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF0A4C9A),
                                Color(0xFF102A56),
                              ],
                            ),
                          ),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x33000000)),
                      ),
                      if (date != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _dayName(date),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date.day.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _month(date),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${date.year}',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.event_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 7, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title.isEmpty ? 'Programme' : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: _navy,
                                fontSize: 13.8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: _badgeBackground(item),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _badgeLabel(item),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                color: _badgeForeground(item),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (details.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: _muted,
                            fontSize: 10,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (date != null)
                        _miniLine(
                          Icons.calendar_month_rounded,
                          _longDate(date),
                        ),
                      _miniLine(Icons.schedule_rounded, time),
                      _miniLine(Icons.location_on_outlined, place),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 7),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniLine(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 13, color: _muted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: _muted,
                fontSize: 9.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramFilter {
  const _ProgramFilter(this.keyName, this.label);

  final String keyName;
  final String label;
}

class _ProgramTab extends StatelessWidget {
  const _ProgramTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0B5CFF) : const Color(0xFFF4F7FC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0B5CFF)
                  : const Color(0xFFE0E7F1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF102A56),
            ),
          ),
        ),
      ),
    );
  }
}
