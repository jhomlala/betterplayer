import 'package:better_player/better_player.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(body: widget),
    );
  }

  testWidgets(
    'Material controls have correct semantic labels for Play/Pause',
    (tester) async {
      final mockPlayerEngineController = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockPlayerEngineController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(wrapWidget(BetterPlayer(controller: controller)));
      await tester.pumpAndSettle();

      // Show controls
      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      // Check Play button semantics
      expect(
        find.bySemanticsLabel(controller.translations.controlsPlayLabel),
        findsWidgets,
      );

      // Change to playing state
      mockPlayerEngineController.value = mockPlayerEngineController.value
          .copyWith(isPlaying: true);
      await tester.pumpAndSettle();

      // Check Pause button semantics
      expect(
        find.bySemanticsLabel(controller.translations.controlsPauseLabel),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Material controls have correct semantic labels for Mute/Unmute',
    (tester) async {
      final mockPlayerEngineController = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockPlayerEngineController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(wrapWidget(BetterPlayer(controller: controller)));
      await tester.pumpAndSettle();

      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      // Initial state: Not muted (reports Mute action)
      expect(
        find.bySemanticsLabel(controller.translations.controlsMuteLabel),
        findsOneWidget,
      );

      // Change to muted state
      mockPlayerEngineController.value = mockPlayerEngineController.value
          .copyWith(volume: 0);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(controller.translations.controlsUnmuteLabel),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Progress bar has correct semantics and supports seeking via gestures',
    (tester) async {
      final handle = tester.ensureSemantics();
      final mockPlayerEngineController = MockPlayerEngineController();

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockPlayerEngineController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      // Set duration and position AFTER setupDataSource to avoid override
      const duration = Duration(minutes: 10);
      mockPlayerEngineController.setDuration(duration);
      mockPlayerEngineController.value = mockPlayerEngineController.value
          .copyWith(position: const Duration(minutes: 5));

      await tester.pumpWidget(wrapWidget(BetterPlayer(controller: controller)));
      await tester.pumpAndSettle();

      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      final progressBarFinder = find.bySemanticsLabel(
        controller.translations.progressBarLabel,
      );
      expect(progressBarFinder, findsOneWidget);

      // Check semantics value (50%)
      expect(
        tester.getSemantics(progressBarFinder),
        matchesSemantics(
          label: controller.translations.progressBarLabel,
          value: '50%',
          increasedValue: '60%',
          decreasedValue: '40%',
          isSlider: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      // Test Increase gesture (swipe up)
      final id = tester.getSemantics(progressBarFinder).id;
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();

      // Should seek forward by 10% (1 minute)
      expect(
        mockPlayerEngineController.lastSeekPosition,
        const Duration(minutes: 6),
      );

      // Test Decrease gesture (swipe down)
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        id,
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();

      // Should seek backward
      expect(
        mockPlayerEngineController.lastSeekPosition,
        const Duration(minutes: 5),
      );

      handle.dispose();
    },
  );
}
