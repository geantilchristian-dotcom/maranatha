import '../../../core/search/search_normalizer.dart';
import '../../../core/search/search_provider.dart';
import '../../../core/search/search_result.dart';
import '../../bible/data/bible_books.dart';
import '../../bible/data/bible_repository.dart';
import '../../bible/data/bible_search_engine.dart';

class BibleGlobalSearchProvider implements MaranathaSearchProvider {
  BibleSearchEngine? _engine;
  @override
  String get id => 'bible';
  Future<BibleSearchEngine> _getEngine() async {
    final existing = _engine;
    if (existing != null) {
      return existing;
    }
    final data = await BibleRepository.instance.load('fr');
    final engine = BibleSearchEngine.fromData(data: data, language: 'fr');
    _engine = engine;
    return engine;
  }

  @override
  Future<List<MaranathaSearchResult>> search(String query) async {
    final engine = await _getEngine();
    final results = <MaranathaSearchResult>[];
    final direct = engine.parseReference(query);
    if (direct != null) {
      final bookName = bibleBooksFr[direct.bookIndex];
      results.add(
        MaranathaSearchResult(
          id: 'bible:${direct.bookIndex}:${direct.chapter}:${direct.verse}',
          title: '$bookName ${direct.chapter}:${direct.verse}',
          subtitle: 'Ouvrir directement ce passage',
          section: 'Bible',
          score: 2200,
          destinationType: SearchDestinationType.bibleReference,
          metadata: <String, Object?>{
            'bookIndex': direct.bookIndex,
            'chapter': direct.chapter,
            'verse': direct.verse,
          },
        ),
      );
    }
    final normalizedQuery = SearchNormalizer.normalize(query);
    for (var index = 0; index < bibleBooksFr.length; index++) {
      final book = bibleBooksFr[index];
      final normalizedBook = SearchNormalizer.normalize(book);
      final similarity = SearchNormalizer.similarity(
        normalizedQuery,
        normalizedBook,
      );
      final exact = normalizedQuery == normalizedBook;
      final contains =
          normalizedBook.contains(normalizedQuery) ||
          normalizedQuery.contains(normalizedBook);
      if (!exact && !contains && similarity < 0.69) {
        continue;
      }
      results.add(
        MaranathaSearchResult(
          id: 'bible-book:$index',
          title: book,
          subtitle: 'Ouvrir le livre de $book',
          section: 'Bible',
          score: exact
              ? 1800
              : contains
              ? 1200
              : 750 * similarity,
          destinationType: SearchDestinationType.bibleReference,
          metadata: <String, Object?>{
            'bookIndex': index,
            'chapter': 1,
            'verse': 1,
          },
        ),
      );
    }
    final bibleResults = engine.search(query, limit: 35);
    for (final result in bibleResults) {
      results.add(
        MaranathaSearchResult(
          id: 'bible:${result.bookIndex}:${result.chapter}:${result.verse}',
          title: result.reference,
          subtitle: 'R\u00e9sultat biblique',
          snippet: result.text,
          section: 'Bible',
          score: 700.0 + result.score.toDouble(),
          destinationType: SearchDestinationType.bibleReference,
          metadata: <String, Object?>{
            'bookIndex': result.bookIndex,
            'chapter': result.chapter,
            'verse': result.verse,
          },
        ),
      );
    }
    return results;
  }
}
