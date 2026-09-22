import 'search_result.dart';

abstract class MaranathaSearchProvider {
  String get id;
  Future<List<MaranathaSearchResult>> search(String query);
}
