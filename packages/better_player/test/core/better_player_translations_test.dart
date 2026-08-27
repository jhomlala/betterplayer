import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerTranslations tests', () {
    test('Default values', () {
      final translations = PlayerTranslations();
      expect(translations.languageCode, 'en');
    });

    test('Polish factory', () {
      final translations = PlayerTranslations.polish();
      expect(translations.languageCode, 'pl');
      expect(translations.generalRetry, 'Spróbuj ponownie');
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
    });
  });
}
