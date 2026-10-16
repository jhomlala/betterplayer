import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  setUpAll(BetterPlayerTestUtils.setupMockPlatform);

  group('controlsVisibilityStream tests', () {
    testWidgets(
      'emits true and false on Material controls lifecycle',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.material,
                  controlsHideTime: Duration(milliseconds: 500),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

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

        // Wait for player and _initTimer to initialize controls
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(events, contains(true));
        expect(controller.isControlsVisible, true);

        // Programmatically hide controls
        controller.setControlsVisibility(false);
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);

        // Tap on player to show controls again
        await tester.tap(find.byType(BetterPlayer));
        await tester.pump();
        // Wait for transition to complete
        await tester.pump(const Duration(milliseconds: 350));
        expect(events.last, true);
        expect(controller.isControlsVisible, true);

        // Advance past controlsHideTime (500ms) + transition (300ms) to auto-hide
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'emits true and false on Cupertino controls lifecycle',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.cupertino,
                  controlsHideTime: Duration(milliseconds: 500),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

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

        // Wait for player and _initTimer to initialize controls
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(events, contains(true));
        expect(controller.isControlsVisible, true);

        // Programmatically hide controls
        controller.setControlsVisibility(false);
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);

        // Tap on player to show controls again
        await tester.tap(find.byType(BetterPlayer));
        await tester.pump();
        // Wait for transition to complete
        await tester.pump(const Duration(milliseconds: 350));
        expect(events.last, true);
        expect(controller.isControlsVisible, true);

        // Advance past controlsHideTime (500ms) + transition (300ms) to auto-hide
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'emits true and false on Web controls lifecycle',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.web,
                  controlsHideTime: Duration(milliseconds: 300),
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

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

        // Wait for initialize
        await tester.pumpAndSettle();
        expect(events, contains(true));
        expect(controller.isControlsVisible, true);

        // Wait for controlsHideTime to hide
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(events.last, false);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'emits when custom controls trigger onControlsVisibilityChanged',
      (tester) async {
        void Function(bool)? visibilityCallback;

        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.custom,
                  customControlsBuilder: (ctrl, onVisibilityChanged) {
                    visibilityCallback = onVisibilityChanged;
                    return const SizedBox();
                  },
                ),
              ),
            );

        final events = <bool>[];
        controller.controlsVisibilityStream.listen(events.add);

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

        await tester.pumpAndSettle();
        expect(visibilityCallback, isNotNull);

        visibilityCallback!(true);
        await tester.pump();
        expect(events, [true]);
        expect(controller.isControlsVisible, true);

        visibilityCallback!(false);
        await tester.pump();
        expect(events, [true, false]);
        expect(controller.isControlsVisible, false);
      },
    );

    testWidgets(
      'mounting PlayerWebControls does not trigger setState or markNeedsBuild during build',
      (tester) async {
        final mockPlayerEngineController = MockPlayerEngineController();
        mockPlayerEngineController.setDuration(const Duration(seconds: 100));

        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockPlayerEngineController,
              configuration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.web,
                ),
              ),
            );

        await controller.setupDataSource(
          PlayerDataSource.network(
            BetterPlayerTestUtils.forBiggerBlazesUrl,
          ),
        );

        var rebuildCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                controller.controlsVisibilityStream.listen((_) {
                  setState(() {
                    rebuildCount++;
                  });
                });
                return Scaffold(
                  body: BetterPlayer(
                    controller: controller,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(rebuildCount, greaterThan(0));
        expect(controller.isControlsVisible, true);
      },
    );
  });
}
