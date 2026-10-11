import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerTranslations tests', () {
    test('Default values', () {
      final translations = PlayerTranslations();
      expect(translations.languageCode, 'en');
      expect(translations.overflowMenuAbout, 'About');
      expect(translations.aboutVersion, 'Version');
      expect(translations.aboutClose, 'Close');
      expect(translations.aboutLinkCopied, 'Copied');
      expect(translations.aboutRepository, 'Repository');
      expect(translations.aboutHasoft, 'Hasoft.pl');
      expect(translations.aboutReportIssue, 'Report issue');
    });

    test('Polish factory', () {
      final translations = PlayerTranslations.polish();
      expect(translations.languageCode, 'pl');
      expect(translations.generalRetry, 'Spróbuj ponownie');
      expect(translations.overflowMenuAbout, 'O odtwarzaczu');
      expect(translations.aboutVersion, 'Wersja');
      expect(translations.aboutClose, 'Zamknij');
      expect(translations.aboutLinkCopied, 'Skopiowano');
      expect(translations.aboutRepository, 'Repozytorium');
      expect(translations.aboutHasoft, 'Hasoft.pl');
      expect(translations.aboutReportIssue, 'Zgłoś błąd');
    });

    test('Chinese factory', () {
      final translations = PlayerTranslations.chinese();
      expect(translations.languageCode, 'zh');
    });

    test('Hindi factory', () {
      final translations = PlayerTranslations.hindi();
      expect(translations.languageCode, 'hi');
    });

    test('Arabic factory', () {
      final translations = PlayerTranslations.arabic();
      expect(translations.languageCode, 'ar');
    });

    test('Turkish factory', () {
      final translations = PlayerTranslations.turkish();
      expect(translations.languageCode, 'tr');
    });

    test('Vietnamese factory', () {
      final translations = PlayerTranslations.vietnamese();
      expect(translations.languageCode, 'vi');
    });

    test('Spanish factory', () {
      final translations = PlayerTranslations.spanish();
      expect(translations.languageCode, 'es');
      expect(translations.overflowMenuAbout, 'About');
      expect(translations.aboutVersion, 'Version');
      expect(translations.aboutClose, 'Close');
      expect(translations.aboutLinkCopied, 'Copied');
    });

    test('Persian factory', () {
      final translations = PlayerTranslations.persian();
      expect(translations.languageCode, 'fa');
      expect(translations.overflowMenuCancelLabel, 'لغو');
      expect(translations.overflowMenuScrimHint, 'بستن');
    });

    test('Portuguese factory', () {
      final translations = PlayerTranslations.portuguese();
      expect(translations.languageCode, 'pt');
      expect(translations.overflowMenuCancelLabel, 'Cancelar');
      expect(translations.overflowMenuScrimHint, 'Fechar');
    });
  });
}
