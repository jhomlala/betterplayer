import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  setUpAll(() {
    BetterPlayerTestUtils.setupMockPlatform();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(
    () => {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            mockMethodChannel.channel,
            mockMethodChannel.handle,
          ),
    },
  );

  group('BetterPlayerPlaylistController tests', () {
    test('Initialization with data sources', () {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
        PlayerDataSource.network('https://example.com/2.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(dataSourceList);

      expect(playlistController.currentDataSourceIndex, 0);
      expect(playlistController.betterPlayerController != null, true);
    });

    test('setupDataSource changes current index', () {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
        PlayerDataSource.network('https://example.com/2.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(dataSourceList);

      playlistController.setupDataSource(1);
      expect(playlistController.currentDataSourceIndex, 1);
    });

    test('Next video from playlist', () async {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
        PlayerDataSource.network('https://example.com/2.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(
        dataSourceList,
        betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
          nextVideoDelay: Duration.zero,
        ),
      );

      // Manually trigger video finished event
      playlistController.betterPlayerController!.postEvent(
        PlayerEvent(PlayerEventType.finished),
      );

      // The controller should trigger next video timer and then auto-switch because delay is 0
      // Wait a bit for async operations
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(playlistController.currentDataSourceIndex, 1);
    });

    test('looping playlist works', () async {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(
        dataSourceList,
        betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
          nextVideoDelay: Duration.zero,
        ),
      );

      playlistController.betterPlayerController!.postEvent(
        PlayerEvent(PlayerEventType.finished),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(playlistController.currentDataSourceIndex, 0);
    });

    test('dispose clears resources', () {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(dataSourceList);
      playlistController.dispose();
    });

    test(
      'playNextVideo, playPreviousVideo, and setupDataSourceList work cleanly',
      () {
        final playlistController = BetterPlayerPlaylistController([
          PlayerDataSource.network('https://example.com/1.mp4'),
          PlayerDataSource.network('https://example.com/2.mp4'),
        ]);

        playlistController.playNextVideo();
        expect(playlistController.currentDataSourceIndex, 1);

        playlistController.playPreviousVideo();
        expect(playlistController.currentDataSourceIndex, 0);

        playlistController.playNextVideo();
        expect(playlistController.currentDataSourceIndex, 1);

        playlistController.setupDataSourceList([
          PlayerDataSource.network('https://example.com/3.mp4'),
          PlayerDataSource.network('https://example.com/4.mp4'),
        ]);
        expect(playlistController.currentDataSourceIndex, 0);
        playlistController.dispose();
      },
    );

    test(
      'disposing BetterPlayerController mid-setupDataSource does not throw',
      () async {
        final controller = BetterPlayerController(const PlayerConfiguration());
        final future = controller.setupDataSource(
          PlayerDataSource.network('https://example.com/1.mp4'),
        );
        controller.dispose(forceDispose: true);
        await expectLater(future, completes);
      },
    );

    testWidgets('BetterPlayerPlaylist widget initialization', (
      tester,
    ) async {
      final dataSourceList = [
        PlayerDataSource.network('https://example.com/1.mp4'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: BetterPlayerPlaylist(
              betterPlayerDataSourceList: dataSourceList,
              betterPlayerConfiguration: const PlayerConfiguration(),
              betterPlayerPlaylistConfiguration:
                  const PlayerPlaylistConfiguration(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BetterPlayerPlaylist), findsOneWidget);
      expect(find.byType(BetterPlayer), findsOneWidget);
    });
  });
}
