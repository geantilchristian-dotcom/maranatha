import '../../../core/search/search_normalizer.dart';
import '../../../core/search/search_provider.dart';
import '../../../core/search/search_result.dart';
import '../../content/data/content_repository.dart';

class LegacyContentSearchProvider implements MaranathaSearchProvider {
  @override
  String get id => 'maranatha-content';
  @override
  Future<List<MaranathaSearchResult>> search(String query) async {
    final snapshot = await MaranathaContentRepository.instance.load();
    final results = <MaranathaSearchResult>[];
    for (final entry in snapshot.library.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final item = entry.value[index];
        final score = _score(query, item);
        if (score <= 0) {
          continue;
        }
        final itemId = ContentFields.id(item);
        results.add(
          MaranathaSearchResult(
            id: 'library:${entry.key}:${itemId.isEmpty ? index : itemId}',
            title: ContentFields.title(item).isEmpty
                ? 'Bibliotheque'
                : ContentFields.title(item),
            subtitle: 'Bibliotheque - ${_libraryLabel(entry.key)}',
            snippet: ContentFields.description(item),
            section: 'Bibliotheque',
            score: 650.0 + score,
            destinationType: SearchDestinationType.content,
            metadata: <String, Object?>{
              'routeId': 'library',
              'section': entry.key,
              'focusId': itemId,
            },
          ),
        );
      }
    }
    for (var index = 0; index < snapshot.programmes.length; index++) {
      final item = snapshot.programmes[index];
      final score = _score(query, item);
      if (score <= 0) {
        continue;
      }
      final itemId = ContentFields.id(item);
      results.add(
        MaranathaSearchResult(
          id: 'programme:${itemId.isEmpty ? index : itemId}',
          title: ContentFields.title(item).isEmpty
              ? 'Programme'
              : ContentFields.title(item),
          subtitle: 'Programme MARANATHA',
          snippet: ContentFields.description(item),
          section: 'Programme',
          score: 700.0 + score,
          destinationType: SearchDestinationType.content,
          metadata: <String, Object?>{
            'routeId': 'programme',
            'focusId': itemId,
          },
        ),
      );
    }
    for (var index = 0; index < snapshot.sermons.length; index++) {
      final item = snapshot.sermons[index];
      final score = _score(query, item);
      if (score <= 0) {
        continue;
      }
      final itemId = ContentFields.id(item);
      results.add(
        MaranathaSearchResult(
          id: 'direct:${itemId.isEmpty ? index : itemId}',
          title: ContentFields.title(item).isEmpty
              ? 'Direct'
              : ContentFields.title(item),
          subtitle: 'Direct et predications',
          snippet: ContentFields.description(item),
          section: 'Direct',
          score: 680.0 + score,
          destinationType: SearchDestinationType.content,
          metadata: <String, Object?>{'routeId': 'direct', 'focusId': itemId},
        ),
      );
    }
    for (var index = 0; index < snapshot.studies.length; index++) {
      final item = snapshot.studies[index];
      final score = _score(query, item);
      if (score <= 0) {
        continue;
      }
      results.add(
        MaranathaSearchResult(
          id: 'study:$index',
          title: ContentFields.title(item).isEmpty
              ? 'Etude biblique'
              : ContentFields.title(item),
          subtitle: 'Etude biblique',
          snippet: ContentFields.description(item),
          section: 'Etude biblique',
          score: 610.0 + score,
          destinationType: SearchDestinationType.content,
          metadata: const <String, Object?>{'routeId': 'study'},
        ),
      );
    }
    for (var index = 0; index < snapshot.prayers.length; index++) {
      final item = snapshot.prayers[index];
      final score = _score(query, item);
      if (score <= 0) {
        continue;
      }
      results.add(
        MaranathaSearchResult(
          id: 'prayer:$index',
          title: ContentFields.title(item).isEmpty
              ? 'Priere'
              : ContentFields.title(item),
          subtitle: 'Priere MARANATHA',
          snippet: ContentFields.description(item),
          section: 'Priere',
          score: 600.0 + score,
          destinationType: SearchDestinationType.content,
          metadata: const <String, Object?>{'routeId': 'prayer'},
        ),
      );
    }
    return results;
  }

  double _score(String query, Map<String, dynamic> item) {
    final normalizedQuery = SearchNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) {
      return 0;
    }
    final title = SearchNormalizer.normalize(ContentFields.title(item));
    final description = SearchNormalizer.normalize(
      ContentFields.description(item),
    );
    final author = SearchNormalizer.normalize(ContentFields.author(item));
    final place = SearchNormalizer.normalize(ContentFields.place(item));
    final theme = SearchNormalizer.normalize(ContentFields.theme(item));
    final combined = [title, description, author, place, theme].join(' ');
    var score = 0.0;
    if (title == normalizedQuery) {
      score += 600;
    }
    if (title.contains(normalizedQuery)) {
      score += 380;
    }
    if (combined.contains(normalizedQuery)) {
      score += 250;
    }
    final tokens = SearchNormalizer.tokens(normalizedQuery);
    for (final token in tokens) {
      if (title.contains(token)) {
        score += 90;
      }
      if (combined.contains(token)) {
        score += 35;
      }
    }
    if (title.isNotEmpty) {
      final similarity = SearchNormalizer.similarity(normalizedQuery, title);
      if (similarity >= 0.60) {
        score += similarity * 200;
      }
    }
    return score;
  }

  String _libraryLabel(String value) {
    switch (value) {
      case 'recent':
        return 'Recents';
      case 'live':
        return 'Predications';
      case 'audio':
        return 'Audios';
      case 'video':
        return 'Videos';
      case 'book':
        return 'Livres';
      default:
        return value;
    }
  }
}
