import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

void main() {
  test(
    'setupDataSource controller event is posted after setup completes',
    () async {
      final mock = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final events = <PlayerControllerEvent>[];
      controller.controllerEventStream.listen(events.add);

      await controller.setupDataSource(
        PlayerDataSource.file('test/video.mp4'),
      );

      // Verify that setupDataSource controller event was posted
      expect(events.contains(PlayerControllerEvent.setupDataSource), true);
    },
  );
}
