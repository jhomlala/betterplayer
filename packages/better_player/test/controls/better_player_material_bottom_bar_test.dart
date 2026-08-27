import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_material_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';
import '../helpers/mock_video_player_controller.dart';

void main() {
  late BetterPlayerMockController mockController;
  late MockVideoPlayerController mockVideoPlayerController;

  setUp(() async {
    final mockMethodChannel = MockMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );

    mockVideoPlayerController = MockVideoPlayerController();
    mockController = BetterPlayerMockController(
      const PlayerConfiguration(),
    );
    mockController.videoPlayerController = mockVideoPlayerController;
    await mockController.setupDataSource(
      PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
    );
  });

  Widget wrapWidget(Widget widget) {
    return MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    );
  }

  testWidgets('Material bottom bar shows play button when paused', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialBottomBar(
          controller: mockController,
          controlsConfiguration: const PlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {},
          onMute: () {},
          onExpandCollapse: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          latestValue: VideoPlayerValue(duration: const Duration(seconds: 10)),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow_outlined), findsOneWidget);
  });

  testWidgets('Material bottom bar shows pause button when playing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialBottomBar(
          controller: mockController,
          controlsConfiguration: const PlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {},
          onMute: () {},
          onExpandCollapse: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          latestValue: VideoPlayerValue(
            duration: const Duration(seconds: 10),
            isPlaying: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pause_outlined), findsOneWidget);
  });

  testWidgets('Material bottom bar triggers onPlayPause callback', (
    tester,
  ) async {
    var playPauseTriggered = false;
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialBottomBar(
          controller: mockController,
          controlsConfiguration: const PlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {
            playPauseTriggered = true;
          },
          onMute: () {},
          onExpandCollapse: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          latestValue: VideoPlayerValue(duration: const Duration(seconds: 10)),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const Key('better_player_material_controls_play_pause_button'),
      ),
    );
    expect(playPauseTriggered, isTrue);
  });

  testWidgets('Material bottom bar shows mute icon when volume is 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWidget(
        BetterPlayerMaterialBottomBar(
          controller: mockController,
          controlsConfiguration: const PlayerControlsConfiguration(),
          controlsNotVisible: false,
          onPlayerHide: () {},
          onPlayPause: () {},
          onMute: () {},
          onExpandCollapse: () {},
          onProgressBarDragStart: () {},
          onProgressBarDragEnd: () {},
          onProgressBarTapDown: () {},
          latestValue: VideoPlayerValue(
            duration: const Duration(seconds: 10),
            volume: 0,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
  });
}
