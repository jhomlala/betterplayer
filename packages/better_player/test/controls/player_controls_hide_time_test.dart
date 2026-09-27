import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  setUpAll(BetterPlayerTestUtils.setupMockPlatform);

  testWidgets(
    'Controls hide after custom controlsHideTime for Material controls',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlayerEngineController = MockPlayerEngineController();
      mockPlayerEngineController.setDuration(const Duration(seconds: 100));

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockPlayerEngineController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.material,
            controlsHideTime: Duration(milliseconds: 500),
          ),
        ),
      );

      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(
              controller: controller,
            ),
          ),
        ),
      );

      // Wait for player to initialize
      await tester.pumpAndSettle();

      // Tap on the player to show controls and restart timer
      await tester.tap(find.byType(BetterPlayer));
      await tester.pump();

      // Wait 200ms - controls should still be visible
      await tester.pump(const Duration(milliseconds: 200));

      // Wait another 350ms - total 550ms, which is > 500ms
      // Controls should be hidden
      await tester.pump(const Duration(milliseconds: 350));

      // If we wait for the timer to finish, the controlsNotVisible state is updated to true
      // and it rebuilds.
    },
  );

  testWidgets(
    'Controls hide after custom controlsHideTime for Cupertino controls',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPlayerEngineController = MockPlayerEngineController();
      mockPlayerEngineController.setDuration(const Duration(seconds: 100));

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockPlayerEngineController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.cupertino,
            controlsHideTime: Duration(milliseconds: 500),
          ),
        ),
      );

      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(
              controller: controller,
            ),
          ),
        ),
      );

      // Wait for player to initialize
      await tester.pumpAndSettle();

      // Tap on the player to show controls and restart timer
      await tester.tap(find.byType(BetterPlayer));
      await tester.pump();

      // Wait 200ms - controls should still be visible
      await tester.pump(const Duration(milliseconds: 200));

      // Wait another 350ms - total 550ms, which is > 500ms
      // Controls should be hidden
      await tester.pump(const Duration(milliseconds: 350));
    },
  );
}
