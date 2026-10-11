import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMethodChannel = MockMethodChannel();

  setUpAll(BetterPlayerTestUtils.setupMockPlatform);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          mockMethodChannel.channel,
          mockMethodChannel.handle,
        );
  });

  group('BetterPlayerFeed widget tests', () {
    testWidgets('Renders PageView and items correctly', (tester) async {
      final dataSources = [
        PlayerDataSource.network('https://example.com/1.mp4'),
        PlayerDataSource.network('https://example.com/2.mp4'),
      ];

      final feedController = BetterPlayerFeedController(
        dataSources: dataSources,
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerFeed(
              controller: feedController,
              configuration: PlayerFeedConfiguration(
                placeholderBuilder: (context, index, dataSource) =>
                    Text('Placeholder $index'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BetterPlayerFeed), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Placeholder 0'), findsOneWidget);

      feedController.dispose();
    });

    test(
      'onIndexChanged updates currentIndex and notifies listeners',
      () async {
        final dataSources = [
          PlayerDataSource.network('https://example.com/1.mp4'),
          PlayerDataSource.network('https://example.com/2.mp4'),
        ];

        final feedController = BetterPlayerFeedController(
          dataSources: dataSources,
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
        );

        expect(feedController.currentIndex, 0);

        await feedController.onIndexChanged(1);
        expect(feedController.currentIndex, 1);

        feedController.dispose();
      },
    );

    test('onIndexChanged pauses previous index controller', () async {
      final dataSources = [
        PlayerDataSource.network('https://example.com/1.mp4'),
        PlayerDataSource.network('https://example.com/2.mp4'),
      ];

      final feedController = BetterPlayerFeedController(
        dataSources: dataSources,
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await feedController.onIndexChanged(0);
      final lease0 = feedController.getLeaseNotifier(0).value;
      expect(lease0, isNotNull);

      await feedController.onIndexChanged(1);
      final lease1 = feedController.getLeaseNotifier(1).value;
      expect(lease1, isNotNull);
      expect(lease0!.controller.isPlaying(), false);

      feedController.dispose();
    });

    test('appendDataSources increases data source count and notifiers', () {
      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/1.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      expect(feedController.dataSources.length, 1);

      feedController.appendDataSources([
        PlayerDataSource.network('https://example.com/2.mp4'),
        PlayerDataSource.network('https://example.com/3.mp4'),
      ]);

      expect(feedController.dataSources.length, 3);
      expect(feedController.getLeaseNotifier(2), isNotNull);

      feedController.dispose();
    });

    test('Custom idGetter assigns custom identifiers', () async {
      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/1.mp4'),
        ],
        idGetter: (index) => 'custom_video_$index',
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await feedController.onIndexChanged(0);
      final lease = feedController.getLeaseNotifier(0).value;
      expect(lease?.itemId, 'custom_video_0');

      feedController.dispose();
    });
  });
}
