import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerEventsExtension', () {
    test('addEventsListener receives posted events', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      final events = <PlayerEvent>[];

      void listener(PlayerEvent event) {
        events.add(event);
      }

      controller.addEventsListener(listener);
      controller.postEvent(PlayerEvent(PlayerEventType.play));
      controller.postEvent(PlayerEvent(PlayerEventType.pause));

      expect(events.length, 2);
      expect(events[0].betterPlayerEventType, PlayerEventType.play);
      expect(events[1].betterPlayerEventType, PlayerEventType.pause);

      controller.dispose();
    });

    test('removeEventsListener stops receiving events', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      final events = <PlayerEvent>[];

      void listener(PlayerEvent event) {
        events.add(event);
      }

      controller.addEventsListener(listener);
      controller.postEvent(PlayerEvent(PlayerEventType.play));

      controller.removeEventsListener(listener);
      controller.postEvent(PlayerEvent(PlayerEventType.pause));

      expect(events.length, 1);
      expect(events.first.betterPlayerEventType, PlayerEventType.play);

      controller.dispose();
    });

    test('multiple listeners all receive posted events', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      final list1 = <PlayerEvent>[];
      final list2 = <PlayerEvent>[];

      controller
        ..addEventsListener(list1.add)
        ..addEventsListener(list2.add)
        ..postEvent(
          PlayerEvent(
            PlayerEventType.setVolume,
            parameters: {'volume': 0.8},
          ),
        );

      expect(list1.length, 1);
      expect(list2.length, 1);
      expect(list1.first.parameters?['volume'], 0.8);
      expect(list2.first.parameters?['volume'], 0.8);

      controller.dispose();
    });

    test('listener can safely remove itself during iteration', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      var callCount = 0;

      void selfRemovingListener(PlayerEvent event) {
        callCount++;
        controller.removeEventsListener(selfRemovingListener);
      }

      controller.addEventsListener(selfRemovingListener);
      controller.postEvent(PlayerEvent(PlayerEventType.play));
      controller.postEvent(PlayerEvent(PlayerEventType.pause));

      expect(callCount, 1);
      controller.dispose();
    });
  });
}
