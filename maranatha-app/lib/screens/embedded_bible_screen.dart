import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmbeddedBibleScreen extends StatefulWidget {
  const EmbeddedBibleScreen({super.key});

  @override
  State<EmbeddedBibleScreen> createState() => _EmbeddedBibleScreenState();
}

class _EmbeddedBibleScreenState extends State<EmbeddedBibleScreen> {
  static const Color _red = Color(0xFFC0001A);
  static const Color _navy = Color(0xFF172033);

  static const List<String> _booksFr = [
    'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
    'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques', 'Esdras',
    'Néhémie', 'Esther', 'Job', 'Psaumes', 'Proverbes',
    'Ecclésiaste', 'Cantique des cantiques', 'Ésaïe', 'Jérémie',
    'Lamentations', 'Ézéchiel', 'Daniel', 'Osée', 'Joël', 'Amos',
    'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habacuc', 'Sophonie',
    'Aggée', 'Zacharie', 'Malachie', 'Matthieu', 'Marc', 'Luc',
    'Jean', 'Actes', 'Romains', '1 Corinthiens', '2 Corinthiens',
    'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
    '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée',
    '2 Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques',
    '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean', 'Jude',
    'Apocalypse',
  ];

  static const List<String> _booksSw = [
    'Mwanzo', 'Kutoka', 'Walawi', 'Hesabu', 'Kumbukumbu la Sheria',
    'Yoshua', 'Waamuzi', 'Ruthu', '1 Samueli', '2 Samueli',
    '1 Wafalme', '2 Wafalme', '1 Mambo ya Nyakati',
    '2 Mambo ya Nyakati', 'Ezra', 'Nehemia', 'Esta', 'Yobu',
    'Zaburi', 'Methali', 'Mhubiri', 'Wimbo Ulio Bora', 'Isaya',
    'Yeremia', 'Maombolezo', 'Ezekieli', 'Danieli', 'Hosea', 'Yoeli',
    'Amosi', 'Obadia', 'Yona', 'Mika', 'Nahumu', 'Habakuki',
    'Sefania', 'Hagai', 'Zekaria', 'Malaki', 'Mathayo', 'Marko',
    'Luka', 'Yohane', 'Matendo', 'Waroma', '1 Wakorintho',
    '2 Wakorintho', 'Wagalatia', 'Waefeso', 'Wafilipi', 'Wakolosai',
    '1 Wathesalonike', '2 Wathesalonike', '1 Timotheo', '2 Timotheo',
    'Tito', 'Filemoni', 'Waebrania', 'Yakobo', '1 Petro', '2 Petro',
    '1 Yohane', '2 Yohane', '3 Yohane', 'Yuda', 'Ufunuo',
  ];

  final Map<String, Map<String, dynamic>> _data = {};
  String _language = 'fr';
  int _bookIndex = 42;
  int _chapter = 3;
  bool _loading = true;
  String? _error;

  List<String> get _books => _language == 'sw' ? _booksSw : _booksFr;
  Map<String, dynamic>? get _currentData => _data[_language];
  List<dynamic> get _currentBooks => (_currentData?['books'] as List<dynamic>?) ?? const <dynamic>[];
  List<dynamic> get _currentChapterCounts => (_currentData?['chapterCounts'] as List<dynamic>?) ?? const <dynamic>[];

  int get _chapterCount {
    if (_bookIndex >= _currentChapterCounts.length) return 1;
    return (_currentChapterCounts[_bookIndex] as num?)?.toInt() ?? 1;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage('fr');
  }

  Future<void> _loadLanguage(String language) async {
    if (_data.containsKey(language)) {
      if (!mounted) return;
      setState(() {
        _language = language;
        _chapter = _chapter.clamp(1, _chapterCount).toInt();
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _language = language;
      _loading = true;
      _error = null;
    });

    try {
      final asset = language == 'sw' ? 'assets/bible/bible_sw.json.gz' : 'assets/bible/bible_fr.json.gz';
      final data = await rootBundle.load(asset);
      final bytes = GZipCodec().decode(data.buffer.asUint8List());
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException('Base Bible invalide');
      _data[language] = Map<String, dynamic>.from(decoded);
      if (!mounted) return;
      setState(() {
        _chapter = _chapter.clamp(1, _chapterCount).toInt();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger la Bible intégrée : $error';
      });
    }
  }

  List<dynamic> _verses() {
    if (_bookIndex >= _currentBooks.length) return const <dynamic>[];
    final book = _currentBooks[_bookIndex];
    if (book is! List || _chapter < 1 || _chapter > book.length) return const <dynamic>[];
    final chapter = book[_chapter - 1];
    return chapter is List ? chapter : const <dynamic>[];
  }

  String _plainText(Object? value) {
    return (value?.toString() ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
  }

  void _selectBook(int? index) {
    if (index == null) return;
    setState(() {
      _bookIndex = index;
      _chapter = 1;
    });
  }

  void _selectChapter(int? chapter) {
    if (chapter == null) return;
    setState(() => _chapter = chapter);
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = _language == 'fr';
    return Container(
      color: const Color(0xFFF4F3F8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: _red, size: 27),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Bible intégrée', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE5F5EA), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_done_rounded, color: Color(0xFF18794E), size: 15),
                      SizedBox(width: 5),
                      Text('Hors ligne', style: TextStyle(color: Color(0xFF18794E), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'fr', label: Text('Français')),
                ButtonSegment<String>(value: 'sw', label: Text('Kiswahili')),
              ],
              selected: <String>{_language},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) _loadLanguage(values.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    value: _bookIndex,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Livre', border: OutlineInputBorder(), isDense: true),
                    items: List<DropdownMenuItem<int>>.generate(
                      _books.length,
                      (index) => DropdownMenuItem<int>(value: index, child: Text(_books[index], overflow: TextOverflow.ellipsis)),
                    ),
                    onChanged: _selectBook,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _chapter.clamp(1, _chapterCount).toInt(),
                    decoration: const InputDecoration(labelText: 'Chapitre', border: OutlineInputBorder(), isDense: true),
                    items: List<DropdownMenuItem<int>>.generate(
                      _chapterCount,
                      (index) => DropdownMenuItem<int>(value: index + 1, child: Text('${index + 1}')),
                    ),
                    onChanged: _selectChapter,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chapter > 1 ? () => setState(() => _chapter--) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: Text(isFrench ? 'Précédent' : 'Iliyotangulia'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chapter < _chapterCount ? () => setState(() => _chapter++) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: Text(isFrench ? 'Suivant' : 'Inayofuata'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _red))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: _verses().length,
                        itemBuilder: (context, index) {
                          final verse = _verses()[index];
                          final number = verse is Map ? verse['verse'] : index + 1;
                          final text = verse is Map ? verse['text'] : verse;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: _navy, fontSize: 16, height: 1.5),
                                children: [
                                  TextSpan(text: '$number  ', style: const TextStyle(color: _red, fontWeight: FontWeight.w800)),
                                  TextSpan(text: _plainText(text)),
                                ],
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
}
