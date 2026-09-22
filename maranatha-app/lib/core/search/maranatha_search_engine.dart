import 'search_provider.dart';
import 'search_result.dart';

class MaranathaSearchEngine {
  MaranathaSearchEngine._();
  static final MaranathaSearchEngine instance = MaranathaSearchEngine._();
  final List<MaranathaSearchProvider> _providers = <MaranathaSearchProvider>[];
  bool get hasProviders {
    return _providers.isNotEmpty;
  }

  void registerProvider(MaranathaSearchProvider provider) {
    final alreadyRegistered = _providers.any((item) => item.id == provider.id);
    if (alreadyRegistered) {
      return;
    }
    _providers.add(provider);
  }

  Future<List<MaranathaSearchResult>> search(
    String query, {
    int limit = 60,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const <MaranathaSearchResult>[];
    }
    final allResults = <MaranathaSearchResult>[];
    for (final provider in _providers) {
      try {
        final providerResults = await provider.search(cleanQuery);
        allResults.addAll(providerResults);
      } catch (_) {
        // Un fournisseur ne doit jamais
        // bloquer toute la recherche.
      }
    }
    final deduplicated = <String, MaranathaSearchResult>{};
    for (final result in allResults) {
      final previous = deduplicated[result.id];
      if (previous == null || result.score > previous.score) {
        deduplicated[result.id] = result;
      }
    }
    final results = deduplicated.values.toList();
    results.sort((a, b) => b.score.compareTo(a.score));
    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }
}
