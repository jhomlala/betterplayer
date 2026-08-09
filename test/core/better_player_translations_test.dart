import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerTranslations tests', () {
    test('Default values', () {
      final translations = BetterPlayerTranslations();
      expect(translations.languageCode, 'en');
    });

    test('Polish factory', () {
      final translations = BetterPlayerTranslations.polish();
      expect(translations.languageCode, 'pl');
      expect(translations.generalRetry, 'Spróbuj ponownie');
    });

    test('Chinese factory', () {
      final translations = BetterPlayerTranslations.chinese();
      expect(translations.languageCode, 'zh');
    });

    test('Hindi factory', () {
      final translations = BetterPlayerTranslations.hindi();
      expect(translations.languageCode, 'hi');
    });

    test('Arabic factory', () {
      final translations = BetterPlayerTranslations.arabic();
      expect(translations.languageCode, 'ar');
    });

    test('Turkish factory', () {
      final translations = BetterPlayerTranslations.turkish();
      expect(translations.languageCode, 'tr');
    });

    test('Vietnamese factory', () {
      final translations = BetterPlayerTranslations.vietnamese();
      expect(translations.languageCode, 'vi');
    });

    test('Spanish factory', () {
      final translations = BetterPlayerTranslations.spanish();
      expect(translations.languageCode, 'es');
    });
  });
}
