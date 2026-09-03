part of '../better_player_controller.dart';

extension PlayerTranslationsExtension on BetterPlayerController {
  ///Setup translations for given locale. In normal use cases it shouldn't be
  ///called manually.
  void setupTranslations(Locale locale) {
    final languageCode = locale.languageCode;
    translations =
        betterPlayerConfiguration.translations?.firstWhereOrNull(
          (t) => t.languageCode == languageCode,
        ) ??
        _getDefaultTranslations(locale);
  }

  ///Setup default translations for selected user locale. These translations
  ///are pre-build in.
  PlayerTranslations _getDefaultTranslations(Locale locale) {
    final languageCode = locale.languageCode;
    switch (languageCode) {
      case 'pl':
        return PlayerTranslations.polish();
      case 'zh':
        return PlayerTranslations.chinese();
      case 'hi':
        return PlayerTranslations.hindi();
      case 'tr':
        return PlayerTranslations.turkish();
      case 'vi':
        return PlayerTranslations.vietnamese();
      case 'es':
        return PlayerTranslations.spanish();
      default:
        return PlayerTranslations();
    }
  }
}
