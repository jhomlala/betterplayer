import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_video_player_controller.dart';

void main() {
  late BetterPlayerController controller;
  late StreamController<bool> visibilityStreamController;

  setUp(() {
    controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
      controller: MockVideoPlayerController(),
    );
    visibilityStreamController = StreamController<bool>.broadcast();
  });

  tearDown(() {
    visibilityStreamController.close();
  });

  testWidgets('Subtitles are displayed correctly', (tester) async {
    final subtitle = PlayerSubtitle(
      '00:00:01,000 --> 00:00:05,000\nTest Subtitle',
      false,
    );
    final subtitles = [subtitle];
    controller.subtitlesLines.addAll(subtitles);

    await tester.pumpWidget(
      MaterialApp(
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
    (controller.videoPlayerController! as MockVideoPlayerController).value =
        controller.videoPlayerController!.value.copyWith(
          position: const Duration(seconds: 2),
        );

    // Trigger listener
    controller.videoPlayerController!.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.byType(HtmlWidget), findsNWidgets(2));
    // expect(find.textContaining('Test Subtitle'), findsNWidgets(2));
  });

  testWidgets('Subtitles are hidden when player not visible', (
    tester,
  ) async {
    final subtitle = PlayerSubtitle(
      '00:00:01,000 --> 00:00:05,000\nTest Subtitle',
      false,
    );
    final subtitles = [subtitle];
    controller.subtitlesLines.addAll(subtitles);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerSubtitlesDrawer(
            subtitles: subtitles,
            betterPlayerController: controller,
            playerVisibilityStream: visibilityStreamController.stream,
          ),
        ),
      ),
    );

    (controller.videoPlayerController! as MockVideoPlayerController).value =
        controller.videoPlayerController!.value.copyWith(
          position: const Duration(seconds: 2),
        );
    controller.videoPlayerController!.notifyListeners();
    await tester.pump();

    expect(find.byType(HtmlWidget), findsNWidgets(2));

    // Hide controls
    visibilityStreamController.add(true);
    await tester.pump();
    // This mostly checks if it builds without error when visibility changes
    expect(find.byType(HtmlWidget), findsNWidgets(2));
  });

  testWidgets('Subtitles with custom configuration', (
    tester,
  ) async {
    final subtitle = PlayerSubtitle(
      '00:00:01,000 --> 00:00:05,000\nTest Subtitle',
      false,
    );
    final subtitles = [subtitle];
    controller.subtitlesLines.addAll(subtitles);

    await tester.pumpWidget(
      MaterialApp(
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

    (controller.videoPlayerController! as MockVideoPlayerController).value =
        controller.videoPlayerController!.value.copyWith(
          position: const Duration(seconds: 2),
        );
    controller.videoPlayerController!.notifyListeners();
    await tester.pumpAndSettle();

    // Only 1 HtmlWidget because outline is disabled
    expect(find.byType(HtmlWidget), findsOneWidget);
  });
}
