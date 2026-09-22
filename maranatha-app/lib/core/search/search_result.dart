enum SearchDestinationType { bibleReference, module, content }

class MaranathaSearchResult {
  const MaranathaSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.section,
    required this.score,
    required this.destinationType,
    this.snippet,
    this.metadata = const <String, Object?>{},
  });
  final String id;
  final String title;
  final String subtitle;
  final String section;
  final String? snippet;
  final double score;
  final SearchDestinationType destinationType;
  final Map<String, Object?> metadata;
}
