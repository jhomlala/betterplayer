import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'One of children is BetterPlayerWithControls',
    (tester) async {
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
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
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

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(
          const Key('better_player_material_controls_play_pause_button'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Material controls show mute button if enabled',
    (tester) async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
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

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Mute icon should be present by default
      expect(
        find.byIcon(controller.betterPlayerControlsConfiguration.muteIcon),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Cupertino controls show play/pause button',
    (tester) async {
      final mockVideoPlayerController = MockPlayerEngineController();
      mockVideoPlayerController.setDuration(const Duration(seconds: 100));
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockVideoPlayerController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.cupertino,
          ),
        ),
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byIcon(controller.betterPlayerControlsConfiguration.playIcon),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Overflow menu opens on tap',
    (tester) async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
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

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      controller.setControlsAlwaysVisible(true);
      await tester.pump();

      final moreButton = find.byIcon(
        controller.betterPlayerControlsConfiguration.overflowMenuIcon,
      );
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Check if one of the overflow items is visible
      expect(
        find.text(controller.translations.overflowMenuPlaybackSpeed),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Playback speed can be changed via overflow menu',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
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

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      controller.setControlsAlwaysVisible(true);
      await tester.pump();

      final moreButton = find.byIcon(
        controller.betterPlayerControlsConfiguration.overflowMenuIcon,
      );
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final speedButton = find.text(
        controller.translations.overflowMenuPlaybackSpeed,
      );
      await tester.tap(speedButton);
      await tester.pumpAndSettle();

      final speed2x = find.text('2.0 x');
      expect(
        speed2x,
        findsOneWidget,
      );

      await tester.tap(speed2x);
      await tester.pumpAndSettle();

      expect(controller.engineController!.value.speed, 2.0);
    },
  );

  testWidgets(
    'Material controls show progress bar',
    (tester) async {
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: MockPlayerEngineController(),
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

      await tester.pumpWidget(
        _wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byType(BetterPlayerMaterialVideoProgressBar),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Cupertino controls show progress bar',
    (tester) async {
      final mockVideoPlayerController = MockPlayerEngineController();
      mockVideoPlayerController.setDuration(const Duration(seconds: 100));
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mockVideoPlayerController,
        configuration: const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.cupertino,
          ),
        ),
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
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
      await tester.pump();

      expect(
        find.byType(BetterPlayerCupertinoVideoProgressBar),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Playlist navigation buttons in controls',
    (tester) async {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
        PlayerDataSource.network('https://example.com/2.mp4'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: BetterPlayerPlaylist(
              betterPlayerDataSourceList: dataSourceList,
              betterPlayerConfiguration: const PlayerConfiguration(
                controlsConfiguration: PlayerControlsConfiguration(
                  playerTheme: PlayerTheme.material,
                ),
              ),
              betterPlayerPlaylistConfiguration:
                  const PlayerPlaylistConfiguration(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BetterPlayerPlaylist), findsOneWidget);
    },
  );

  testWidgets(
    'Material progress bar handles null/uninitialized videoPlayerValue without throwing',
    (tester) async {
      final controller = BetterPlayerController(
        const PlayerConfiguration(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerMaterialVideoProgressBar(
              controller,
            ),
          ),
        ),
      );

      final progressBarFinder = find.byType(
        BetterPlayerMaterialVideoProgressBar,
      );
      expect(progressBarFinder, findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(progressBarFinder),
      );
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();
      await tester.pump();

      await tester.tap(progressBarFinder);
      await tester.pump();
    },
  );

  testWidgets(
    'Cupertino progress bar handles null/uninitialized videoPlayerValue without throwing',
    (tester) async {
      final controller = BetterPlayerController(
        const PlayerConfiguration(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerCupertinoVideoProgressBar(
              controller,
            ),
          ),
        ),
      );

      final progressBarFinder = find.byType(
        BetterPlayerCupertinoVideoProgressBar,
      );
      expect(progressBarFinder, findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(progressBarFinder),
      );
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();
      await tester.pump();

      await tester.tap(progressBarFinder);
      await tester.pump();
    },
  );
}

///Wrap widget with material app to handle all features like navigation and
///localization properly.
Widget _wrapWidget(Widget widget) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: false),
    home: widget,
  );
}
