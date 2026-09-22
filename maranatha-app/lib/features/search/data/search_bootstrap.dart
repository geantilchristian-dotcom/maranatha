import '../../../core/search/maranatha_search_engine.dart';
import 'bible_global_search_provider.dart';
import 'legacy_content_search_provider.dart';
import 'navigation_search_provider.dart';

abstract final class SearchBootstrap {
  static bool _initialized = false;
  static void ensureInitialized() {
    if (_initialized) {
      return;
    }
    final engine = MaranathaSearchEngine.instance;
    engine.registerProvider(NavigationSearchProvider());
    engine.registerProvider(BibleGlobalSearchProvider());
    engine.registerProvider(LegacyContentSearchProvider());
    _initialized = true;
  }
}
