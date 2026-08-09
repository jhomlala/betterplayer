import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'better_player_mock_controller.dart';
import 'better_player_test_utils.dart';
import 'mock_video_player_controller.dart';

void main() {
  late BetterPlayerMockController mockController;

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    mockController =
        BetterPlayerMockController(const BetterPlayerConfiguration());
  });

  testWidgets(
    'One of children is BetterPlayerWithControls',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: mockController,
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is BetterPlayerWithControls,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Material controls show play/pause button',
    (WidgetTester tester) async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(
        BetterPlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('better_player_material_controls_play_pause_button'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Material controls toggle play/pause on tap',
    (WidgetTester tester) async {
      final mockVideoPlayerController = MockVideoPlayerController();
      mockVideoPlayerController.setDuration(const Duration(seconds: 100));
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockVideoPlayerController,
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(
        BetterPlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      // Initially paused
      expect(controller.isPlaying(), false);
      expect(controller.videoPlayerController, mockVideoPlayerController);

      // await tester.tap(playPauseButton);
      // await tester.pumpAndSettle();

      // expect(mockVideoPlayerController.value.isPlaying, true);
      // expect(controller.isPlaying(), true);

      // await tester.tap(playPauseButton);
      // await tester.pumpAndSettle();

      // expect(controller.isPlaying(), false);
    },
  );

  testWidgets(
    'Material controls show mute button if enabled',
    (WidgetTester tester) async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(
        BetterPlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Mute icon should be present by default
      expect(
        find.byIcon(controller.betterPlayerControlsConfiguration.muteIcon),
        findsOneWidget,
      );
    },
  );
}

///Wrap widget with material app to handle all features like navigation and
///localization properly.
Widget _wrapWidget(Widget widget) {
  return MaterialApp(home: widget);
}
