import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerTranslationsExtension', () {
    test(
      'setupTranslations uses translation from configuration if matched',
      () {
        final customTranslations = [
          PlayerTranslations(
            languageCode: 'fr',
            generalDefault: 'Par défaut',
          ),
        ];
        final controller = BetterPlayerController(
          PlayerConfiguration(translations: customTranslations),
        );

        controller.setupTranslations(const Locale('fr'));

        expect(controller.translations.languageCode, 'fr');
        expect(controller.translations.generalDefault, 'Par défaut');
        controller.dispose();
      },
    );

    test(
      'setupTranslations loads built-in translations for supported locales',
      () {
        final controller = BetterPlayerController(const PlayerConfiguration());

        controller.setupTranslations(const Locale('pl'));
        expect(controller.translations.languageCode, 'pl');

        controller.setupTranslations(const Locale('zh'));
        expect(controller.translations.languageCode, 'zh');

        controller.setupTranslations(const Locale('hi'));
        expect(controller.translations.languageCode, 'hi');

        controller.setupTranslations(const Locale('tr'));
        expect(controller.translations.languageCode, 'tr');

        controller.setupTranslations(const Locale('vi'));
        expect(controller.translations.languageCode, 'vi');

        controller.setupTranslations(const Locale('es'));
        expect(controller.translations.languageCode, 'es');

        controller.setupTranslations(const Locale('fa'));
        expect(controller.translations.languageCode, 'fa');

        controller.setupTranslations(const Locale('pt'));
        expect(controller.translations.languageCode, 'pt');

        controller.dispose();
      },
    );

    test(
      'setupTranslations falls back to default English translations for unknown locale',
      () {
        final controller = BetterPlayerController(const PlayerConfiguration());

        controller.setupTranslations(const Locale('de'));
        expect(controller.translations.languageCode, 'en');

        controller.dispose();
      },
    );
  });
}
