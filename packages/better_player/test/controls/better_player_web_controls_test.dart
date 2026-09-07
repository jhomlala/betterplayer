import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_web_controls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
      home: Scaffold(
        body: widget,
      ),
    );
  }

  Future<void> setupControls(WidgetTester tester) async {
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
    'BetterPlayerWebControls is rendered and basic buttons exist',
    (tester) async {
      await setupControls(tester);
      expect(find.byType(BetterPlayerWebControls), findsOneWidget);
      
      // Verify basic buttons exist by semantics
      expect(find.bySemanticsLabel('better_player_material_controls_play_pause_button'), findsOneWidget);
      expect(find.bySemanticsLabel('better_player_material_controls_mute_button'), findsOneWidget);
      expect(find.bySemanticsLabel('better_player_material_controls_fullscreen_button'), findsOneWidget);
      expect(find.bySemanticsLabel('better_player_material_controls_more_button'), findsOneWidget);
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

    expect(controller.videoPlayerValue?.isPlaying, true);

    await tester.tap(playPauseButton);
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

    // Initial width should be 0 (volume slider is hidden)
    final volumeSliderFinder = find.byType(AnimatedContainer).first;
    expect(tester.widget<AnimatedContainer>(volumeSliderFinder).constraints?.maxWidth, 0.0);

    // Hover mute button area to expand slider
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(muteButton));
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedContainer>(volumeSliderFinder).constraints?.maxWidth, 100.0);

    await tester.tap(muteButton);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.volume, 0.0);

    await tester.tap(muteButton);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.volume, 1.0);
  });

  testWidgets('Keyboard shortcuts work', (tester) async {
    await setupControls(tester);

    // Focus the controls to receive key events
    await tester.tap(find.byType(BetterPlayerWebControls));
    await tester.pump();

    // Space to play
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.isPlaying, true);

    // M to mute
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    expect(controller.videoPlayerValue?.volume, 0.0);
  });

  testWidgets('Settings menu opens and handles selection', (tester) async {
    await setupControls(tester);

    final moreButton = find.bySemanticsLabel(
      'better_player_material_controls_more_button',
    );
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    final speedItem = find.text('Playback speed');
    expect(speedItem, findsOneWidget);
    
    await tester.tap(speedItem);
    await tester.pumpAndSettle();

    final speed2x = find.text('2.0x');
    expect(speed2x, findsOneWidget);
    await tester.tap(speed2x);
    await tester.pumpAndSettle();

    expect(controller.videoPlayerValue?.speed, 2.0);
  });
}
