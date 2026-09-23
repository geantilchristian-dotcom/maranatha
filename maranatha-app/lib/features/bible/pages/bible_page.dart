import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bible_books.dart';
import '../data/bible_launch_request.dart';
import '../data/bible_repository.dart';
import '../data/bible_search_engine.dart';

enum _BibleViewMode { reader, books, chapters, search }

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});
  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  // ==========================================================
  // COULEURS INSPIREES DU DESIGN FOURNI
  // ==========================================================
  static const Color _verseRed = Color(0xFFC3462D);
  static const Color _verseRedSoft = Color(0xFFFFF3EF);
  static const Color _ink = Color(0xFF40494D);
  static const Color _title = Color(0xFF536A73);
  static const Color _muted = Color(0xFF7A8B91);
  static const Color _icon = Color(0xFF527C85);
  static const Color _line = Color(0xFFD8DDDF);
  static const Color _page = Color(0xFFFCFCFC);
  static const Color _soft = Color(0xFFF3F4F4);
  static const Color _darkPage = Color(0xFF171A1C);
  static const Color _darkCard = Color(0xFF202427);
  static const Color _darkText = Color(0xFFE8E9E9);
  static const String _languageKey = 'maranatha_bible_language_v2';
  static const String _darkKey = 'maranatha_bible_dark_mode_v1';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bookSearchController = TextEditingController();
  final ScrollController _readerController = ScrollController();
  Timer? _searchTimer;
  String _language = 'fr';
  BibleData? _data;
  BibleSearchEngine? _searchEngine;

  final Map<String, BibleSearchEngine>
      _engineCache =
      <String, BibleSearchEngine>{};
  List<BibleSearchResult> _searchResults = <BibleSearchResult>[];
  BibleReference? _directReference;
  int _bookIndex = 0;
  int _chapter = 1;
  int _pendingBookIndex = 0;
  int? _selectedVerse;
  bool _loading = true;
  bool _darkMode = false;
  String? _error;
  String _query = '';
  String _bookQuery = '';
  _BibleViewMode _mode = _BibleViewMode.reader;
  // ==========================================================
  // DONNEES
  // ==========================================================
  List<String> get _books => bibleBooksForLanguage(_language);
  int get _chapterCount {
    final data = _data;
    if (data == null || _bookIndex >= data.chapterCounts.length) {
      return 1;
    }
    final value = data.chapterCounts[_bookIndex];
    return value < 1 ? 1 : value;
  }

  int _chapterCountFor(int bookIndex) {
    final data = _data;
    if (data == null ||
        bookIndex < 0 ||
        bookIndex >= data.chapterCounts.length) {
      return 1;
    }
    final value = data.chapterCounts[bookIndex];
    return value < 1 ? 1 : value;
  }

  List<dynamic> get _chapterVerses {
    final data = _data;
    if (data == null || _bookIndex >= data.books.length) {
      return const <dynamic>[];
    }
    final book = data.books[_bookIndex];
    if (book is! List || _chapter < 1 || _chapter > book.length) {
      return const <dynamic>[];
    }
    final chapter = book[_chapter - 1];
    if (chapter is! List) {
      return const <dynamic>[];
    }
    return chapter;
  }

  // ==========================================================
  // CYCLE DE VIE
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _restorePreferences();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _bookSearchController.dispose();
    _readerController.dispose();
    super.dispose();
  }

  Future<void> _restorePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString(_languageKey);
    final dark = prefs.getBool(_darkKey);
    if (language == 'fr' || language == 'sw') {
      _language = language!;
    }
    _darkMode = dark ?? false;
    await _loadBible(_language, initial: true);
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
  }

  Future<void> _saveDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, _darkMode);
  }

  // ==========================================================
  // CHARGEMENT BIBLE
  // ==========================================================
  Future<void> _preloadBible(
    String language,
  ) async {
    if (
      _engineCache
          .containsKey(language)
    ) {
      return;
    }

    try {
      final bible =
          await BibleRepository
              .instance
              .load(language);

      _engineCache[language] =
          BibleSearchEngine.fromData(
        data: bible,
        language: language,
      );
    } catch (_) {
      // Le chargement normal gÃ¨re l'erreur.
    }
  }

  Future<void> _loadBible(String language, {bool initial = false}) async {
    if (mounted) {
      setState(() {
        _language = language;
        _loading = true;
        _error = null;
        _query = '';
        _searchResults = <BibleSearchResult>[];
        _directReference = null;
      });
    }
    _searchController.clear();
    try {
      final bible = await BibleRepository.instance.load(language);
      final engine =
          _engineCache[language] ??
          BibleSearchEngine.fromData(
            data: bible,
            language: language,
          );

      _engineCache[language] =
          engine;
      if (!mounted) {
        return;
      }
      setState(() {
        _data = bible;
        _searchEngine = engine;
        if (initial) {
          final launch = BibleLaunchRequest.instance.take();
          if (launch != null) {
            _bookIndex = launch.bookIndex;
            _chapter = launch.chapter;
            _selectedVerse = launch.verse;
          }
        }
        if (_bookIndex >= bible.books.length) {
          _bookIndex = 0;
        }
        final count = _chapterCountFor(_bookIndex);
        if (_chapter > count) {
          _chapter = count;
        }
        if (_chapter < 1) {
          _chapter = 1;
        }
        _pendingBookIndex = _bookIndex;
        _loading = false;
        _mode = _BibleViewMode.reader;
      });
      await _saveLanguage();

      final otherLanguage =
          language == 'fr'
              ? 'sw'
              : 'fr';

      unawaited(
        _preloadBible(
          otherLanguage,
        ),
      );
      if (_selectedVerse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future<void>.delayed(
            const Duration(milliseconds: 120),
            _scrollToSelectedVerse,
          );
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Impossible de charger la Bible.\n$error';
      });
    }
  }

  // ==========================================================
  // LANGUE FR / SW
  // ==========================================================
  Future<void> _changeLanguage(String language) async {
    if (language == _language || _loading) {
      return;
    }
    await _loadBible(language);
  }

  // ==========================================================
  // LIVRE / CHAPITRE
  // ==========================================================
  void _openBooks() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _bookQuery = '';
      _bookSearchController.clear();
      _mode = _BibleViewMode.books;
    });
  }

  void _selectBook(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _pendingBookIndex = index;
      _mode = _BibleViewMode.chapters;
    });
  }

  void _selectChapter(int chapter) {
    setState(() {
      _bookIndex = _pendingBookIndex;
      _chapter = chapter;
      _selectedVerse = null;
      _mode = _BibleViewMode.reader;
    });
    if (_readerController.hasClients) {
      _readerController.jumpTo(0);
    }
  }

  void _previousChapter() {
    if (_chapter > 1) {
      _selectChapter(_chapter - 1);
      return;
    }
    if (_bookIndex > 0) {
      final previousBook = _bookIndex - 1;
      _pendingBookIndex = previousBook;
      final lastChapter = _chapterCountFor(previousBook);
      _selectChapter(lastChapter);
    }
  }

  void _nextChapter() {
    if (_chapter < _chapterCount) {
      _selectChapter(_chapter + 1);
      return;
    }
    if (_bookIndex < _books.length - 1) {
      _pendingBookIndex = _bookIndex + 1;
      _selectChapter(1);
    }
  }

  // ==========================================================
  // RECHERCHE
  // ==========================================================
  void _openSearch() {
    setState(() {
      _mode = _BibleViewMode.search;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus();
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    setState(() {
      _query = value;
    });
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = <BibleSearchResult>[];
        _directReference = null;
      });
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 220), () {
      _performSearch(value);
    });
  }

  void _performSearch(String value) {
    final engine = _searchEngine;
    if (engine == null || !mounted) {
      return;
    }
    final query = value.trim();
    if (query.isEmpty) {
      return;
    }
    final direct = engine.parseReference(query);
    final results = engine.search(query, limit: 80);
    if (!mounted) {
      return;
    }
    setState(() {
      _directReference = direct;
      _searchResults = results;
    });
  }

  void _submitSearch(String value) {
    final engine = _searchEngine;
    if (engine == null) {
      return;
    }
    final reference = engine.parseReference(value);
    if (reference != null) {
      _openReference(reference);
      return;
    }
    _performSearch(value);
  }

  void _openReference(BibleReference reference) {
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {
      _bookIndex = reference.bookIndex;
      _pendingBookIndex = reference.bookIndex;
      _chapter = reference.chapter;
      _selectedVerse = reference.verse;
      _query = '';
      _searchResults = <BibleSearchResult>[];
      _directReference = null;
      _mode = _BibleViewMode.reader;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        _scrollToSelectedVerse,
      );
    });
  }

  Future<void> _scrollToSelectedVerse() async {
    final selected = _selectedVerse;
    if (selected == null || !_readerController.hasClients) {
      return;
    }
    final estimated = (selected - 1) * 62.0;
    final max = _readerController.position.maxScrollExtent;
    final target = estimated.clamp(0.0, max);
    await _readerController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  // ==========================================================
  // TEXTE VERSETS
  // ==========================================================
  String _plainText(Object? value) {
    return (value?.toString() ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  String _verseText(Object? verse) {
    if (verse is Map) {
      return _plainText(verse['text']);
    }
    return _plainText(verse);
  }

  int _verseNumber(Object? verse, int fallback) {
    if (verse is Map) {
      final value = verse['verse'];
      if (value is num) {
        return value.toInt();
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  // ==========================================================
  // COULEURS DYNAMIQUES
  // ==========================================================
  Color get _background => _darkMode ? _darkPage : _page;
  Color get _card => _darkMode ? _darkCard : Colors.white;
  Color get _bodyText => _darkMode ? _darkText : _ink;
  Color get _secondaryText => _darkMode ? const Color(0xFFADB7BB) : _muted;
  Color get _divider => _darkMode ? const Color(0xFF343A3D) : _line;
  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: _BibleDrawer(
        language: _language,
        darkMode: _darkMode,
        onDarkMode: _toggleDarkMode,
        onItem: _drawerAction,
      ),
      body: _loading
          ? _loadingView()
          : _error != null
          ? _errorView()
          : Column(
              children: <Widget>[
                // BARRE BIBLE FIXE
                _topBar(),
                // FR / SW FIXE
                _languageBar(),
                Divider(height: 1, color: _divider),
                // SEUL LE CONTENU CI-DESSOUS CHANGE
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _currentView(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _currentView() {
    switch (_mode) {
      case _BibleViewMode.books:
        return _booksView();
      case _BibleViewMode.chapters:
        return _chaptersView();
      case _BibleViewMode.search:
        return _searchView();
      case _BibleViewMode.reader:
        return _readerView();
    }
  }

  // ==========================================================
  // BARRE SUPERIEURE BIBLE
  // ==========================================================
  Widget _topBar() {
    final normal = _mode == _BibleViewMode.reader;
    String title;
    if (_mode == _BibleViewMode.books) {
      title = _language == 'sw' ? 'Vitabu' : 'Livres';
    } else if (_mode == _BibleViewMode.chapters) {
      title = _books[_pendingBookIndex];
    } else if (_mode == _BibleViewMode.search) {
      title = _language == 'sw' ? 'Tafuta' : 'Rechercher';
    } else {
      title = '${_books[_bookIndex]} $_chapter';
    }
    return Container(
      height: 57,
      color: _card,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            child: IconButton(
              tooltip: normal ? 'Menu Bible' : 'Retour',
              onPressed: () {
                if (normal) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() {
                    _mode = _BibleViewMode.reader;
                  });
                }
              },
              icon: Icon(
                normal ? Icons.menu_rounded : Icons.arrow_back_rounded,
                color: _icon,
                size: 27,
              ),
            ),
          ),
          Expanded(
            child: normal
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openBooks,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _darkMode ? _darkText : _title,
                                  fontSize: 21,
                                  height: 1,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: _secondaryText,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _darkMode ? _darkText : _title,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: 44,
            child: normal
                ? IconButton(
                    tooltip: 'Rechercher',
                    onPressed: _openSearch,
                    icon: Icon(Icons.search_rounded, color: _icon, size: 25),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SELECTEUR FR / SW
  // ==========================================================
  Widget _languageBar() {
    return Container(
      height: 45,
      color: _card,
      padding: const EdgeInsets.fromLTRB(70, 5, 70, 6),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _darkMode ? const Color(0xFF2B3033) : const Color(0xFFF0F1F1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: _languageButton('fr', 'FR')),
            Expanded(child: _languageButton('sw', 'SW')),
          ],
        ),
      ),
    );
  }

  Widget _languageButton(String language, String label) {
    final selected = _language == language;
    return Material(
      color: selected ? _card : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: () {
          _changeLanguage(language);
        },
        borderRadius: BorderRadius.circular(5),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _verseRed : _secondaryText,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LECTURE
  // ==========================================================
  Widget _readerView() {
    return Container(
      key: const ValueKey('reader'),
      color: _background,
      child: Column(
        children: <Widget>[
          // TITRE DU CHAPITRE
          Container(
            width: double.infinity,
            color: _card,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            child: Row(
              children: <Widget>[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Chapitre précédent',
                  onPressed: _previousChapter,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: _secondaryText,
                    size: 25,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_books[_bookIndex]} $_chapter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _bodyText,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Chapitre suivant',
                  onPressed: _nextChapter,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryText,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _divider),
          Expanded(
            child: ListView.builder(
              controller: _readerController,
              padding: const EdgeInsets.fromLTRB(20, 16, 18, 46),
              itemCount: _chapterVerses.length,
              itemBuilder: (context, index) {
                final verse = _chapterVerses[index];
                final number = _verseNumber(verse, index + 1);
                return _verseItem(
                  verse: verse,
                  number: number,
                  first: index == 0,
                  selected: number == _selectedVerse,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _verseItem({
    required Object? verse,
    required int number,
    required bool first,
    required bool selected,
  }) {
    final text = _verseText(verse);
    if (first) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.fromLTRB(3, 4, 3, 5),
        decoration: BoxDecoration(
          color: selected
              ? (_darkMode ? const Color(0xFF39241F) : _verseRedSoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 47,
              child: Text(
                '$number',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _verseRed,
                  fontSize: 48,
                  height: 0.98,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: SelectableText(
                text,
                style: TextStyle(
                  color: _bodyText,
                  fontSize: 17.5,
                  height: 1.31,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.fromLTRB(2, 3, 2, 3),
      decoration: BoxDecoration(
        color: selected
            ? (_darkMode ? const Color(0xFF39241F) : _verseRedSoft)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$number ',
              style: const TextStyle(
                color: _verseRed,
                fontSize: 17,
                height: 1.38,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                color: _bodyText,
                fontSize: 17.2,
                height: 1.38,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LISTE DES LIVRES - 2 COLONNES
  // ==========================================================
  Widget _booksView() {
    final filtered = <MapEntry<int, String>>[];
    final normalized = _bookQuery.trim().toLowerCase();
    for (var index = 0; index < _books.length; index++) {
      final name = _books[index];
      if (normalized.isEmpty || name.toLowerCase().contains(normalized)) {
        filtered.add(MapEntry<int, String>(index, name));
      }
    }
    return Container(
      key: const ValueKey('books'),
      color: _background,
      child: Column(
        children: <Widget>[
          Container(
            color: _card,
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 10),
            child: TextField(
              controller: _bookSearchController,
              onChanged: (value) {
                setState(() {
                  _bookQuery = value;
                });
              },
              style: TextStyle(color: _bodyText, fontSize: 15),
              decoration: InputDecoration(
                hintText: _language == 'sw'
                    ? 'Tafuta kitabu'
                    : 'Rechercher un livre',
                hintStyle: TextStyle(color: _secondaryText, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: _icon, size: 24),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _divider),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _icon, width: 1.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 30),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 38,
                mainAxisSpacing: 11,
                childAspectRatio: 2.65,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final entry = filtered[index];
                final selected = entry.key == _bookIndex;
                return Material(
                  elevation: _darkMode ? 0 : 3,
                  shadowColor: const Color(0x4A000000),
                  color: selected
                      ? (_darkMode ? const Color(0xFF3A2A26) : _verseRedSoft)
                      : _card,
                  borderRadius: BorderRadius.circular(2),
                  child: InkWell(
                    onTap: () {
                      _selectBook(entry.key);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? _verseRed
                              : (_darkMode ? _darkText : _title),
                          fontSize: 16,
                          height: 1.08,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CHOIX DU CHAPITRE
  // ==========================================================
  Widget _chaptersView() {
    final count = _chapterCountFor(_pendingBookIndex);
    return Container(
      key: const ValueKey('chapters'),
      color: _background,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Text(
              _language == 'sw' ? 'Chagua sura' : 'Choisir le chapitre',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: count,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                final selected =
                    _pendingBookIndex == _bookIndex && chapter == _chapter;
                return Material(
                  elevation: _darkMode ? 0 : 2,
                  color: selected ? _verseRed : _card,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: () {
                      _selectChapter(chapter);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Center(
                      child: Text(
                        '$chapter',
                        style: TextStyle(
                          color: selected ? Colors.white : _bodyText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECHERCHE VERSETS
  // ==========================================================
  Widget _searchView() {
    final direct = _directReference;
    final extra = direct == null ? 0 : 1;
    return Container(
      key: const ValueKey('search'),
      color: _background,
      child: Column(
        children: <Widget>[
          Container(
            color: _card,
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 10),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _submitSearch,
              style: TextStyle(color: _bodyText, fontSize: 15),
              decoration: InputDecoration(
                hintText: _language == 'sw'
                    ? 'Tafuta aya, mada au rejea'
                    : 'Rechercher un verset, un thème ou une référence',
                hintStyle: TextStyle(color: _secondaryText, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: _icon, size: 23),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: Icon(Icons.close_rounded, color: _secondaryText),
                      ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _divider),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _icon),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? _searchEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 30),
                    itemCount: _searchResults.length + extra,
                    itemBuilder: (context, index) {
                      if (direct != null && index == 0) {
                        return _directCard(direct);
                      }
                      final resultIndex = index - extra;
                      final result = _searchResults[resultIndex];
                      return _searchResultCard(result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.search_rounded, size: 44, color: _secondaryText),
          const SizedBox(height: 10),
          Text(
            _language == 'sw' ? 'Tafuta Biblia' : 'Rechercher dans la Bible',
            style: TextStyle(color: _secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _directCard(BibleReference reference) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _darkMode ? const Color(0xFF332521) : _verseRedSoft,
        child: InkWell(
          onTap: () {
            _openReference(reference);
          },
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _verseRed,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_books[reference.bookIndex]} '
                    '${reference.chapter}:${reference.verse}',
                    style: TextStyle(
                      color: _bodyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _searchResultCard(BibleSearchResult result) {
    return Material(
      color: _card,
      child: InkWell(
        onTap: () {
          _openReference(
            BibleReference(
              bookIndex: result.bookIndex,
              chapter: result.chapter,
              verse: result.verse,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 11, 6, 13),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                result.reference,
                style: const TextStyle(
                  color: _verseRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                result.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _bodyText,
                  fontSize: 15.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING / ERREUR
  // ==========================================================
  Widget _loadingView() {
    return const _BibleLoadingSkeleton();
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.menu_book_outlined, color: _verseRed, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _bodyText, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DRAWER BIBLE
  // ==========================================================
  Future<void> _toggleDarkMode() async {
    setState(() {
      _darkMode = !_darkMode;
    });
    await _saveDarkMode();
  }

  void _drawerAction(String action) {
    Navigator.of(context).pop();
    switch (action) {
      case 'books':
        _openBooks();
        return;
      case 'search':
        _openSearch();
        return;
      case 'copy-app':
        Clipboard.setData(
          const ClipboardData(text: 'https://cemm-eglisemaranatha.site'),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lien MARANATHA copié.')));
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == 'sw'
                  ? 'Sehemu hii itaunganishwa na Biblia ya MARANATHA.'
                  : 'Cette fonction sera reliée au module Bible MARANATHA.',
            ),
          ),
        );
    }
  }
}

// ============================================================
// MENU LATERAL BIBLE
// ============================================================
class _BibleDrawer extends StatelessWidget {
  const _BibleDrawer({
    required this.language,
    required this.darkMode,
    required this.onDarkMode,
    required this.onItem,
  });
  final String language;
  final bool darkMode;
  final VoidCallback onDarkMode;
  final ValueChanged<String> onItem;
  static const Color _icon = Color(0xFF527C85);
  static const Color _text = Color(0xFF6C7F86);
  static const Color _line = Color(0xFFD7DADB);
  String _label(String fr, String sw) {
    return language == 'sw' ? sw : fr;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // ================================================
            // HEADER DRAWER
            // ================================================
            Container(
              width: double.infinity,
              height: 146,
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFE9EEF0), Color(0xFFF9FAFA)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    width: 43,
                    height: 58,
                    child: Image.asset(
                      'assets/branding/cemm_official_symbol.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Bible MARANATHA',
                    style: TextStyle(
                      color: Color(0xFF40494D),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _item(
                    icon: Icons.menu_book_outlined,
                    text: _label('Livres de la Bible', 'Vitabu vya Biblia'),
                    onTap: () {
                      onItem('books');
                    },
                  ),
                  _item(
                    icon: Icons.search_rounded,
                    text: _label('Rechercher', 'Tafuta'),
                    onTap: () {
                      onItem('search');
                    },
                  ),
                  _item(
                    icon: Icons.calendar_month_outlined,
                    text: _label('Plan de lecture', 'Mpango wa Kusoma'),
                    onTap: () {
                      onItem('plan');
                    },
                  ),
                  _item(
                    icon: Icons.auto_stories_outlined,
                    text: _label('Versets du jour', 'Vifungu vya Kila Siku'),
                    onTap: () {
                      onItem('daily');
                    },
                  ),
                  _item(
                    icon: Icons.bookmark_border_rounded,
                    text: _label('Signets', 'Alamisho'),
                    onTap: () {
                      onItem('bookmarks');
                    },
                  ),
                  _item(
                    icon: Icons.article_outlined,
                    text: _label('Notes', 'Vidokezo'),
                    onTap: () {
                      onItem('notes');
                    },
                  ),
                  _item(
                    icon: Icons.format_size_rounded,
                    text: _label('Apparence', 'Maangazio'),
                    onTap: () {
                      onItem('appearance');
                    },
                  ),
                  _item(
                    icon: Icons.settings_outlined,
                    text: _label('Paramètres Bible', 'Mipangilio'),
                    onTap: () {
                      onItem('settings');
                    },
                  ),
                  _item(
                    icon: darkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    text: darkMode
                        ? _label('Mode jour', 'Mchana')
                        : _label('Mode nuit', 'Usiku'),
                    onTap: onDarkMode,
                  ),
                  _item(
                    icon: Icons.share_outlined,
                    text: _label('Partager MARANATHA', 'Shiriki Programu'),
                    onTap: () {
                      onItem('copy-app');
                    },
                  ),
                  _item(
                    icon: Icons.mail_outline_rounded,
                    text: _label('Avis', 'Maoni'),
                    onTap: () {
                      onItem('feedback');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 57,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            leading: SizedBox(
              width: 30,
              child: Icon(icon, color: _icon, size: 23),
            ),
            title: Text(
              text,
              style: const TextStyle(
                color: _text,
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            onTap: onTap,
          ),
        ),
        const Divider(height: 1, indent: 17, endIndent: 0, color: _line),
      ],
    );
  }
}


class _BibleLoadingSkeleton
    extends StatefulWidget {
  const _BibleLoadingSkeleton();

  @override
  State<_BibleLoadingSkeleton>
      createState() =>
          _BibleLoadingSkeletonState();
}

class _BibleLoadingSkeletonState
    extends State<_BibleLoadingSkeleton>
    with SingleTickerProviderStateMixin {

  late final AnimationController
      _pulse;

  @override
  void initState() {
    super.initState();

    _pulse =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 850,
      ),
      lowerBound: 0.45,
      upperBound: 1,
    )
          ..repeat(
            reverse: true,
          );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block(
    double height, {
    double? width,
    double radius = 6,
  }) {
    return Container(
      width:
          width ??
          double.infinity,
      height: height,
      decoration: BoxDecoration(
        color:
            const Color(
          0xFFE5E7EB,
        ),
        borderRadius:
            BorderRadius.circular(
          radius,
        ),
      ),
    );
  }

  Widget _verseLine(
    int index,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        11,
        18,
        11,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          _block(
            26,
            width: 26,
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                _block(
                  12,
                  width:
                      index.isEven
                          ? 270
                          : 215,
                ),
                const SizedBox(height: 8),
                _block(11),
                const SizedBox(height: 8),
                _block(
                  11,
                  width: 180,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _pulse,
      builder:
          (context, child) {
        return Opacity(
          opacity:
              _pulse.value,
          child: child,
        );
      },
      child: ColoredBox(
        color:
            const Color(
          0xFFF7F7F6,
        ),
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                12,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child:
                            _block(38),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            _block(38),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _block(42),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color:
                  Color(
                0xFFE5E7EB,
              ),
            ),
            Expanded(
              child:
                  ListView.builder(
                padding:
                    const EdgeInsets.only(
                  top: 7,
                  bottom: 24,
                ),
                itemCount: 7,
                itemBuilder:
                    (context, index) {
                  return _verseLine(
                    index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
