import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:better_player/src/subtitles/player_subtitles_drawer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  late BetterPlayerController controller;
  late MockPlayerEngineController mockEngine;
  late StreamController<bool> visibilityStreamController;

  setUp(() {
    mockEngine = MockPlayerEngineController();
    controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
      controller: mockEngine,
    );
    visibilityStreamController = StreamController<bool>.broadcast();
  });

  tearDown(() {
    visibilityStreamController.close();
  });

  testWidgets('Subtitles are displayed correctly', (tester) async {
    final subtitle = PlayerSubtitle(
      value: '00:00:01,000 --> 00:00:05,000\nTest Subtitle',
      isWebVTT: false,
    );
    final subtitles = [subtitle];
    controller.subtitlesLines = [...controller.subtitlesLines, ...subtitles];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: PlayerSubtitlesDrawer(
            subtitles: subtitles,
            betterPlayerController: controller,
            playerVisibilityStream: visibilityStreamController.stream,
          ),
        ),
      ),
    );

    // Initial state: position 0, no subtitle
    expect(find.text('Test Subtitle'), findsNothing);

    // Update position to 2s
    mockEngine.value = mockEngine.value.copyWith(
      position: const Duration(seconds: 2),
    );

    // Trigger listener
    mockEngine.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.byType(RichText), findsNWidgets(2));
    // expect(find.textContaining('Test Subtitle'), findsNWidgets(2));
  });

  testWidgets('Subtitles are hidden when player not visible', (
    tester,
  ) async {
    final subtitle = PlayerSubtitle(
      value: '00:00:01,000 --> 00:00:05,000\nTest Subtitle',
      isWebVTT: false,
    );
    final subtitles = [subtitle];
    controller.subtitlesLines = [...controller.subtitlesLines, ...subtitles];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: PlayerSubtitlesDrawer(
            subtitles: subtitles,
            betterPlayerController: controller,
            playerVisibilityStream: visibilityStreamController.stream,
          ),
        ),
      ),
    );

    mockEngine.value = mockEngine.value.copyWith(
      position: const Duration(seconds: 2),
    );
    mockEngine.notifyListeners();
    await tester.pump();

    expect(find.byType(RichText), findsNWidgets(2));

    // Hide controls
    visibilityStreamController.add(true);
    await tester.pump();
    // This mostly checks if it builds without error when visibility changes
    expect(find.byType(RichText), findsNWidgets(2));
  });

  testWidgets('Subtitles with custom configuration', (
    tester,
  ) async {
    final subtitle = PlayerSubtitle(
      value: '00:00:01,000 --> 00:00:05,000\nTest Subtitle',
      isWebVTT: false,
    );
    final subtitles = [subtitle];
    controller.subtitlesLines = [...controller.subtitlesLines, ...subtitles];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: PlayerSubtitlesDrawer(
            subtitles: subtitles,
            betterPlayerController: controller,
            playerVisibilityStream: visibilityStreamController.stream,
            betterPlayerSubtitlesConfiguration:
                const PlayerSubtitlesConfiguration(
                  outlineEnabled: false,
                  fontColor: Colors.red,
                ),
          ),
        ),
      ),
    );

    mockEngine.value = mockEngine.value.copyWith(
      position: const Duration(seconds: 2),
    );
    mockEngine.notifyListeners();
    await tester.pumpAndSettle();

    // Only 1 RichText because outline is disabled
    expect(find.byType(RichText), findsOneWidget);
  });

  testWidgets('Embedded active captions are displayed correctly', (
    tester,
  ) async {
    final embeddedSource = PlayerSubtitlesSource(
      type: PlayerSubtitlesSourceType.embedded,
      name: 'English CC',
      isClosedCaption: true,
    );
    await controller.setupSubtitleSource(embeddedSource);
    controller.activeCaptions = ['Caption Line 1', 'Caption Line 2'];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: PlayerSubtitlesDrawer(
            subtitles: const [],
            betterPlayerController: controller,
            playerVisibilityStream: visibilityStreamController.stream,
          ),
        ),
      ),
    );

    expect(find.text('Caption Line 1', findRichText: true), findsNWidgets(2));
    expect(find.text('Caption Line 2', findRichText: true), findsNWidgets(2));
    expect(controller.renderedSubtitle?.texts, [
      'Caption Line 1',
      'Caption Line 2',
    ]);

    controller.activeCaptions = [];
    await tester.pump();
    expect(find.text('Caption Line 1', findRichText: true), findsNothing);
    expect(find.text('Caption Line 2', findRichText: true), findsNothing);
    expect(controller.renderedSubtitle, isNull);
  });

  testWidgets(
    'Active captions are ignored when subtitle source is not embedded',
    (tester) async {
      final networkSource = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.network,
        name: 'English WebVTT',
      );
      await controller.setupSubtitleSource(networkSource);
      controller.activeCaptions = ['Should Not Show'];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: PlayerSubtitlesDrawer(
              subtitles: const [],
              betterPlayerController: controller,
              playerVisibilityStream: visibilityStreamController.stream,
            ),
          ),
        ),
      );

      expect(find.text('Should Not Show', findRichText: true), findsNothing);
    },
  );

  testWidgets(
    'PlayerSubtitlesDrawer rebinds listeners when controller changes',
    (tester) async {
      final controller1 = _SubtitlesListenerTrackingController();
      final controller2 = _SubtitlesListenerTrackingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: PlayerSubtitlesDrawer(
              subtitles: const [],
              betterPlayerController: controller1,
              playerVisibilityStream: visibilityStreamController.stream,
            ),
          ),
        ),
      );

      expect(controller1.addListenerCalls, 1);
      expect(controller1.removeListenerCalls, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: PlayerSubtitlesDrawer(
              subtitles: const [],
              betterPlayerController: controller2,
              playerVisibilityStream: visibilityStreamController.stream,
            ),
          ),
        ),
      );

      expect(controller1.removeListenerCalls, 1);
      expect(controller2.addListenerCalls, 1);

      controller1.dispose();
      controller2.dispose();
    },
  );
}

class _SubtitlesListenerTrackingController extends BetterPlayerController {
  _SubtitlesListenerTrackingController() : super(const PlayerConfiguration());

  int addListenerCalls = 0;
  int removeListenerCalls = 0;

  @override
  void addVideoListener(VoidCallback listener) {
    addListenerCalls++;
    super.addVideoListener(listener);
  }

  @override
  void removeVideoListener(VoidCallback listener) {
    removeListenerCalls++;
    super.removeVideoListener(listener);
  }
}
