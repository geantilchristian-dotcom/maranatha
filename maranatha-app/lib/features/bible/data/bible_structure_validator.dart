class BibleValidationReport {
  const BibleValidationReport({
    required this.label,
    required this.bookCount,
    required this.chapterCount,
    required this.verseCount,
    required this.chapterCounts,
    required this.numberingGaps,
  });
  final String label;
  final int bookCount;
  final int chapterCount;
  final int verseCount;
  final List<int> chapterCounts;
  final List<String> numberingGaps;
}

abstract final class BibleStructureValidator {
  static BibleValidationReport validate(
    Object? decoded, {
    required String label,
  }) {
    if (decoded is! Map) {
      throw FormatException('$label : racine JSON invalide.');
    }
    final books = decoded['books'];
    if (books is! List) {
      throw FormatException('$label : champ books absent ou invalide.');
    }
    if (books.length != 66) {
      throw FormatException(
        '$label : ${books.length} livres trouves au lieu de 66.',
      );
    }
    final declaredCounts = decoded['chapterCounts'];
    if (declaredCounts != null && declaredCounts is! List) {
      throw FormatException('$label : chapterCounts invalide.');
    }
    if (declaredCounts is List && declaredCounts.length != books.length) {
      throw FormatException(
        '$label : chapterCounts contient '
        '${declaredCounts.length} elements '
        'pour ${books.length} livres.',
      );
    }
    final chapterCounts = <int>[];
    final numberingGaps = <String>[];
    var chapterTotal = 0;
    var verseTotal = 0;
    for (var bookIndex = 0; bookIndex < books.length; bookIndex++) {
      final book = books[bookIndex];
      if (book is! List) {
        throw FormatException('$label : livre ${bookIndex + 1} invalide.');
      }
      if (book.isEmpty) {
        throw FormatException('$label : livre ${bookIndex + 1} vide.');
      }
      chapterCounts.add(book.length);
      chapterTotal += book.length;
      if (declaredCounts is List) {
        final rawCount = declaredCounts[bookIndex];
        final declared = rawCount is num
            ? rawCount.toInt()
            : int.tryParse(rawCount.toString());
        if (declared == null) {
          throw FormatException(
            '$label : chapterCounts invalide '
            'au livre ${bookIndex + 1}.',
          );
        }
        if (declared != book.length) {
          throw FormatException(
            '$label : incoherence de chapitres '
            'au livre ${bookIndex + 1}. '
            'Declare=$declared, reel=${book.length}.',
          );
        }
      }
      for (var chapterIndex = 0; chapterIndex < book.length; chapterIndex++) {
        final chapter = book[chapterIndex];
        if (chapter is! List) {
          throw FormatException(
            '$label : livre ${bookIndex + 1}, '
            'chapitre ${chapterIndex + 1} invalide.',
          );
        }
        if (chapter.isEmpty) {
          throw FormatException(
            '$label : livre ${bookIndex + 1}, '
            'chapitre ${chapterIndex + 1} vide.',
          );
        }
        verseTotal += chapter.length;
        int? previousNumber;
        final seen = <int>{};
        for (var verseIndex = 0; verseIndex < chapter.length; verseIndex++) {
          final verse = chapter[verseIndex];
          final text = _extractText(verse);
          if (text.isEmpty) {
            throw FormatException(
              '$label : verset vide : '
              'livre ${bookIndex + 1}, '
              'chapitre ${chapterIndex + 1}, '
              'position ${verseIndex + 1}.',
            );
          }
          if (text.contains('\uFFFD')) {
            throw FormatException(
              '$label : caractere Unicode invalide : '
              'livre ${bookIndex + 1}, '
              'chapitre ${chapterIndex + 1}, '
              'position ${verseIndex + 1}.',
            );
          }
          final number = _extractNumber(verse, fallback: verseIndex + 1);
          if (number < 1) {
            throw FormatException(
              '$label : numero de verset invalide '
              '$number au livre ${bookIndex + 1}, '
              'chapitre ${chapterIndex + 1}.',
            );
          }
          if (seen.contains(number)) {
            throw FormatException(
              '$label : numero $number en double : '
              'livre ${bookIndex + 1}, '
              'chapitre ${chapterIndex + 1}.',
            );
          }
          if (previousNumber != null) {
            if (number <= previousNumber) {
              throw FormatException(
                '$label : numerotation non croissante : '
                'livre ${bookIndex + 1}, '
                'chapitre ${chapterIndex + 1}. '
                '$previousNumber puis $number.',
              );
            }
            if (number > previousNumber + 1) {
              final from = previousNumber + 1;
              final to = number - 1;
              numberingGaps.add(
                _gapMessage(
                  bookIndex: bookIndex,
                  chapterIndex: chapterIndex,
                  from: from,
                  to: to,
                ),
              );
            }
          } else if (number > 1) {
            numberingGaps.add(
              _gapMessage(
                bookIndex: bookIndex,
                chapterIndex: chapterIndex,
                from: 1,
                to: number - 1,
              ),
            );
          }
          seen.add(number);
          previousNumber = number;
        }
      }
    }
    return BibleValidationReport(
      label: label,
      bookCount: books.length,
      chapterCount: chapterTotal,
      verseCount: verseTotal,
      chapterCounts: List<int>.unmodifiable(chapterCounts),
      numberingGaps: List<String>.unmodifiable(numberingGaps),
    );
  }

  static void validateCompatibleBooks(
    Object? first,
    Object? second, {
    required String firstLabel,
    required String secondLabel,
  }) {
    if (first is! Map || second is! Map) {
      throw const FormatException('Structures bibliques invalides.');
    }
    final firstBooks = first['books'];
    final secondBooks = second['books'];
    if (firstBooks is! List || secondBooks is! List) {
      throw const FormatException('Champ books invalide.');
    }
    if (firstBooks.length != 66) {
      throw FormatException(
        '$firstLabel : '
        '${firstBooks.length} livres au lieu de 66.',
      );
    }
    if (secondBooks.length != 66) {
      throw FormatException(
        '$secondLabel : '
        '${secondBooks.length} livres au lieu de 66.',
      );
    }
    // On ne force volontairement PAS
    // la meme versification entre FR et SW.
  }

  static int _extractNumber(Object? verse, {required int fallback}) {
    if (verse is! Map || !verse.containsKey('verse')) {
      return fallback;
    }
    final raw = verse['verse'];
    if (raw is num) {
      return raw.toInt();
    }
    final value = raw?.toString().trim() ?? '';
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
    throw FormatException('Numero de verset non numerique : $value');
  }

  static String _extractText(Object? verse) {
    Object? value = verse;
    if (verse is Map) {
      if (verse.containsKey('text')) {
        value = verse['text'];
      } else if (verse.containsKey('texte')) {
        value = verse['texte'];
      }
    }
    return value?.toString().replaceAll(RegExp(r'<[^>]+>'), '').trim() ?? '';
  }

  static String _gapMessage({
    required int bookIndex,
    required int chapterIndex,
    required int from,
    required int to,
  }) {
    final numbers = from == to ? '$from' : '$from-$to';
    return 'Livre ${bookIndex + 1}, '
        'chapitre ${chapterIndex + 1} : '
        'numero(s) $numbers absent(s) '
        'dans cette source.';
  }
}
