import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_video_player_controller.dart';

void main() {
  late BetterPlayerMockController mockController;

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    mockController =
        BetterPlayerMockController(const BetterPlayerConfiguration());
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'One of children is BetterPlayerWithControls',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ));

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
            const Key('better_player_material_controls_play_pause_button')),
        findsOneWidget,
      );
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
      await controller.setupDataSource(BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ));

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

  testWidgets(
    'Cupertino controls show play/pause button',
    (WidgetTester tester) async {
      final mockVideoPlayerController = MockVideoPlayerController();
      mockVideoPlayerController.setDuration(const Duration(seconds: 100));
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockVideoPlayerController,
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.cupertino,
          ),
        ),
      );
      await controller.setupDataSource(BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ));

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
        find.byIcon(controller.betterPlayerControlsConfiguration.playIcon),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Overflow menu opens on tap',
    (WidgetTester tester) async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ));

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

      final moreButton = find.byIcon(
          controller.betterPlayerControlsConfiguration.overflowMenuIcon);
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Check if one of the overflow items is visible
      expect(find.text(controller.translations.overflowMenuPlaybackSpeed),
          findsOneWidget);
    },
  );

  testWidgets(
    'Playback speed can be changed via overflow menu',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockVideoPlayerController(),
        configuration: const BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
            playerTheme: BetterPlayerTheme.material,
          ),
        ),
      );
      await controller.setupDataSource(BetterPlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ));

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

      final moreButton = find.byIcon(
          controller.betterPlayerControlsConfiguration.overflowMenuIcon);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final speedButton =
          find.text(controller.translations.overflowMenuPlaybackSpeed);
      await tester.tap(speedButton);
      await tester.pumpAndSettle();

      final speed2x = find.text('2.0 x');
      expect(speed2x, findsOneWidget);

      await tester.tap(speed2x);
      await tester.pumpAndSettle();

      expect(controller.videoPlayerController!.value.speed, 2.0);
    },
  );
}

///Wrap widget with material app to handle all features like navigation and
///localization properly.
Widget _wrapWidget(Widget widget) {
  return MaterialApp(home: widget);
}
