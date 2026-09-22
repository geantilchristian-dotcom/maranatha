import 'dart:convert';

import 'package:flutter/services.dart';

class BibleData {
  const BibleData({required this.books, required this.chapterCounts});
  final List<dynamic> books;
  final List<int> chapterCounts;
}

class BibleRepository {
  BibleRepository._();
  static final BibleRepository instance = BibleRepository._();
  final Map<String, BibleData> _cache = <String, BibleData>{};
  Future<BibleData> load(String language) async {
    final cached = _cache[language];
    if (cached != null) {
      return cached;
    }
    final assetPath = language == 'sw'
        ? 'assets/bible/bible_sw.json'
        : 'assets/bible/bible_fr.json';
    final source = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Base biblique invalide.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final books = (map['books'] as List<dynamic>?) ?? const <dynamic>[];
    final rawChapterCounts =
        (map['chapterCounts'] as List<dynamic>?) ?? const <dynamic>[];
    final chapterCounts = rawChapterCounts
        .map((value) {
          if (value is num) {
            return value.toInt();
          }
          return 1;
        })
        .toList(growable: false);
    final bible = BibleData(books: books, chapterCounts: chapterCounts);
    _cache[language] = bible;
    return bible;
  }
}
