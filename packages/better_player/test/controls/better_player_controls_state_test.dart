import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';

class MockControlsWidget extends StatefulWidget {

  const MockControlsWidget({
    required this.controller,
    super.key,
  });
  final BetterPlayerController controller;

  @override
  MockControlsState createState() => MockControlsState();
}

class MockControlsState extends BetterPlayerControlsState<MockControlsWidget> {
  @override
  BetterPlayerController? get betterPlayerController => widget.controller;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      widget.controller.betterPlayerControlsConfiguration;

  @override
  VideoPlayerValue? get latestValue =>
      widget.controller.videoPlayerController?.value;

  @override
  void cancelAndRestartTimer() {}

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

void main() {
  group('BetterPlayerControlsState tests', () {
    late BetterPlayerMockController controller;

    setUp(() {
      controller = BetterPlayerMockController(
        const BetterPlayerConfiguration(),
      );
    });

    test('isVideoFinished returns true when position >= duration', () {
      final state = MockControlsState();
      final value = VideoPlayerValue(
        duration: const Duration(seconds: 10),
        position: const Duration(seconds: 10),
      );
      expect(state.isVideoFinished(value), true);

      final value2 = VideoPlayerValue(
        duration: const Duration(seconds: 10),
        position: const Duration(seconds: 5),
        isPlaying: true,
      );
      expect(state.isVideoFinished(value2), false);
    });

    test('isLoading returns true when buffering', () {
      final state = MockControlsState();
      final value = VideoPlayerValue(
        duration: const Duration(seconds: 10),
        position: const Duration(seconds: 5),
        buffered: [
          DurationRange(Duration.zero, const Duration(seconds: 6)),
        ],
        isBuffering: true,
        isPlaying: true,
      );
      // _bufferingInterval is 20000ms (20s). 6s - 5s = 1s < 20s.
      expect(state.isLoading(value), true);
    });

    testWidgets('changePlayerControlsNotVisible updates state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockControlsWidget(controller: controller),
        ),
      );

      final state = tester.state<MockControlsState>(
        find.byType(MockControlsWidget),
      );
      expect(state.controlsNotVisible, true);

      state.changePlayerControlsNotVisible(false);
      expect(state.controlsNotVisible, false);
    });
  });
}
