class BibleLaunchData {
  const BibleLaunchData({
    required this.bookIndex,
    required this.chapter,
    required this.verse,
  });
  final int bookIndex;
  final int chapter;
  final int verse;
}

class BibleLaunchRequest {
  BibleLaunchRequest._();
  static final BibleLaunchRequest instance = BibleLaunchRequest._();
  BibleLaunchData? _pending;
  void set({required int bookIndex, required int chapter, required int verse}) {
    _pending = BibleLaunchData(
      bookIndex: bookIndex,
      chapter: chapter,
      verse: verse,
    );
  }

  BibleLaunchData? take() {
    final value = _pending;
    _pending = null;
    return value;
  }
}
