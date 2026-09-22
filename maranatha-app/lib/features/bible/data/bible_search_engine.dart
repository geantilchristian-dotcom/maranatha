import 'bible_books.dart';
import 'bible_repository.dart';

class BibleReference {
  const BibleReference({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
  });
  final int bookIndex;
  final int chapter;
  final int verse;
}

class BibleSearchResult {
  const BibleSearchResult({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.bookName,
    required this.text,
    required this.score,
  });
  final int bookIndex;
  final int chapter;
  final int verse;
  final String bookName;
  final String text;
  final int score;
  String get reference {
    return '$bookName $chapter:$verse';
  }
}

class _IndexedVerse {
  const _IndexedVerse({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
    required this.bookName,
    required this.text,
    required this.normalized,
  });
  final int bookIndex;
  final int chapter;
  final int verse;
  final String bookName;
  final String text;
  final String normalized;
}

class _TopicProfile {
  const _TopicProfile({
    required this.triggers,
    required this.terms,
    required this.preferredPhrases,
  });
  final List<String> triggers;
  final List<String> terms;
  final List<String> preferredPhrases;
}

class BibleSearchEngine {
  BibleSearchEngine._(this._verses, this._chapterCounts, this._bookAliases);
  final List<_IndexedVerse> _verses;
  final List<int> _chapterCounts;
  final Map<String, int> _bookAliases;
  static const Set<String> _stopWords = <String>{
    'a',
    'au',
    'aux',
    'avec',
    'ce',
    'ces',
    'dans',
    'de',
    'des',
    'du',
    'elle',
    'en',
    'et',
    'est',
    'il',
    'je',
    'la',
    'le',
    'les',
    'me',
    'mes',
    'mon',
    'ne',
    'nous',
    'on',
    'ou',
    'par',
    'pas',
    'pour',
    'que',
    'qui',
    'sa',
    'se',
    'ses',
    'son',
    'sur',
    'tu',
    'un',
    'une',
    'vous',
    'ya',
    'wa',
    'na',
    'ni',
    'kwa',
    'katika',
  };
  static const List<_TopicProfile> _topics = <_TopicProfile>[
    _TopicProfile(
      triggers: <String>[
        'jesus revient',
        'jesus reviens',
        'jesus reviendra',
        'retour de jesus',
        'retour du christ',
        'christ revient',
        'vient bientot',
        'reviens bientot',
        'seconde venue',
        'avenement',
      ],
      terms: <String>[
        'jesus',
        'christ',
        'seigneur',
        'viens',
        'vient',
        'viendra',
        'reviendra',
        'retour',
        'bientot',
        'apparaitra',
        'apparition',
        'avenement',
        'veillez',
        'attendre',
        'attendez',
      ],
      preferredPhrases: <String>[
        'je viens bientot',
        'viens bientot',
        'fils de l homme viendra',
        'venue du seigneur',
        'notre seigneur jesus christ',
      ],
    ),
    _TopicProfile(
      triggers: <String>['amour', 'aimer', 'aime', 'dieu aime'],
      terms: <String>['amour', 'aime', 'aimer', 'charite', 'bienveillance'],
      preferredPhrases: <String>[
        'dieu a tant aime',
        'aimez vous',
        'l amour de dieu',
      ],
    ),
    _TopicProfile(
      triggers: <String>['foi', 'croire', 'confiance en dieu'],
      terms: <String>['foi', 'croire', 'croit', 'confiance', 'esperance'],
      preferredPhrases: <String>['par la foi', 'celui qui croit', 'ayez foi'],
    ),
    _TopicProfile(
      triggers: <String>['priere', 'prier', 'comment prier'],
      terms: <String>['priere', 'prier', 'priez', 'demandez', 'invoquez'],
      preferredPhrases: <String>[
        'quand vous priez',
        'priez sans cesse',
        'demandez et vous recevrez',
      ],
    ),
    _TopicProfile(
      triggers: <String>['peur', 'avoir peur', 'crainte', 'angoisse'],
      terms: <String>[
        'peur',
        'crainte',
        'craindre',
        'angoisse',
        'courage',
        'fortifie',
      ],
      preferredPhrases: <String>[
        'ne crains point',
        'ne craignez pas',
        'fortifie toi',
      ],
    ),
    _TopicProfile(
      triggers: <String>['paix', 'trouver la paix'],
      terms: <String>['paix', 'repos', 'tranquillite', 'reconciliation'],
      preferredPhrases: <String>[
        'je vous donne ma paix',
        'prince de paix',
        'paix de dieu',
      ],
    ),
    _TopicProfile(
      triggers: <String>['pardon', 'pardonner', 'peche'],
      terms: <String>[
        'pardon',
        'pardonne',
        'pardonner',
        'peche',
        'peches',
        'confesser',
        'misericorde',
      ],
      preferredPhrases: <String>[
        'pardonne nos offenses',
        'si nous confessons nos peches',
        'vos peches seront pardonnes',
      ],
    ),
    _TopicProfile(
      triggers: <String>['esperance', 'espoir', 'avenir'],
      terms: <String>['esperance', 'espoir', 'avenir', 'promesse', 'attendre'],
      preferredPhrases: <String>[
        'un avenir et une esperance',
        'notre esperance',
      ],
    ),
  ];
  factory BibleSearchEngine.fromData({
    required BibleData data,
    required String language,
  }) {
    final books = bibleBooksForLanguage(language);
    final indexed = <_IndexedVerse>[];
    for (var bookIndex = 0; bookIndex < data.books.length; bookIndex++) {
      final book = data.books[bookIndex];
      if (book is! List) {
        continue;
      }
      final bookName = bookIndex < books.length
          ? books[bookIndex]
          : 'Livre ${bookIndex + 1}';
      for (var chapterIndex = 0; chapterIndex < book.length; chapterIndex++) {
        final chapter = book[chapterIndex];
        if (chapter is! List) {
          continue;
        }
        for (var verseIndex = 0; verseIndex < chapter.length; verseIndex++) {
          final raw = chapter[verseIndex];
          final text = _extractVerseText(raw);
          final verseNumber = _extractVerseNumber(raw, verseIndex + 1);
          indexed.add(
            _IndexedVerse(
              bookIndex: bookIndex,
              chapter: chapterIndex + 1,
              verse: verseNumber,
              bookName: bookName,
              text: text,
              normalized: normalize(text),
            ),
          );
        }
      }
    }
    return BibleSearchEngine._(
      indexed,
      data.chapterCounts,
      _createBookAliases(),
    );
  }
  static String _extractVerseText(Object? verse) {
    Object? value = verse;
    if (verse is Map) {
      value = verse['text'];
    }
    return (value?.toString() ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  static int _extractVerseNumber(Object? verse, int fallback) {
    if (verse is Map) {
      final raw = verse['verse'];
      if (raw is num) {
        return raw.toInt();
      }
      final parsed = int.tryParse(raw?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  BibleReference? parseReference(String input) {
    final cleaned = _normalizeReference(input);
    final match = RegExp(r'^(.+?)\s+(\d+)(?::(\d+))?$').firstMatch(cleaned);
    if (match == null) {
      return null;
    }
    final bookQuery = normalize(match.group(1) ?? '');
    final chapter = int.tryParse(match.group(2) ?? '');
    final verse = int.tryParse(match.group(3) ?? '') ?? 1;
    if (chapter == null) {
      return null;
    }
    final bookIndex = _bookAliases[bookQuery];
    if (bookIndex == null) {
      return null;
    }
    if (bookIndex < 0 || bookIndex >= _chapterCounts.length) {
      return null;
    }
    final maxChapter = _chapterCounts[bookIndex];
    if (chapter < 1 || chapter > maxChapter) {
      return null;
    }
    return BibleReference(bookIndex: bookIndex, chapter: chapter, verse: verse);
  }

  List<BibleSearchResult> search(String query, {int limit = 80}) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.length < 2) {
      return const <BibleSearchResult>[];
    }
    final baseTerms = normalizedQuery
        .split(' ')
        .where((term) => term.length >= 2 && !_stopWords.contains(term))
        .toSet();
    if (baseTerms.isEmpty) {
      return const <BibleSearchResult>[];
    }
    final profile = _topicFor(normalizedQuery);
    final expandedTerms = <String>{...baseTerms, ...?profile?.terms};
    final results = <BibleSearchResult>[];
    for (final verse in _verses) {
      var score = 0;
      var coreHits = 0;
      var topicHits = 0;
      if (verse.normalized.contains(normalizedQuery)) {
        score += 140;
      }
      for (final term in baseTerms) {
        if (verse.normalized.contains(term)) {
          coreHits++;
          score += 24;
        }
      }
      if (coreHits == baseTerms.length) {
        score += 30;
      }
      if (profile != null) {
        for (final term in expandedTerms) {
          if (baseTerms.contains(term)) {
            continue;
          }
          if (verse.normalized.contains(term)) {
            topicHits++;
            score += 5;
          }
        }
        for (final phrase in profile.preferredPhrases) {
          if (verse.normalized.contains(phrase)) {
            score += 75;
          }
        }
        if (topicHits >= 2) {
          score += 18;
        }
      }
      final relevant = coreHits > 0 || (profile != null && topicHits > 0);
      if (!relevant || score <= 0) {
        continue;
      }
      results.add(
        BibleSearchResult(
          bookIndex: verse.bookIndex,
          chapter: verse.chapter,
          verse: verse.verse,
          bookName: verse.bookName,
          text: verse.text,
          score: score,
        ),
      );
    }
    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final bookCompare = a.bookIndex.compareTo(b.bookIndex);
      if (bookCompare != 0) {
        return bookCompare;
      }
      final chapterCompare = a.chapter.compareTo(b.chapter);
      if (chapterCompare != 0) {
        return chapterCompare;
      }
      return a.verse.compareTo(b.verse);
    });
    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  static _TopicProfile? _topicFor(String normalizedQuery) {
    for (final topic in _topics) {
      for (final trigger in topic.triggers) {
        if (normalizedQuery.contains(trigger)) {
          return topic;
        }
      }
    }
    return null;
  }

  static String normalize(String input) {
    var value = input.toLowerCase();
    value = value
        .replaceAll('\u0153', 'oe')
        .replaceAll('\u00e6', 'ae')
        .replaceAll('\u00e0', 'a')
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e4', 'a')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00e5', 'a')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u00e8', 'e')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00eb', 'e')
        .replaceAll('\u00ec', 'i')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00ee', 'i')
        .replaceAll('\u00ef', 'i')
        .replaceAll('\u00f1', 'n')
        .replaceAll('\u00f2', 'o')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00f9', 'u')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u00fb', 'u')
        .replaceAll('\u00fc', 'u')
        .replaceAll('\u00fd', 'y')
        .replaceAll('\u00ff', 'y');
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    return value.trim();
  }

  static String _normalizeReference(String input) {
    var value = normalize(input);
    final original = input.toLowerCase();
    if (original.contains(':')) {
      final colonMatch = RegExp(r'(.+?)\s+(\d+)\s*:\s*(\d+)')
          .firstMatch(original);
      if (colonMatch != null) {
        final book = normalize(colonMatch.group(1) ?? '');
        final chapter = colonMatch.group(2);
        final verse = colonMatch.group(3);
        value = '$book $chapter:$verse';
      }
    }
    return value.trim();
  }

  static Map<String, int> _createBookAliases() {
    final aliases = <String, int>{};
    for (var index = 0; index < bibleBooksFr.length; index++) {
      aliases[normalize(bibleBooksFr[index])] = index;
    }
    for (var index = 0; index < bibleBooksSw.length; index++) {
      aliases[normalize(bibleBooksSw[index])] = index;
    }
    void add(String alias, int index) {
      aliases[normalize(alias)] = index;
    }

    add('gen', 0);
    add('gn', 0);
    add('exo', 1);
    add('ex', 1);
    add('lev', 2);
    add('deut', 4);
    add('dt', 4);
    add('jos', 5);
    add('ps', 18);
    add('psaume', 18);
    add('psaumes', 18);
    add('prov', 19);
    add('pr', 19);
    add('esaie', 22);
    add('es', 22);
    add('jer', 23);
    add('ez', 25);
    add('dan', 26);
    add('mt', 39);
    add('mat', 39);
    add('mc', 40);
    add('marc', 40);
    add('lc', 41);
    add('luc', 41);
    add('jn', 42);
    add('jean', 42);
    add('act', 43);
    add('ac', 43);
    add('rom', 44);
    add('rm', 44);
    add('1 cor', 45);
    add('1 co', 45);
    add('2 cor', 46);
    add('2 co', 46);
    add('gal', 47);
    add('eph', 48);
    add('phil', 49);
    add('col', 50);
    add('1 thess', 51);
    add('1 th', 51);
    add('2 thess', 52);
    add('2 th', 52);
    add('1 tim', 53);
    add('1 tm', 53);
    add('2 tim', 54);
    add('2 tm', 54);
    add('heb', 57);
    add('jac', 58);
    add('1 pi', 59);
    add('1 pierre', 59);
    add('2 pi', 60);
    add('2 pierre', 60);
    add('1 jn', 61);
    add('2 jn', 62);
    add('3 jn', 63);
    add('apoc', 65);
    add('ap', 65);
    add('apo', 65);
    return aliases;
  }
}
