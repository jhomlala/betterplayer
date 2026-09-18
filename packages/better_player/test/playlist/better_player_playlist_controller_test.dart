import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';

void main() {
  test('changedPlaylistItem event is dispatched on setupDataSource', () async {
    BetterPlayerTestUtils.setupMockPlatform();

    final dataSourceList = [
      PlayerDataSource.network('https://example.com/video1.mp4'),
      PlayerDataSource.network('https://example.com/video2.mp4'),
    ];

    final playlistController = BetterPlayerPlaylistController(dataSourceList);

    final events = <PlayerEvent>[];
    playlistController.betterPlayerController?.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.changedPlaylistItem) {
        events.add(event);
      }
    });

    // Manually trigger a change to the next data source
    playlistController.setupDataSource(1);

    expect(events.isNotEmpty, isTrue);
    expect(
      events.last.betterPlayerEventType,
      PlayerEventType.changedPlaylistItem,
    );
  });
}
