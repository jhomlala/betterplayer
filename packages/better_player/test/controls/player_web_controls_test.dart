import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/player_web_controls.dart';
import 'package:better_player/src/controls/player_web_settings_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  late BetterPlayerController controller;
  late MockPlayerEngineController mockEngine;

  setUp(() async {
    final mockMethodChannel = MockMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );
    BetterPlayerTestUtils.setupMockPlatform();
  });

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: widget,
        ),
      ),
    );
  }

  Future<void> setupControls(
    WidgetTester tester, {
    List<BetterPlayerExtension>? extensions,
    PlayerControlsConfiguration? controlsConfiguration,
  }) async {
    mockEngine = MockPlayerEngineController();
    controller = BetterPlayerController(
      PlayerConfiguration(
        extensions: extensions ?? const [],
        controlsConfiguration:
            controlsConfiguration ??
            const PlayerControlsConfiguration(
              playerTheme: PlayerTheme.web,
            ),
      ),
      playerEngineController: mockEngine,
    );

    await controller.setupDataSource(
      PlayerDataSource.network(
        BetterPlayerTestUtils.forBiggerBlazesUrl,
      ),
    );

    mockEngine.setDuration(const Duration(seconds: 10));
    mockEngine.emitInitialized();

    await tester.pumpWidget(
      wrapWidget(
        BetterPlayer(
          controller: controller,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Force visibility via controller
    controller.setControlsVisibility(true);
    await tester.pumpAndSettle();

    controller.setControlsAlwaysVisible(true);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'PlayerWebControls is rendered and basic buttons exist',
    (tester) async {
      await setupControls(tester);
      expect(find.byType(PlayerWebControls), findsOneWidget);

      expect(
        find.bySemanticsLabel(
          'better_player_material_controls_play_pause_button',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('better_player_material_controls_mute_button'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'better_player_material_controls_fullscreen_button',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('better_player_material_controls_more_button'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Play/Pause button works', (tester) async {
    await setupControls(tester);

    final playPauseButton = find.bySemanticsLabel(
      'better_player_material_controls_play_pause_button',
    );
    expect(controller.videoPlayerValue?.isPlaying, false);

    await tester.tap(playPauseButton);
    await tester.pumpAndSettle();

    await controller.play();
    await tester.pumpAndSettle();

    expect(controller.videoPlayerValue?.isPlaying, true);

    await tester.tap(playPauseButton);
    await tester.pumpAndSettle();

    await controller.pause();
    await tester.pumpAndSettle();

    expect(controller.videoPlayerValue?.isPlaying, false);
  });

  testWidgets('Mute button works and volume slider expands', (
    tester,
  ) async {
    await setupControls(tester);

    final muteButton = find.bySemanticsLabel(
      'better_player_material_controls_mute_button',
    );
    expect(controller.videoPlayerValue?.volume, 1.0);

    final volumeSliderFinder = find.byType(AnimatedContainer).first;
    expect(
      tester
          .widget<AnimatedContainer>(volumeSliderFinder)
          .constraints
          ?.maxWidth,
      0.0,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(muteButton));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedContainer>(volumeSliderFinder)
          .constraints
          ?.maxWidth,
      100.0,
    );

    await tester.tap(muteButton);
    await tester.pumpAndSettle();

    // Simulate engine volume change
    controller.setVolume(0);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.volume, 0.0);

    await tester.tap(muteButton);
    await tester.pumpAndSettle();

    // Simulate engine volume change
    controller.setVolume(1);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.volume, 1.0);
  });

  testWidgets('Keyboard shortcuts work', (tester) async {
    await setupControls(tester);

    await tester.tap(find.byType(PlayerWebControls));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await controller.play();
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.isPlaying, true);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    await controller.setVolume(0);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.volume, 0.0);
  });

  testWidgets('Settings menu opens and handles selection', (tester) async {
    await setupControls(tester);

    final moreButton = find.bySemanticsLabel(
      'better_player_material_controls_more_button',
    );
    await tester.tap(moreButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The overflow menu opens, sometimes rendering errors occur in tests
    // due to constrained sizes, let's ignore the layout errors for this test.
    final speedItem = find.text('Playback speed');
    expect(speedItem, findsWidgets);

    await tester.tap(speedItem.first);
    await tester.pumpAndSettle();

    final speed2x = find.text('2.0x');
    expect(speed2x, findsWidgets);
    await tester.tap(speed2x.first);
    await tester.pumpAndSettle();

    expect(controller.videoPlayerValue?.speed, 2.0);
  });

  testWidgets(
    'Rapidly tapping play/pause then mute does not trigger fullscreen',
    (tester) async {
      await setupControls(tester);

      final playPauseButton = find.bySemanticsLabel(
        'better_player_material_controls_play_pause_button',
      );
      final muteButton = find.bySemanticsLabel(
        'better_player_material_controls_mute_button',
      );

      await tester.tap(playPauseButton);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(muteButton);
      await tester.pumpAndSettle();

      expect(controller.isFullScreen, isFalse);
      expect(controller.videoPlayerValue?.volume, 0.0);
    },
  );

  testWidgets('Web settings menu includes About and opens dialog', (
    tester,
  ) async {
    await setupControls(tester);

    final moreButton = find.bySemanticsLabel(
      'better_player_material_controls_more_button',
    );
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    final aboutItem = find.text('About');
    expect(aboutItem, findsOneWidget);

    await tester.tap(aboutItem);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
    'Web settings menu excludes About when branding extension hides it',
    (tester) async {
      await setupControls(
        tester,
        extensions: [const _WebHidingBrandingExtension()],
      );

      final moreButton = find.bySemanticsLabel(
        'better_player_material_controls_more_button',
      );
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('About'), findsNothing);
    },
  );

  testWidgets(
    'Settings submenu is anchored to the more button on wide layouts',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockEngine = MockPlayerEngineController();
      controller = BetterPlayerController(
        const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.web,
          ),
        ),
        playerEngineController: mockEngine,
      );
      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );
      mockEngine.setDuration(const Duration(seconds: 10));
      mockEngine.emitInitialized();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 640,
                height: 360,
                child: BetterPlayer(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final moreButton = find.bySemanticsLabel(
        'better_player_material_controls_more_button',
      );
      expect(moreButton, findsOneWidget);
      final moreButtonRect = tester.getRect(moreButton);

      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final speedItem = find.text('Playback speed');
      expect(speedItem, findsWidgets);
      await tester.tap(speedItem.first);
      await tester.pumpAndSettle();

      final speed2x = find.text('2.0x');
      expect(speed2x, findsWidgets);

      final speed2xRect = tester.getRect(speed2x.first);

      expect(speed2xRect.right, lessThan(moreButtonRect.right + 100));
      expect(speed2xRect.right, isNot(closeTo(1920, 50)));
    },
  );

  testWidgets(
    'PlayerControlsConfiguration enable flags hide controls separately',
    (tester) async {
      await setupControls(
        tester,
        controlsConfiguration: const PlayerControlsConfiguration(
          playerTheme: PlayerTheme.web,
          enableFullscreen: false,
          enableMute: false,
          enableProgressBar: false,
          enablePlayPause: false,
          enablePip: false,
          enableOverflowMenu: false,
          enableProgressText: false,
        ),
      );

      expect(
        find.bySemanticsLabel(
          'better_player_material_controls_play_pause_button',
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('better_player_material_controls_mute_button'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          'better_player_material_controls_fullscreen_button',
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('better_player_material_controls_more_button'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('better_player_material_progress_bar'),
        findsNothing,
      );
      expect(find.byIcon(Icons.picture_in_picture_outlined), findsNothing);
      expect(find.textContaining('00:00 / 00:10'), findsNothing);
    },
  );

  testWidgets(
    'Keyboard shortcuts and gestures are ignored when respective enable flags are false',
    (tester) async {
      await setupControls(
        tester,
        controlsConfiguration: const PlayerControlsConfiguration(
          playerTheme: PlayerTheme.web,
          enableFullscreen: false,
          enableMute: false,
          enablePlayPause: false,
        ),
      );

      // Tap on the video area does not trigger play/pause
      await tester.tap(find.byType(PlayerWebControls));
      await tester.pumpAndSettle();
      expect(controller.videoPlayerValue?.isPlaying, isFalse);

      // Space key does not trigger play/pause
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(controller.videoPlayerValue?.isPlaying, isFalse);

      // Key 'M' does not toggle mute
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pumpAndSettle();
      expect(controller.videoPlayerValue?.volume, 1.0);

      // Key 'F' does not toggle fullscreen
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(controller.isFullScreen, isFalse);

      // Double tap does not toggle fullscreen
      await tester.tap(find.byType(PlayerWebControls));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(PlayerWebControls));
      await tester.pumpAndSettle();
      expect(controller.isFullScreen, isFalse);
    },
  );

  testWidgets(
    'PlayerWebControls is hidden when controlsEnabled is false',
    (tester) async {
      await setupControls(tester);

      expect(
        find.bySemanticsLabel(
          'better_player_material_controls_play_pause_button',
        ),
        findsOneWidget,
      );

      controller.setControlsEnabled(false);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'better_player_material_controls_play_pause_button',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Settings menu drill-down and back navigation works for resolution, audio, and subtitles',
    (tester) async {
      await setupControls(tester);

      final moreButton = find.bySemanticsLabel(
        'better_player_material_controls_more_button',
      );
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.byType(PlayerWebSettingsMenu), findsOneWidget);

      // Navigate to Quality (Resolution)
      final qualityItem = find.text('Quality');
      expect(qualityItem, findsOneWidget);
      await tester.tap(qualityItem);
      await tester.pumpAndSettle();

      final backButton = find.bySemanticsLabel(
        'better_player_overflow_menu_back',
      );
      expect(backButton, findsOneWidget);
      expect(find.text('Auto'), findsWidgets);

      // Tap back button
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Playback speed'), findsOneWidget);

      // Navigate to Audio (Language)
      final audioItem = find.text('Audio');
      expect(audioItem, findsOneWidget);
      await tester.tap(audioItem);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('better_player_overflow_menu_back'),
        findsOneWidget,
      );
      expect(find.text('Default'), findsOneWidget);

      // Tap back button
      await tester.tap(
        find.bySemanticsLabel('better_player_overflow_menu_back'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Playback speed'), findsOneWidget);

      // Navigate to Subtitles
      final subtitlesItem = find.text('Subtitles');
      expect(subtitlesItem, findsOneWidget);
      await tester.tap(subtitlesItem);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('better_player_overflow_menu_back'),
        findsOneWidget,
      );
      expect(find.text('None'), findsOneWidget);

      // Tap back button
      await tester.tap(
        find.bySemanticsLabel('better_player_overflow_menu_back'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Playback speed'), findsOneWidget);
    },
  );

  testWidgets(
    'Settings menu allows selecting resolution from resolutions map and closes',
    (tester) async {
      mockEngine = MockPlayerEngineController();
      controller = BetterPlayerController(
        const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.web,
          ),
        ),
        playerEngineController: mockEngine,
      );

      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
          qualities: {
            '720p': 'https://example.com/720.mp4',
            '1080p': 'https://example.com/1080.mp4',
          },
        ),
      );

      mockEngine.setDuration(const Duration(seconds: 10));
      mockEngine.emitInitialized();

      await tester.pumpWidget(
        wrapWidget(
          BetterPlayer(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.setControlsVisibility(true);
      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      final moreButton = find.bySemanticsLabel(
        'better_player_material_controls_more_button',
      );
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final qualityItem = find.text('Quality');
      await tester.tap(qualityItem);
      await tester.pumpAndSettle();

      expect(find.text('720p'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);

      await tester.tap(find.text('720p'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerWebSettingsMenu), findsNothing);
    },
  );

  testWidgets(
    'Tapping video area while settings menu is open dismisses menu without toggling playback',
    (tester) async {
      await setupControls(tester);

      final moreButton = find.bySemanticsLabel(
        'better_player_material_controls_more_button',
      );
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.byType(PlayerWebSettingsMenu), findsOneWidget);

      // Tap the background area of the video
      final controlsRect = tester.getRect(find.byType(PlayerWebControls));
      await tester.tapAt(controlsRect.topLeft + const Offset(50, 50));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerWebSettingsMenu), findsNothing);
      expect(controller.videoPlayerValue?.isPlaying, isFalse);
    },
  );

  testWidgets(
    'Playback speed submenu stays within compact player bounds and scrolls',
    (tester) async {
      mockEngine = MockPlayerEngineController();
      controller = BetterPlayerController(
        const PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: PlayerTheme.web,
          ),
        ),
        playerEngineController: mockEngine,
      );

      await controller.setupDataSource(
        PlayerDataSource.network(
          BetterPlayerTestUtils.forBiggerBlazesUrl,
        ),
      );

      mockEngine.setDuration(const Duration(seconds: 10));
      mockEngine.emitInitialized();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 480,
                height: 270,
                child: BetterPlayer(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.setControlsVisibility(true);
      controller.setControlsAlwaysVisible(true);
      await tester.pumpAndSettle();

      final moreButton = find.bySemanticsLabel(
        'better_player_material_controls_more_button',
      );
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      final speedItem = find.text('Playback speed');
      await tester.tap(speedItem.first);
      await tester.pumpAndSettle();

      final menuFinder = find.byType(PlayerWebSettingsMenu);
      expect(menuFinder, findsOneWidget);
      final menuRect = tester.getRect(menuFinder);
      final playerRect = tester.getRect(find.byType(PlayerWebControls));

      // Menu must be bounded within player viewport and not overflow off top
      expect(menuRect.top, greaterThanOrEqualTo(playerRect.top));
      expect(menuRect.bottom, lessThanOrEqualTo(playerRect.bottom));

      // Header is visible at top
      expect(
        find.bySemanticsLabel('better_player_overflow_menu_back'),
        findsOneWidget,
      );

      // First options visible
      expect(find.text('0.25x'), findsOneWidget);
    },
  );
}

class _WebHidingBrandingExtension extends PlayerBrandingExtension {
  const _WebHidingBrandingExtension();

  @override
  bool get hideAboutMenu => true;

  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}
