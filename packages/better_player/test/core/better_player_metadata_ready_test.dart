import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/better_player_mock_controller.dart';
import '../helpers/better_player_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(BetterPlayerTestUtils.setupMockPlatform);

  group('BetterPlayerController metadataReady tests', () {
    test('metadataReady is fired when data source is set', () async {
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
      );

      var metadataReadyFired = false;
      PlayerEvent? receivedEvent;

      controller.addEventsListener((event) {
        if (event.betterPlayerEventType == PlayerEventType.metadataReady) {
          metadataReadyFired = true;
          receivedEvent = event;
        }
      });

      await controller.setupDataSource(
        PlayerDataSource.network(BetterPlayerTestUtils.forBiggerBlazesUrl),
      );

      expect(metadataReadyFired, isTrue);
      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.parameters, isNotNull);
      expect(
        receivedEvent!.parameters![PlayerEventConstants.asmsTracksParameter],
        isNotNull,
      );
      expect(
        receivedEvent!.parameters![PlayerEventConstants
            .asmsAudioTracksParameter],
        isNotNull,
      );
      expect(
        receivedEvent!.parameters![PlayerEventConstants.subtitlesParameter],
        isNotNull,
      );
    });
  });
}
