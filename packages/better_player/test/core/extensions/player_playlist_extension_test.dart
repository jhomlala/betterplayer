import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerPlaylistExtension', () {
    test(
      'startNextVideoTimer throws StateError when playlist config is null',
      () {
        final controller = BetterPlayerController(const PlayerConfiguration());

        expect(controller.startNextVideoTimer, throwsStateError);

        controller.dispose();
      },
    );

    test('startNextVideoTimer with zero delay emits 0 and finishes', () async {
      final controller = BetterPlayerController(
        const PlayerConfiguration(),
        betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
          nextVideoDelay: Duration.zero,
        ),
      );

      final emissions = <int?>[];
      final subscription = controller.nextVideoTimeStream.listen(emissions.add);

      controller.startNextVideoTimer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, [0]);

      await subscription.cancel();
      controller.dispose();
    });

    test('cancelNextVideoTimer clears timer and emits null', () async {
      final controller = BetterPlayerController(
        const PlayerConfiguration(),
        betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
          nextVideoDelay: Duration(seconds: 10),
        ),
      );

      final emissions = <int?>[];
      final subscription = controller.nextVideoTimeStream.listen(emissions.add);

      controller.startNextVideoTimer();
      controller.cancelNextVideoTimer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, [10, null]);

      await subscription.cancel();
      controller.dispose();
    });

    test('playNextVideo sets nextVideoTime to 0 and cancels timer', () async {
      final controller = BetterPlayerController(
        const PlayerConfiguration(),
        betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
          nextVideoDelay: Duration(seconds: 5),
        ),
      );

      final emissions = <int?>[];
      final subscription = controller.nextVideoTimeStream.listen(emissions.add);

      controller.playNextVideo();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, [0, null]);

      await subscription.cancel();
      controller.dispose();
    });

    test(
      'playPreviousVideo sets nextVideoTime to -1 and cancels timer',
      () async {
        final controller = BetterPlayerController(
          const PlayerConfiguration(),
          betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
            nextVideoDelay: Duration(seconds: 5),
          ),
        );

        final emissions = <int?>[];
        final subscription = controller.nextVideoTimeStream.listen(
          emissions.add,
        );

        controller.playPreviousVideo();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emissions, [-1, null]);

        await subscription.cancel();
        controller.dispose();
      },
    );
  });
}
