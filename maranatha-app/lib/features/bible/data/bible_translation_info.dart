class BibleTranslationInfo {
  const BibleTranslationInfo({
    required this.languageCode,
    required this.languageName,
    required this.translationId,
    required this.translationName,
    required this.sourceStatus,
    required this.assetPath,
  });
  final String languageCode;
  final String languageName;
  final String translationId;
  final String translationName;
  final String sourceStatus;
  final String assetPath;
}

abstract final class BibleTranslations {
  static const BibleTranslationInfo french = BibleTranslationInfo(
    languageCode: 'fr',
    languageName: 'Francais',
    translationId: 'FR_LOCAL',
    translationName: 'Version francaise integree - source exacte a confirmer',
    sourceStatus: 'SOURCE_EXACTE_A_CONFIRMER',
    assetPath: 'assets/bible/bible_fr.json',
  );
  static const BibleTranslationInfo swahili = BibleTranslationInfo(
    languageCode: 'sw',
    languageName: 'Kiswahili',
    translationId: 'SUV',
    translationName: 'Maandiko Matakatifu - SUV',
    sourceStatus: 'TRADUCTION_VERROUILLEE',
    assetPath: 'assets/bible/bible_sw.json',
  );
  static BibleTranslationInfo fromLanguage(String language) {
    return language == 'sw' ? swahili : french;
  }
}
