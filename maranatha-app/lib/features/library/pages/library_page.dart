import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.initialSection, this.focusId});

  final String? initialSection;
  final String? focusId;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const String _server = 'https://maranatha-1-k6ro.onrender.com';
  static const String _api = '$_server/api';
  static const String _cacheKey = 'maranatha_library_admin_v2';

  static const Color _blue = Color(0xFF0B5CFF);
  static const Color _navy = Color(0xFF102A56);
  static const Color _muted = Color(0xFF71809A);
  static const Color _line = Color(0xFFE2E9F3);
  static const Color _soft = Color(0xFFF5F8FD);

  static const List<_LibraryTab> _tabs = <_LibraryTab>[
    _LibraryTab('recent', 'Récents', Icons.history_rounded),
    _LibraryTab('live', 'Prédications', Icons.podcasts_rounded),
    _LibraryTab('audio', 'Audios', Icons.headphones_rounded),
    _LibraryTab('video', 'Vidéos', Icons.play_circle_outline_rounded),
    _LibraryTab('book', 'Livres', Icons.menu_book_rounded),
  ];

  final TextEditingController _search = TextEditingController();

  Map<String, List<Map<String, dynamic>>> _library = _emptyLibrary();
  late String _selected;
  bool _loading = true;
  bool _refreshing = false;
  String _query = '';

  @override
  void initState() {
    super.initState();

    final wanted = widget.initialSection;
    _selected = _tabs.any((tab) => tab.keyName == wanted) ? wanted! : 'recent';

    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static Map<String, List<Map<String, dynamic>>> _emptyLibrary() {
    return <String, List<Map<String, dynamic>>>{
      'recent': <Map<String, dynamic>>[],
      'live': <Map<String, dynamic>>[],
      'audio': <Map<String, dynamic>>[],
      'video': <Map<String, dynamic>>[],
      'book': <Map<String, dynamic>>[],
    };
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null && cached.trim().isNotEmpty) {
      try {
        final parsed = _normalize(jsonDecode(cached));
        if (parsed != null) {
          _library = parsed;
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
            Uri.parse('$_api/library/state'),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('library_http_${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final raw = decoded is Map && decoded.containsKey('value')
          ? decoded['value']
          : decoded;

      final parsed = _normalize(raw);
      if (parsed == null) {
        throw Exception('library_format');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(parsed));

      if (!mounted) return;

      setState(() {
        _library = parsed;
      });
    } catch (_) {
      // Garde le dernier cache réel publié par l'administration.
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Map<String, List<Map<String, dynamic>>>? _normalize(Object? value) {
    if (value is! Map) return null;

    final output = _emptyLibrary();

    for (final key in output.keys) {
      final raw = value[key];

      if (raw is List) {
        output[key] = raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return output;
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

  String _title(Map<String, dynamic> item) {
    return _text(item, const <String>['title', 'titre', 'name', 'badge']);
  }

  String _author(Map<String, dynamic> item) {
    return _text(item, const <String>[
      'auteur',
      'author',
      'pasteur',
      'speaker',
    ]);
  }

  String _description(Map<String, dynamic> item) {
    return _text(item, const <String>[
      'description',
      'details',
      'resume',
      'summary',
    ]);
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

  String _image(Map<String, dynamic> item) {
    return _absoluteUrl(
      _text(item, const <String>[
        'couvertureUrl',
        'imageUrl',
        'image',
        'cover',
        'thumbnail',
      ]),
    );
  }

  String _media(Map<String, dynamic> item) {
    return _absoluteUrl(
      _text(item, const <String>[
        'fichierUrl',
        'audioUrl',
        'youtubeUrl',
        'lienExterne',
        'pdfUrl',
        'url',
      ]),
    );
  }

  List<Map<String, dynamic>> get _sourceItems {
    if (_selected != 'recent') {
      return List<Map<String, dynamic>>.from(
        _library[_selected] ?? const <Map<String, dynamic>>[],
      );
    }

    final recent = _library['recent'] ?? const <Map<String, dynamic>>[];
    if (recent.isNotEmpty) {
      return List<Map<String, dynamic>>.from(recent);
    }

    return <Map<String, dynamic>>[
      ...?_library['book'],
      ...?_library['live'],
      ...?_library['audio'],
      ...?_library['video'],
    ];
  }

  List<Map<String, dynamic>> get _items {
    final source = _sourceItems;
    final query = _query.toLowerCase().trim();

    final filtered = query.isEmpty
        ? source
        : source.where((item) {
            final haystack = <String>[
              _title(item),
              _author(item),
              _description(item),
            ].join(' ').toLowerCase();

            return haystack.contains(query);
          }).toList();

    final focus = widget.focusId;
    if (focus != null && focus.isNotEmpty) {
      filtered.sort((a, b) {
        final aa = _id(a) == focus;
        final bb = _id(b) == focus;

        if (aa == bb) return 0;
        return aa ? -1 : 1;
      });
    }

    return filtered;
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final url = _media(item);

    if (url.isEmpty) {
      _message('Fichier indisponible.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _message('Lien invalide.');
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!opened && mounted) {
      _message('Impossible d’ouvrir ce contenu.');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _kind(Map<String, dynamic> item) {
    final raw = _text(item, const <String>[
      'type',
      'category',
      'categorie',
      'kind',
    ]).toLowerCase();

    if (raw.contains('livre') || raw.contains('book')) return 'LIVRE';
    if (raw.contains('video') || raw.contains('vidéo')) return 'VIDÉO';
    if (raw.contains('audio')) return 'AUDIO';
    if (raw.contains('pred') || raw.contains('préd')) return 'PRÉDICATION';

    switch (_selected) {
      case 'book':
        return 'LIVRE';
      case 'video':
        return 'VIDÉO';
      case 'audio':
        return 'AUDIO';
      case 'live':
        return 'PRÉDICATION';
      default:
        return 'PUBLICATION';
    }
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'LIVRE':
        return Icons.menu_book_rounded;
      case 'VIDÉO':
        return Icons.play_circle_outline_rounded;
      case 'AUDIO':
        return Icons.headphones_rounded;
      case 'PRÉDICATION':
        return Icons.podcasts_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _actionLabel(String kind) {
    switch (kind) {
      case 'LIVRE':
        return 'Lire';
      case 'VIDÉO':
        return 'Regarder';
      case 'AUDIO':
      case 'PRÉDICATION':
        return 'Écouter';
      default:
        return 'Ouvrir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Bibliothèque',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualiser',
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 820;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        children: <Widget>[
                          _filters(),
                          _searchBar(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              desktop ? 22 : 14,
                              15,
                              desktop ? 22 : 14,
                              10,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _selected == 'recent'
                                        ? 'Ajouts récents'
                                        : _tabs
                                              .firstWhere(
                                                (tab) =>
                                                    tab.keyName == _selected,
                                              )
                                              .label,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _navy,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_items.length}',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _content(constraints.maxWidth)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _filters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final selected = tab.keyName == _selected;

            return _FilterTab(
              label: tab.label,
              icon: tab.icon,
              selected: selected,
              onTap: () {
                setState(() {
                  _selected = tab.keyName;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 0),
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _search,
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: _navy,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un livre, une prédication, un auteur…',
            hintStyle: const TextStyle(
              fontFamily: 'Manrope',
              color: Color(0xFF98A5B8),
              fontSize: 11.5,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 21,
              color: _navy,
            ),
            filled: true,
            fillColor: _soft,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _blue, width: 1.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(double width) {
    final items = _items;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Aucun contenu publié dans cette section.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (width < 720) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _mobileCard(items[index]);
        },
      );
    }

    final columns = width >= 1120
        ? 4
        : width >= 820
        ? 3
        : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        return _gridCard(items[index]);
      },
    );
  }

  Widget _mobileCard(Map<String, dynamic> item) {
    final title = _title(item);
    final author = _author(item);
    final image = _image(item);
    final kind = _kind(item);
    final action = _actionLabel(kind);

    final focused =
        widget.focusId != null &&
        widget.focusId!.isNotEmpty &&
        _id(item) == widget.focusId;

    return Container(
      height: 146,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: focused ? _blue : _line,
          width: focused ? 1.4 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x090D2340),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 86,
                height: 128,
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFFEAF1FF),
                        alignment: Alignment.center,
                        child: Icon(_kindIcon(kind), size: 34, color: _blue),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFEAF1FF),
                            alignment: Alignment.center,
                            child: Icon(
                              _kindIcon(kind),
                              size: 34,
                              color: _blue,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _KindBadge(label: kind, icon: _kindIcon(kind)),
                  const SizedBox(height: 7),
                  Text(
                    title.isEmpty ? 'Publication MARANATHA' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _navy,
                      fontSize: 13.5,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.18,
                    ),
                  ),
                  if (author.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 34,
                      child: FilledButton.icon(
                        onPressed: () {
                          _open(item);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: Icon(_kindIcon(kind), size: 16),
                        label: Text(
                          action,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

  Widget _gridCard(Map<String, dynamic> item) {
    final title = _title(item);
    final author = _author(item);
    final image = _image(item);
    final kind = _kind(item);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          _open(item);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x090D2340),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: double.infinity,
                    child: image.isEmpty
                        ? Container(
                            color: const Color(0xFFEAF1FF),
                            alignment: Alignment.center,
                            child: Icon(
                              _kindIcon(kind),
                              size: 40,
                              color: _blue,
                            ),
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              _KindBadge(label: kind, icon: _kindIcon(kind)),
              const SizedBox(height: 7),
              Text(
                title.isEmpty ? 'Publication MARANATHA' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: _navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (author.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryTab {
  const _LibraryTab(this.keyName, this.label, this.icon);

  final String keyName;
  final String label;
  final IconData icon;
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0B5CFF) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0B5CFF)
                  : const Color(0xFFD9E2EF),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF0B5CFF),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF102A56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF0B5CFF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 8.8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B5CFF),
            ),
          ),
        ],
      ),
    );
  }
}
