abstract final class SearchNormalizer {
  static String normalize(String input) {
    var value = input.toLowerCase();
    value = value
        .replaceAll('\u0153', 'oe')
        .replaceAll('\u00e6', 'ae')
        .replaceAll('\u00e0', 'a')
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e4', 'a')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00e5', 'a')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u00e8', 'e')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00eb', 'e')
        .replaceAll('\u00ec', 'i')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00ee', 'i')
        .replaceAll('\u00ef', 'i')
        .replaceAll('\u00f1', 'n')
        .replaceAll('\u00f2', 'o')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00f9', 'u')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u00fb', 'u')
        .replaceAll('\u00fc', 'u')
        .replaceAll('\u00fd', 'y')
        .replaceAll('\u00ff', 'y');
    value = value.replaceAll(RegExp(r'[^a-z0-9:]+'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    return value.trim();
  }

  static List<String> tokens(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) {
      return const <String>[];
    }
    return normalized
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static double similarity(String a, String b) {
    final first = normalize(a);
    final second = normalize(b);
    if (first == second) {
      return 1;
    }
    if (first.isEmpty || second.isEmpty) {
      return 0;
    }
    final distance = _levenshtein(first, second);
    final longest = first.length > second.length ? first.length : second.length;
    if (longest == 0) {
      return 1;
    }
    return 1 - (distance / longest);
  }

  static int _levenshtein(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        current[j] = [
          deletion,
          insertion,
          substitution,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }
}
