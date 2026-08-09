import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_video_player_controller.dart';

class MockControlsState extends BetterPlayerControlsState<StatefulWidget> {
  final BetterPlayerController _controller;

  MockControlsState(this._controller);

  @override
  BetterPlayerController? get betterPlayerController => _controller;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controller.betterPlayerControlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _controller.videoPlayerController?.value;

  @override
  void cancelAndRestartTimer() {}

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BetterPlayerController controller;
  late MockControlsState state;

  setUp(() {
    controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
      controller: MockVideoPlayerController(),
    );
    state = MockControlsState(controller);
  });

  group('BetterPlayerControlsState logic tests', () {
    test('isVideoFinished returns true when at the end', () {
      final value = VideoPlayerValue(
        duration: const Duration(seconds: 10),
        position: const Duration(seconds: 10),
      );
      expect(state.isVideoFinished(value), true);
    });

    test('isVideoFinished returns false when not at the end', () {
      final value = VideoPlayerValue(
        duration: const Duration(seconds: 10),
        position: const Duration(seconds: 5),
      );
      expect(state.isVideoFinished(value), false);
    });

    test('skipForward seeks correctly', () async {
      final mock = controller.videoPlayerController as MockVideoPlayerController;
      mock.setDuration(const Duration(seconds: 100));
      await mock.seekTo(const Duration(seconds: 10));

      state.skipForward();
      expect(mock.value.position,
          const Duration(seconds: 20)); // Default skip is 10s
    });

    test('skipBack seeks correctly', () async {
      final mock = controller.videoPlayerController as MockVideoPlayerController;
      mock.setDuration(const Duration(seconds: 100));
      await mock.seekTo(const Duration(seconds: 50));

      state.skipBack();
      expect(mock.value.position,
          const Duration(seconds: 40)); // Default skip is 10s
    });

    test('isLoading logic', () {
      final valueNotPlaying = VideoPlayerValue(
        duration: null,
        isPlaying: false,
      );
      expect(state.isLoading(valueNotPlaying), true);

      final valueBuffering = VideoPlayerValue(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 50),
        isPlaying: true,
        isBuffering: true,
        buffered: [
          DurationRange(const Duration(seconds: 0), const Duration(seconds: 55)),
        ],
      );
      expect(state.isLoading(valueBuffering), true);
      
      final valueNotBuffering = VideoPlayerValue(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 50),
        isPlaying: true,
        isBuffering: false,
        buffered: [
          DurationRange(const Duration(seconds: 0), const Duration(seconds: 90)),
        ],
      );
      expect(state.isLoading(valueNotBuffering), false);
    });
  });
}
