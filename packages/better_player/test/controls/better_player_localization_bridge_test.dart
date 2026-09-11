import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/controls/better_player_video_area_semantics.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino_ui;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  late BetterPlayerMockController mockController;

  setUpAll(() {
    BetterPlayerTestUtils.setupMockPlatform();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    mockController = BetterPlayerMockController(
      const PlayerConfiguration(),
    );
  });

  testWidgets(
    'Material localization bridge provides translated labels within Material controls',
    (tester) async {
      final translations = PlayerTranslations.persian();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
        configuration: PlayerConfiguration(
          translations: [translations],
          controlsConfiguration: const PlayerControlsConfiguration(
            playerTheme: PlayerTheme.material,
          ),
        ),
      );

      late material_ui.MaterialLocalizations materialLoc;
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: const [Locale('fa')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BetterPlayer(controller: controller),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.translations.languageCode, 'fa');

      final context =
          tester.element(find.byType(BetterPlayerVideoAreaSemantics).first);
      materialLoc = material_ui.MaterialLocalizations.of(context);

      expect(
          materialLoc.cancelButtonLabel, translations.overflowMenuCancelLabel);
      expect(materialLoc.scrimLabel, translations.overflowMenuScrimLabel);
      expect(
        materialLoc.scrimOnTapHint('Test'),
        '${translations.overflowMenuScrimHint} Test',
      );
    },
  );

  testWidgets(
    'Cupertino localization bridge provides translated labels within Cupertino controls',
    (tester) async {
      final translations = PlayerTranslations.portuguese();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
        configuration: PlayerConfiguration(
          translations: [translations],
          controlsConfiguration: const PlayerControlsConfiguration(
            playerTheme: PlayerTheme.cupertino,
          ),
        ),
      );

      late cupertino_ui.CupertinoLocalizations cupertinoLoc;
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: const [Locale('pt')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BetterPlayer(controller: controller),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.translations.languageCode, 'pt');

      final context =
          tester.element(find.byType(BetterPlayerVideoAreaSemantics).first);
      cupertinoLoc = cupertino_ui.CupertinoLocalizations.of(context);

      expect(
          cupertinoLoc.cancelButtonLabel, translations.overflowMenuCancelLabel);
      expect(
        cupertinoLoc.modalBarrierDismissLabel,
        translations.overflowMenuScrimLabel,
      );
    },
  );
}
