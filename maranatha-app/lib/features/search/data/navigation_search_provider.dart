import '../../../core/search/search_normalizer.dart';
import '../../../core/search/search_provider.dart';
import '../../../core/search/search_result.dart';

class NavigationSearchProvider implements MaranathaSearchProvider {
  @override
  String get id => 'navigation';
  static const List<_NavigationEntry> _entries = <_NavigationEntry>[
    _NavigationEntry(
      id: 'bible',
      title: 'Bible',
      subtitle: 'Lire et rechercher dans la Bible',
      aliases: <String>[
        'bible',
        'parole',
        'ecriture',
        'ecritures',
        'scripture',
        'verset',
      ],
    ),
    _NavigationEntry(
      id: 'programme',
      title: 'Programme',
      subtitle: 'Voir le programme de l\u2019\u00e9glise',
      aliases: <String>[
        'programme',
        'programe',
        'planning',
        'agenda',
        'calendrier',
        'activite',
        'evenement',
        'dimanche',
        'culte',
      ],
    ),
    _NavigationEntry(
      id: 'library',
      title: 'Biblioth\u00e8que',
      subtitle: 'Livres, documents et ressources',
      aliases: <String>[
        'bibliotheque',
        'bibliotheque',
        'livre',
        'livres',
        'document',
        'documents',
        'lecture',
      ],
    ),
    _NavigationEntry(
      id: 'direct',
      title: 'Direct',
      subtitle: 'Acc\u00e9der aux directs MARANATHA',
      aliases: <String>['direct', 'live', 'diffusion', 'culte en direct'],
    ),
    _NavigationEntry(
      id: 'word_of_day',
      title: 'Parole du jour',
      subtitle: 'Consulter la parole du jour',
      aliases: <String>[
        'parole du jour',
        'message du jour',
        'meditation',
        'mediter',
      ],
    ),
    _NavigationEntry(
      id: 'activities',
      title: 'Activit\u00e9s r\u00e9centes',
      subtitle: 'Voir les derni\u00e8res activit\u00e9s',
      aliases: <String>[
        'activite',
        'activites',
        'recent',
        'recente',
        'priere',
        'louange',
        'enseignement',
      ],
    ),
  ];
  @override
  Future<List<MaranathaSearchResult>> search(String query) async {
    final normalizedQuery = SearchNormalizer.normalize(query);
    final queryTokens = SearchNormalizer.tokens(query);
    final results = <MaranathaSearchResult>[];
    for (final entry in _entries) {
      var bestScore = 0.0;
      for (final alias in entry.aliases) {
        final normalizedAlias = SearchNormalizer.normalize(alias);
        var score = 0.0;
        if (normalizedQuery == normalizedAlias) {
          score = 1000;
        } else if (normalizedAlias.contains(normalizedQuery) ||
            normalizedQuery.contains(normalizedAlias)) {
          score = 760;
        }
        final aliasTokens = SearchNormalizer.tokens(alias);
        var tokenHits = 0;
        for (final token in queryTokens) {
          if (aliasTokens.any(
            (aliasToken) =>
                aliasToken.contains(token) || token.contains(aliasToken),
          )) {
            tokenHits++;
          }
        }
        if (tokenHits > 0) {
          score += tokenHits * 130;
        }
        final similarity = SearchNormalizer.similarity(
          normalizedQuery,
          normalizedAlias,
        );
        if (similarity >= 0.58) {
          score += similarity * 430;
        }
        if (score > bestScore) {
          bestScore = score;
        }
      }
      if (bestScore < 180) {
        continue;
      }
      results.add(
        MaranathaSearchResult(
          id: 'module:${entry.id}',
          title: entry.title,
          subtitle: entry.subtitle,
          section: 'MARANATHA',
          score: bestScore,
          destinationType: SearchDestinationType.module,
          metadata: <String, Object?>{'routeId': entry.id},
        ),
      );
    }
    return results;
  }
}

class _NavigationEntry {
  const _NavigationEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.aliases,
  });
  final String id;
  final String title;
  final String subtitle;
  final List<String> aliases;
}
