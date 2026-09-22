import '../data/bible_launch_request.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/bible_books.dart';
import '../data/bible_repository.dart';
import '../data/bible_search_engine.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});
  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFE1E7F0);
  static const Color _secondary = Color(0xFF68778D);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _readerController = ScrollController();
  Timer? _searchTimer;
  String _language = 'fr';
  BibleData? _data;
  BibleSearchEngine? _searchEngine;
  List<BibleSearchResult> _searchResults = <BibleSearchResult>[];
  BibleReference? _directReference;
  int _bookIndex = 0;
  int _chapter = 1;
  int? _selectedVerse;
  bool _loading = true;
  String? _error;
  String _query = '';
  List<String> get _books {
    return bibleBooksForLanguage(_language);
  }

  int get _chapterCount {
    final data = _data;
    if (data == null || _bookIndex >= data.chapterCounts.length) {
      return 1;
    }
    final count = data.chapterCounts[_bookIndex];
    return count < 1 ? 1 : count;
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

  bool get _searchMode {
    return _query.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadBible('fr');
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _readerController.dispose();
    super.dispose();
  }

  Future<void> _loadBible(String language) async {
    setState(() {
      _language = language;
      _loading = true;
      _error = null;
      _query = '';
      _searchResults = <BibleSearchResult>[];
      _directReference = null;
      _selectedVerse = null;
    });
    _searchController.clear();
    try {
      final bible = await BibleRepository.instance.load(language);
      final engine = BibleSearchEngine.fromData(
        data: bible,
        language: language,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = bible;
        _searchEngine = engine;
        final launch = BibleLaunchRequest.instance.take();
        if (launch != null) {
          _bookIndex = launch.bookIndex;
          _chapter = launch.chapter;
          _selectedVerse = launch.verse;
        }

        if (_bookIndex >= bible.books.length) {
          _bookIndex = 0;
        }
        if (_chapter > _chapterCount) {
          _chapter = _chapterCount;
        }
        if (_chapter < 1) {
          _chapter = 1;
        }
        _loading = false;
      });
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

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _searchResults = <BibleSearchResult>[];
      _directReference = null;
    });
  }

  void _openReference(BibleReference reference) {
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {
      _bookIndex = reference.bookIndex;
      _chapter = reference.chapter;
      _selectedVerse = reference.verse;
      _query = '';
      _searchResults = <BibleSearchResult>[];
      _directReference = null;
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
    final estimated = (selected - 1) * 74.0;
    final max = _readerController.position.maxScrollExtent;
    final target = estimated.clamp(0.0, max);
    await _readerController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  String _plainText(Object? value) {
    return (value?.toString() ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
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

  void _changeBook(int index) {
    setState(() {
      _bookIndex = index;
      _chapter = 1;
      _selectedVerse = null;
    });
    _clearSearch();
  }

  void _changeChapter(int chapter) {
    setState(() {
      _chapter = chapter;
      _selectedVerse = null;
    });
    if (_readerController.hasClients) {
      _readerController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _navy,
        titleSpacing: 0,
        title: const Text(
          'Bible',
          style: TextStyle(
            color: _navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
            )
          : _error != null
          ? _ErrorView(message: _error!)
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return _desktop();
                }
                return _mobile();
              },
            ),
    );
  }

  Widget _mobile() {
    return Column(
      children: [
        _mobileControls(),
        const Divider(height: 1, color: _border),
        Expanded(child: _searchMode ? _searchView() : _reader()),
      ],
    );
  }

  Widget _desktop() {
    return Row(
      children: [
        Container(
          width: 270,
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                child: _languageSwitch(),
              ),
              const Divider(height: 1, color: _border),
              Expanded(child: _desktopBookList()),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: _border),
        Expanded(
          child: Column(
            children: [
              _desktopControls(),
              const Divider(height: 1, color: _border),
              Expanded(child: _searchMode ? _searchView() : _reader()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        children: [
          _languageSwitch(),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(flex: 3, child: _bookDropdown()),
              const SizedBox(width: 9),
              Expanded(flex: 2, child: _chapterDropdown()),
            ],
          ),
          const SizedBox(height: 10),
          _smartSearchField(),
        ],
      ),
    );
  }

  Widget _desktopControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(
        children: [
          SizedBox(width: 240, child: _bookDropdown()),
          const SizedBox(width: 10),
          SizedBox(width: 180, child: _chapterDropdown()),
          const SizedBox(width: 14),
          Expanded(child: _smartSearchField()),
        ],
      ),
    );
  }

  Widget _languageSwitch() {
    return Container(
      height: 39,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: _languageButton(language: 'fr', label: 'Fran\u00e7ais'),
          ),
          Expanded(
            child: _languageButton(language: 'sw', label: 'Kiswahili'),
          ),
        ],
      ),
    );
  }

  Widget _languageButton({required String language, required String label}) {
    final selected = _language == language;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: () {
          if (!selected) {
            _loadBible(language);
          }
        },
        borderRadius: BorderRadius.circular(7),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _blue : _secondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorShell({required Widget child}) {
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _bookDropdown() {
    return _selectorShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _bookIndex,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: _blue,
          ),
          items: List.generate(_books.length, (index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                _books[index],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              _changeBook(value);
            }
          },
        ),
      ),
    );
  }

  Widget _chapterDropdown() {
    return _selectorShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _chapter,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: _blue,
          ),
          items: List.generate(_chapterCount, (index) {
            final number = index + 1;
            return DropdownMenuItem<int>(
              value: number,
              child: Text(
                _language == 'sw' ? 'Sura $number' : 'Chapitre $number',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              _changeChapter(value);
            }
          },
        ),
      ),
    );
  }

  Widget _smartSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: _submitSearch,
      style: const TextStyle(
        color: _navy,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: _language == 'sw'
            ? 'Tafuta aya, mada au rejea'
            : 'Rechercher un verset, un th\u00e8me ou une r\u00e9f\u00e9rence',
        hintStyle: const TextStyle(
          color: Color(0xFF94A0B3),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: _blue, size: 20),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: _clearSearch,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: _secondary,
                ),
              ),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
      ),
    );
  }

  Widget _desktopBookList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 20),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final selected = index == _bookIndex;
        return Material(
          color: selected ? const Color(0xFFEAF0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              _changeBook(index);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Text(
                _books[index],
                style: TextStyle(
                  color: selected ? _blue : _navy,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _searchView() {
    final direct = _directReference;
    final extra = direct == null ? 0 : 1;
    return Container(
      color: _page,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        itemCount: _searchResults.length + extra + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _searchHeader();
          }
          if (direct != null && index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DirectReferenceCard(
                reference: direct,
                bookName: _books[direct.bookIndex],
                onTap: () {
                  _openReference(direct);
                },
              ),
            );
          }
          final resultIndex = index - 1 - extra;
          final result = _searchResults[resultIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _SearchResultCard(
              result: result,
              onTap: () {
                _openReference(
                  BibleReference(
                    bookIndex: result.bookIndex,
                    chapter: result.chapter,
                    verse: result.verse,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _searchHeader() {
    final count = _searchResults.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count == 0
                ? 'Aucun r\u00e9sultat'
                : '$count verset${count > 1 ? 's' : ''} pertinent${count > 1 ? 's' : ''}',
            style: const TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '\u00ab $_query \u00bb',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _secondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reader() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(15, 12, 11, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_books[_bookIndex]} $_chapter',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              _ChapterArrow(
                icon: Icons.chevron_left_rounded,
                enabled: _chapter > 1,
                onTap: () {
                  _changeChapter(_chapter - 1);
                },
              ),
              const SizedBox(width: 2),
              _ChapterArrow(
                icon: Icons.chevron_right_rounded,
                enabled: _chapter < _chapterCount,
                onTap: () {
                  _changeChapter(_chapter + 1);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _border),
        Expanded(
          child: ListView.separated(
            controller: _readerController,
            padding: const EdgeInsets.fromLTRB(15, 17, 15, 40),
            itemCount: _chapterVerses.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 5);
            },
            itemBuilder: (context, index) {
              final verse = _chapterVerses[index];
              final number = _verseNumber(verse, index + 1);
              final selected = number == _selectedVerse;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.fromLTRB(9, 9, 10, 9),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEAF0FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 31,
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 10,
                          height: 1.65,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        _verseText(verse),
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15.5,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DirectReferenceCard extends StatelessWidget {
  const _DirectReferenceCard({
    required this.reference,
    required this.bookName,
    required this.onTap,
  });
  final BibleReference reference;
  final String bookName;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF0FF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_forward_rounded,
                color: _BiblePageColors.blue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aller directement \u00e0 '
                  '$bookName ${reference.chapter}:${reference.verse}',
                  style: const TextStyle(
                    color: _BiblePageColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.onTap});
  final BibleSearchResult result;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          decoration: BoxDecoration(
            border: Border.all(color: _BiblePageColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.reference,
                style: const TextStyle(
                  color: _BiblePageColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BiblePageColors.navy,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterArrow extends StatelessWidget {
  const _ChapterArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 22),
      color: _BiblePageColors.navy,
      disabledColor: const Color(0xFFC0C8D3),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _BiblePageColors.navy,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

abstract final class _BiblePageColors {
  static const Color blue = Color(0xFF003DF0);
  static const Color navy = Color(0xFF10284A);
  static const Color border = Color(0xFFE1E7F0);
}
