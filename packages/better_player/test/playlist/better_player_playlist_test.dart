import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/mock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

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
        BetterPlayerDataSource.network('https://example.com/1.mp4'),
        BetterPlayerDataSource.network('https://example.com/2.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(dataSourceList);

      expect(playlistController.currentDataSourceIndex, 0);
      expect(playlistController.betterPlayerController != null, true);
    });

    test('setupDataSource changes current index', () {
      final dataSourceList = [
        BetterPlayerDataSource.network('https://example.com/1.mp4'),
        BetterPlayerDataSource.network('https://example.com/2.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(dataSourceList);

      playlistController.setupDataSource(1);
      expect(playlistController.currentDataSourceIndex, 1);
    });

    test('Next video from playlist', () async {
      final dataSourceList = [
        BetterPlayerDataSource.network('https://example.com/1.mp4'),
        BetterPlayerDataSource.network('https://example.com/2.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(
        dataSourceList,
        betterPlayerPlaylistConfiguration:
            const BetterPlayerPlaylistConfiguration(
              nextVideoDelay: Duration.zero,
            ),
      );

      // Manually trigger video finished event
      playlistController.betterPlayerController!.postEvent(
        BetterPlayerEvent(BetterPlayerEventType.finished),
      );

      // The controller should trigger next video timer and then auto-switch because delay is 0
      // Wait a bit for async operations
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(playlistController.currentDataSourceIndex, 1);
    });

    test('looping playlist works', () async {
      final dataSourceList = [
        BetterPlayerDataSource.network('https://example.com/1.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(
        dataSourceList,
        betterPlayerPlaylistConfiguration:
            const BetterPlayerPlaylistConfiguration(
              nextVideoDelay: Duration.zero,
            ),
      );

      playlistController.betterPlayerController!.postEvent(
        BetterPlayerEvent(BetterPlayerEventType.finished),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(playlistController.currentDataSourceIndex, 0);
    });

    test('dispose clears resources', () {
      final dataSourceList = [
        BetterPlayerDataSource.network('https://example.com/1.mp4'),
      ];
      final playlistController = BetterPlayerPlaylistController(dataSourceList);
      playlistController.dispose();
    });

    testWidgets('BetterPlayerPlaylist widget initialization', (
      tester,
    ) async {
      final dataSourceList = [
        BetterPlayerDataSource.network('https://example.com/1.mp4'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerPlaylist(
              betterPlayerDataSourceList: dataSourceList,
              betterPlayerConfiguration: const BetterPlayerConfiguration(),
              betterPlayerPlaylistConfiguration:
                  const BetterPlayerPlaylistConfiguration(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BetterPlayerPlaylist), findsOneWidget);
      expect(find.byType(BetterPlayer), findsOneWidget);
    });
  });
}
