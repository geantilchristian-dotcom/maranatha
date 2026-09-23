import '../../../core/widgets/maranatha_cached_network_image.dart';
import '../../home/widgets/loading_skeleton.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'library_reader_pages.dart';

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
  static const Color _red = Color(0xFFC9142D);
  static const Color _redSoft = Color(0xFFFFEEF1);
  static const Color _premiumNavy = Color(0xFF081D43);
  static const Color _premiumMuted = Color(0xFF6F7D93);
  static const Color _premiumLine = Color(0xFFE5EAF1);
  static const Color _premiumPage = Color(0xFFFAFBFD);

  static const List<_LibraryTab> _tabs = <_LibraryTab>[
    _LibraryTab('all', 'Tous', Icons.menu_book_outlined),
    _LibraryTab('book', 'Livres', Icons.menu_book_outlined),
    _LibraryTab('live', 'Prédications', Icons.podcasts_rounded),
    _LibraryTab('audio', 'Audios', Icons.headphones_rounded),
    _LibraryTab('video', 'Vidéos', Icons.play_circle_outline_rounded),
  ];

  final TextEditingController _search = TextEditingController();

  Map<String, List<Map<String, dynamic>>> _library = _emptyLibrary();
  late String _selected;
  bool _loading = true;
  bool _refreshing = false;
  String _query = '';
  final Set<String> _bookmarks = <String>{};
  String _lastOpenedId = '';

  @override
  void initState() {
    super.initState();

    final wanted = widget.initialSection;
    _selected = _tabs.any((tab) => tab.keyName == wanted) ? wanted! : 'all';

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
    _bookmarks
      ..clear()
      ..addAll(
        prefs.getStringList('maranatha_library_bookmarks_v1') ??
            const <String>[],
      );
    _lastOpenedId = prefs.getString('maranatha_library_last_opened_v1') ?? '';

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
    final explicit = _absoluteUrl(
      _text(item, const <String>[
        'couvertureUrl',
        'imageUrl',
        'image',
        'cover',
        'thumbnail',
      ]),
    );

    /*
     * Un ancien contenu Video peut avoir son URL YouTube
     * enregistree dans le champ couverture.
     * On la transforme en vraie miniature.
     */
    final fromExplicitYoutube =
        youtubeThumbnailFromUrl(explicit);

    if (fromExplicitYoutube.isNotEmpty) {
      return fromExplicitYoutube;
    }

    if (explicit.isNotEmpty) {
      return explicit;
    }

    final media = _media(item);

    /*
     * YouTube : miniature officielle de la video.
     */
    final youtube =
        youtubeThumbnailFromUrl(media);

    if (youtube.isNotEmpty) {
      return youtube;
    }

    /*
     * Audio / predication :
     * essayer la vraie pochette ID3 du MP3.
     * Si le MP3 n'en contient pas, Image.network
     * utilisera ensuite son errorBuilder / icone de secours.
     */
    final lower = media.toLowerCase();

    if (
      lower.endsWith('.mp3') ||
      lower.endsWith('.m4a') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.wav') ||
      lower.endsWith('.ogg') ||
      lower.contains('/video/upload/')
    ) {
      return libraryAudioCoverUrl(media);
    }

    return '';
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
    if (_selected != 'all') {
      return List<Map<String, dynamic>>.from(
        _library[_selected] ?? const <Map<String, dynamic>>[],
      );
    }
    final output = <Map<String, dynamic>>[];
    final known = <String>{};
    for (final section in const <String>[
      'recent',
      'book',
      'live',
      'audio',
      'video',
    ]) {
      for (final item in _library[section] ?? const <Map<String, dynamic>>[]) {
        final id = _id(item);
        final key = id.isNotEmpty ? id : '${_title(item)}|${_media(item)}';
        if (key.isNotEmpty && known.add(key)) {
          output.add(item);
        }
      }
    }
    return output;
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

    final kind = _kind(item);
    final title = _title(item);
    final author = _author(item);
    final image = _image(item);

    /*
     * LIVRE / PDF
     * Ne plus envoyer directement le navigateur vers Cloudinary.
     * Le PDF est lu dans MARANATHA.
     */
    if (kind == 'LIVRE') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LibraryPdfPage(
            title: title,
            url: url,
          ),
        ),
      );
      return;
    }

    /*
     * AUDIO / PREDICATION
     * Lecture dans le lecteur MP3 MARANATHA.
     */
    if (kind == 'AUDIO' || kind == 'PRÃ‰DICATION') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LibraryAudioPage(
            title: title,
            author: author,
            url: url,
            imageUrl: image,
            kind: kind,
          ),
        ),
      );
      return;
    }

    /*
     * VIDEO :
     * on garde pour l'instant l'ouverture de la vraie URL.
     * La pochette YouTube est cependant extraite automatiquement.
     */
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
      _message('Impossible dâ€™ouvrir ce contenu.');
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

    if (raw.contains('livre') || raw.contains('book')) {
      return 'LIVRE';
    }

    if (raw.contains('video') || raw.contains('vidÃ©o')) {
      return 'VIDÃ‰O';
    }

    if (raw.contains('audio')) {
      return 'AUDIO';
    }

    if (raw.contains('pred') || raw.contains('prÃ©d')) {
      return 'PRÃ‰DICATION';
    }

    /*
     * Quand nous sommes dans une section prÃ©cise,
     * elle reste prioritaire.
     */
    switch (_selected) {
      case 'book':
        return 'LIVRE';

      case 'video':
        return 'VIDÃ‰O';

      case 'audio':
        return 'AUDIO';

      case 'live':
        return 'PRÃ‰DICATION';
    }

    /*
     * Anciennes publications :
     * dÃ©terminer le type depuis le lien rÃ©el.
     */
    final media = _media(item).toLowerCase();

    if (youtubeThumbnailFromUrl(media).isNotEmpty) {
      return 'VIDÃ‰O';
    }

    if (
      media.endsWith('.mp3') ||
      media.endsWith('.m4a') ||
      media.endsWith('.aac') ||
      media.endsWith('.wav') ||
      media.endsWith('.ogg') ||
      media.contains('/video/upload/')
    ) {
      return 'AUDIO';
    }

    if (
      media.endsWith('.pdf') ||
      media.contains('/raw/upload/')
    ) {
      return 'LIVRE';
    }

    return 'PUBLICATION';
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

  List<Map<String, dynamic>> get _allLibraryItems {
    final result = <Map<String, dynamic>>[];
    final keys = <String>{};
    for (final section in const <String>[
      'recent',
      'book',
      'live',
      'audio',
      'video',
    ]) {
      final source = _library[section] ?? const <Map<String, dynamic>>[];
      for (final item in source) {
        final id = _id(item);
        final key = id.isNotEmpty ? id : '${_title(item)}|${_media(item)}';
        if (key.isNotEmpty && keys.add(key)) {
          result.add(item);
        }
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _sectionItems(String section) {
    return List<Map<String, dynamic>>.from(
      _library[section] ?? const <Map<String, dynamic>>[],
    );
  }

  List<Map<String, dynamic>> get _newItems {
    final recent = _sectionItems('recent');
    if (recent.isNotEmpty) {
      return recent;
    }
    return _allLibraryItems;
  }

  Map<String, dynamic>? get _lastOpenedItem {
    if (_lastOpenedId.isEmpty) {
      return null;
    }
    for (final item in _allLibraryItems) {
      if (_id(item) == _lastOpenedId) {
        return item;
      }
    }
    return null;
  }

  bool _isBookmarked(Map<String, dynamic> item) {
    return _bookmarks.contains(_id(item));
  }

  Future<void> _toggleBookmark(Map<String, dynamic> item) async {
    final id = _id(item);
    if (id.isEmpty) {
      return;
    }
    setState(() {
      if (_bookmarks.contains(id)) {
        _bookmarks.remove(id);
      } else {
        _bookmarks.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'maranatha_library_bookmarks_v1',
      _bookmarks.toList(),
    );
  }

  Future<void> _downloadItem(Map<String, dynamic> item) async {
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
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      _message('Impossible d’ouvrir le téléchargement.');
    }
  }

  void _selectLibraryTab(String value) {
    setState(() {
      _selected = value;
      _query = '';
      _search.clear();
    });
  }

  void _showItemMenu(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 37,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DAE2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.open_in_new_rounded,
                    color: _premiumNavy,
                  ),
                  title: const Text(
                    'Ouvrir',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _open(item);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.download_rounded,
                    color: _premiumNavy,
                  ),
                  title: const Text(
                    'Télécharger',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadItem(item);
                  },
                ),
                ListTile(
                  leading: Icon(
                    _isBookmarked(item)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _red,
                  ),
                  title: Text(
                    _isBookmarked(item)
                        ? 'Retirer des favoris'
                        : 'Ajouter aux favoris',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleBookmark(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _premiumPage,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: _premiumNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 13,
        title: const Text(
          'Bibliothèque',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: _premiumNavy,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
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
                      color: _red,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: _premiumNavy,
                    size: 25,
                  ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _premiumLine),
        ),
      ),
      body: _loading
          ? _premiumLoading()
          : Column(
              children: <Widget>[
                _premiumTabs(),
                _premiumSearch(),
                Expanded(
                  child: _query.trim().isNotEmpty
                      ? _searchResultsView()
                      : _selected == 'all'
                      ? _premiumDashboard()
                      : _premiumCategory(),
                ),
              ],
            ),
    );
  }

  Widget _premiumLoading() {
    return ListView(
      padding: const EdgeInsets.all(13),
      children: <Widget>[
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 49,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 145,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _premiumTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) {
            return const SizedBox(width: 6);
          },
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final selected = tab.keyName == _selected;
            return Material(
              color: selected ? _red : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _selectLibraryTab(tab.keyName);
                },
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _red : const Color(0xFFF0F2F6),
                    ),
                    boxShadow: selected
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x20C9142D),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        tab.icon,
                        size: 16,
                        color: selected ? Colors.white : _premiumNavy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: selected ? Colors.white : _premiumNavy,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _premiumSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _search,
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: _premiumNavy,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un livre, une prédication, un auteur…',
            hintStyle: const TextStyle(
              fontFamily: 'Manrope',
              color: Color(0xFF97A3B5),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _premiumNavy,
              size: 21,
            ),
            filled: true,
            fillColor: const Color(0xFFF7F9FC),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _premiumLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _premiumLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _red, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _premiumDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 26),
          children: <Widget>[
            if (_lastOpenedItem != null) ...<Widget>[
              _resumeCard(_lastOpenedItem!),
              const SizedBox(height: 13),
            ],
            _horizontalSection(
              title: 'Nouveautés',
              items: _newItems,
              section: 'all',
              itemBuilder: _newCard,
            ),
            const SizedBox(height: 15),
            _horizontalSection(
              title: 'Livres',
              items: _sectionItems('book'),
              section: 'book',
              itemBuilder: _bookCard,
            ),
            const SizedBox(height: 16),
            if (compact) ...<Widget>[
              _smallSection(
                title: 'Prédications récentes',
                section: 'live',
                items: _sectionItems('live'),
                audioStyle: false,
              ),
              const SizedBox(height: 13),
              _smallSection(
                title: 'Audios',
                section: 'audio',
                items: _sectionItems('audio'),
                audioStyle: true,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _smallSection(
                      title: 'Prédications récentes',
                      section: 'live',
                      items: _sectionItems('live'),
                      audioStyle: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallSection(
                      title: 'Audios',
                      section: 'audio',
                      items: _sectionItems('audio'),
                      audioStyle: true,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _resumeCard(Map<String, dynamic> item) {
    final image = _image(item);
    final title = _title(item);
    final author = _author(item);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _premiumLine),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A081D43),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Reprendre',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: _premiumNavy,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 58,
                  height: 76,
                  child: image.isEmpty
                      ? Container(
                          color: const Color(0xFFF0F3F7),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.menu_book_outlined,
                            color: _premiumNavy,
                          ),
                        )
                      : Image.network(image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title.isEmpty ? 'Publication MARANATHA' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _premiumNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (author.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _premiumMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E8ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: () {
                  _open(item);
                },
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _horizontalSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required String section,
    required Widget Function(Map<String, dynamic> item) itemBuilder,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: _premiumNavy,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (section == 'all') {
                  return;
                }
                _selectLibraryTab(section);
              },
              style: TextButton.styleFrom(
                foregroundColor: _red,
                padding: const EdgeInsets.symmetric(horizontal: 7),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Voir tout',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: title == 'Livres' ? 224 : 177,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) {
              return const SizedBox(width: 9);
            },
            itemBuilder: (context, index) {
              return itemBuilder(items[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _newCard(Map<String, dynamic> item) {
    final title = _title(item);
    final author = _author(item);
    final image = _image(item);
    return SizedBox(
      width: 91,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          _open(item);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 91,
                height: 125,
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFFF0F3F7),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: _premiumNavy,
                          size: 27,
                        ),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: const Color(0xFFF0F3F7),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.menu_book_outlined,
                              color: _premiumNavy,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title.isEmpty ? 'MARANATHA' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: _premiumNavy,
                fontSize: 8.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (author.isNotEmpty)
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: _premiumMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bookCard(Map<String, dynamic> item) {
    final title = _title(item);
    final image = _image(item);
    final bookmarked = _isBookmarked(item);
    return Container(
      width: 106,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _premiumLine),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0B081D43),
            blurRadius: 11,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                _open(item);
              },
              child: SizedBox(
                width: double.infinity,
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFFF0F3F7),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: _premiumNavy,
                          size: 28,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
            child: Text(
              title.isEmpty ? 'Livre MARANATHA' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: _premiumNavy,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: IconButton(
                    tooltip: 'Favori',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _toggleBookmark(item);
                    },
                    icon: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: bookmarked ? _red : _premiumNavy,
                      size: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Télécharger',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _downloadItem(item);
                    },
                    icon: const Icon(
                      Icons.download_rounded,
                      color: _premiumNavy,
                      size: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Plus',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _showItemMenu(item);
                    },
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _premiumNavy,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallSection({
    required String title,
    required String section,
    required List<Map<String, dynamic>> items,
    required bool audioStyle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _premiumLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _premiumNavy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _selectLibraryTab(section);
                },
                style: TextButton.styleFrom(
                  foregroundColor: _red,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(45, 28),
                ),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 7.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Aucun contenu.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: _premiumMuted,
                    fontSize: 8,
                  ),
                ),
              ),
            )
          else
            ...items.take(2).map((item) {
              return _smallMediaItem(item, audioStyle: audioStyle);
            }),
        ],
      ),
    );
  }

  Widget _smallMediaItem(
    Map<String, dynamic> item, {
    required bool audioStyle,
  }) {
    final title = _title(item);
    final author = _author(item);
    final image = _image(item);
    return InkWell(
      onTap: () {
        _open(item);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 51,
                height: 51,
                child: audioStyle
                    ? Container(
                        color: const Color(0xFFF1F4FA),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: _premiumNavy,
                          size: 24,
                        ),
                      )
                    : image.isEmpty
                    ? Container(
                        color: const Color(0xFFF1F4FA),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.play_circle_outline_rounded,
                          color: _premiumNavy,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Image.network(image, fit: BoxFit.cover),
                          const Center(
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: _premiumNavy,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title.isEmpty ? 'Publication MARANATHA' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _premiumNavy,
                      fontSize: 8.7,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (author.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _premiumMuted,
                        fontSize: 7.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                _showItemMenu(item);
              },
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: _premiumNavy,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumCategory() {
    final items = _items;
    if (items.isEmpty) {
      return _emptyCategory();
    }
    if (_selected == 'book') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 650
              ? 4
              : constraints.maxWidth >= 470
              ? 3
              : 2;
          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 26),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 11,
              childAspectRatio: .62,
            ),
            itemBuilder: (context, index) {
              return _categoryBook(items[index]);
            },
          );
        },
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 26),
      itemCount: items.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 9);
      },
      itemBuilder: (context, index) {
        return _categoryMedia(items[index]);
      },
    );
  }

  Widget _categoryBook(Map<String, dynamic> item) {
    final title = _title(item);
    final author = _author(item);
    final image = _image(item);
    final bookmarked = _isBookmarked(item);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _premiumLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                _open(item);
              },
              child: SizedBox(
                width: double.infinity,
                child: image.isEmpty
                    ? Container(
                        color: const Color(0xFFF0F3F7),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: _premiumNavy,
                          size: 35,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
            child: Text(
              title.isEmpty ? 'Livre MARANATHA' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: _premiumNavy,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (author.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: _premiumMuted,
                  fontSize: 7.5,
                ),
              ),
            ),
          SizedBox(
            height: 39,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      _toggleBookmark(item);
                    },
                    icon: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 19,
                      color: bookmarked ? _red : _premiumNavy,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      _downloadItem(item);
                    },
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 19,
                      color: _premiumNavy,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      _showItemMenu(item);
                    },
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 19,
                      color: _premiumNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryMedia(Map<String, dynamic> item) {
    final image = _image(item);
    final title = _title(item);
    final author = _author(item);
    final kind = _kind(item);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          _open(item);
        },
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _premiumLine),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 77,
                  height: 77,
                  child: image.isEmpty
                      ? Container(
                          color: const Color(0xFFF0F3F7),
                          alignment: Alignment.center,
                          child: Icon(
                            _kindIcon(kind),
                            color: _premiumNavy,
                            size: 27,
                          ),
                        )
                      : Image.network(image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      title.isEmpty ? 'Publication MARANATHA' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: _premiumNavy,
                        fontSize: 11,
                        height: 1.2,
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
                          color: _premiumMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showItemMenu(item);
                },
                icon: const Icon(Icons.more_vert_rounded, color: _premiumNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchResultsView() {
    final items = _items;
    if (items.isEmpty) {
      return _emptyCategory(message: 'Aucun résultat pour cette recherche.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 25),
      itemCount: items.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        return _categoryMedia(items[index]);
      },
    );
  }

  Widget _emptyCategory({
    String message = 'Aucun contenu publié dans cette section.',
  }) {
    return ListView(
      children: <Widget>[
        const SizedBox(height: 90),
        const Icon(
          Icons.video_library_outlined,
          color: Color(0xFF9AA4B3),
          size: 41,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: _premiumMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
