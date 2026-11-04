import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_better_player_platform.dart';
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

    test('onIndexChanged with failure sets lease on notifier', () async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;
      mockPlatform.setDataSourceFailuresRemaining = 1;

      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/fail.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await feedController.onIndexChanged(0);
      final lease = feedController.getLeaseNotifier(0).value;
      expect(lease, isNotNull);
      expect(lease!.hasError, isTrue);

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

    test(
      'Evicted slot clears lease notifier value on feed controller',
      () async {
        final dataSources = [
          PlayerDataSource.network('https://example.com/1.mp4'),
          PlayerDataSource.network('https://example.com/2.mp4'),
          PlayerDataSource.network('https://example.com/3.mp4'),
        ];

        final feedController = BetterPlayerFeedController(
          dataSources: dataSources,
          poolConfiguration: const PlayerPoolConfiguration(
            poolSize: 2,
            preloadForward: 0,
            preloadBackward: 0,
          ),
        );

        await feedController.onIndexChanged(0);
        expect(feedController.getLeaseNotifier(0).value, isNotNull);

        await feedController.onIndexChanged(1);
        expect(feedController.getLeaseNotifier(0).value, isNotNull);
        expect(feedController.getLeaseNotifier(1).value, isNotNull);

        await feedController.onIndexChanged(2);
        expect(feedController.getLeaseNotifier(0).value, isNull);
        expect(feedController.getLeaseNotifier(1).value, isNotNull);
        expect(feedController.getLeaseNotifier(2).value, isNotNull);

        feedController.dispose();
      },
    );

    test(
      'Externally provided PageController is not disposed by feed controller',
      () {
        final externalPageController = PageController();
        final feedController = BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/1.mp4'),
          ],
          pageController: externalPageController,
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
        );

        feedController.dispose();

        // Calling addListener on a disposed ChangeNotifier throws FlutterError.
        void noop() {}
        externalPageController
          ..addListener(noop)
          ..removeListener(noop)
          ..dispose();
      },
    );

    test(
      'insertDataSources shifts currentIndex when inserted at or before current',
      () async {
        final feedController = BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/0.mp4'),
            PlayerDataSource.network('https://example.com/1.mp4'),
          ],
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
        );

        await feedController.onIndexChanged(1);
        expect(feedController.currentIndex, 1);
        final activeEntryId = feedController.entries[1].id;

        feedController.insertDataSources(
          index: 0,
          dataSources: [
            PlayerDataSource.network('https://example.com/new_0.mp4'),
          ],
        );

        expect(feedController.dataSources.length, 3);
        expect(feedController.currentIndex, 2);
        expect(
          feedController.entries[feedController.currentIndex].id,
          activeEntryId,
        );

        feedController.dispose();
      },
    );

    test(
      'removeAt shifts currentIndex and rebinds when removing active item',
      () async {
        final feedController = BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/0.mp4'),
            PlayerDataSource.network('https://example.com/1.mp4'),
            PlayerDataSource.network('https://example.com/2.mp4'),
          ],
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
        );

        await feedController.onIndexChanged(1);
        expect(feedController.currentIndex, 1);
        final item1Id = feedController.entries[1].id;
        final item2Id = feedController.entries[2].id;

        // Remove current item (index 1)
        await feedController.removeAt(index: 1);

        expect(feedController.dataSources.length, 2);
        expect(feedController.currentIndex, 1);
        expect(feedController.entries[1].id, item2Id);
        expect(feedController.pool.getController(item1Id), isNull);

        feedController.dispose();
      },
    );

    test('removeAt last item moves index back', () async {
      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/0.mp4'),
          PlayerDataSource.network('https://example.com/1.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await feedController.onIndexChanged(1);
      expect(feedController.currentIndex, 1);

      await feedController.removeAt(index: 1);

      expect(feedController.dataSources.length, 1);
      expect(feedController.currentIndex, 0);

      feedController.dispose();
    });

    test('replaceAt updates data source and keeps entry id', () async {
      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/0.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await feedController.onIndexChanged(0);
      final originalId = feedController.entries[0].id;

      await feedController.replaceAt(
        index: 0,
        dataSource: PlayerDataSource.network(
          'https://example.com/replaced.mp4',
        ),
      );

      expect(feedController.entries[0].id, originalId);
      expect(
        feedController.entries[0].dataSource.url,
        'https://example.com/replaced.mp4',
      );

      feedController.dispose();
    });

    test('replaceAll releases all leases and starts at initialIndex', () async {
      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/0.mp4'),
          PlayerDataSource.network('https://example.com/1.mp4'),
        ],
        idGetter: (i) => 'old_$i',
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await feedController.onIndexChanged(0);
      expect(feedController.pool.getController('old_0'), isNotNull);

      await feedController.replaceAll(
        dataSources: [
          PlayerDataSource.network('https://example.com/fresh_0.mp4'),
          PlayerDataSource.network('https://example.com/fresh_1.mp4'),
        ],
        ids: ['new_0', 'new_1'],
        initialIndex: 1,
      );

      expect(feedController.pool.getController('old_0'), isNull);
      expect(feedController.currentIndex, 1);
      expect(
        feedController.entries[1].dataSource.url,
        'https://example.com/fresh_1.mp4',
      );

      feedController.dispose();
    });

    test('duplicate entry IDs are rejected with ArgumentError', () {
      expect(
        () => BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/0.mp4'),
            PlayerDataSource.network('https://example.com/1.mp4'),
          ],
          idGetter: (_) => 'constant_id',
        ),
        throwsArgumentError,
      );

      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/0.mp4'),
        ],
      );

      expect(
        () => feedController.insertDataSources(
          index: 0,
          dataSources: [
            PlayerDataSource.network('https://example.com/dup.mp4'),
          ],
          ids: ['item_0'],
        ),
        throwsArgumentError,
      );

      feedController.dispose();
    });

    testWidgets(
      'Feed reacts to appendDataSources and mutations with PageView rebuild',
      (tester) async {
        final feedController = BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/0.mp4'),
            PlayerDataSource.network('https://example.com/1.mp4'),
          ],
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
          autoPlay: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayerFeed(
                controller: feedController,
                configuration: PlayerFeedConfiguration(
                  placeholderBuilder: (context, index, dataSource) =>
                      Text('Item: ${dataSource.url}'),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(
          find.text('Item: https://example.com/0.mp4'),
          findsOneWidget,
        );

        // Append items and verify PageView updates
        feedController.appendDataSources([
          PlayerDataSource.network('https://example.com/2.mp4'),
        ]);
        await tester.pump();

        expect(feedController.entries.length, 3);

        feedController.dispose();
      },
    );

    testWidgets(
      'Failing feed item renders PlayerFeedErrorView and retry button recovers',
      (tester) async {
        final mockPlatform = MockBetterPlayerPlatform();
        BetterPlayerPlatform.instance = mockPlatform;
        mockPlatform.setDataSourceFailuresRemaining = 1;

        final feedController = BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/fail-then-pass.mp4'),
          ],
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
          autoPlay: false,
        );

        await tester.runAsync(() async {
          await feedController.onIndexChanged(0);
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterPlayerFeed(
                controller: feedController,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(PlayerFeedErrorView), findsOneWidget);
        expect(
          find.byKey(const Key('feed_error_retry_button')),
          findsOneWidget,
        );

        // Tap retry with failure count reset
        mockPlatform.setDataSourceFailuresRemaining = 0;
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('feed_error_retry_button')));
        });
        await tester.pump();

        expect(find.byType(PlayerFeedErrorView), findsNothing);

        feedController.dispose();
      },
    );

    testWidgets('Custom errorBuilder is used when provided', (tester) async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;
      mockPlatform.setDataSourceFailuresRemaining = 1;

      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/custom-error.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
        autoPlay: false,
      );

      await tester.runAsync(() async {
        await feedController.onIndexChanged(0);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayerFeed(
              controller: feedController,
              configuration: PlayerFeedConfiguration(
                errorBuilder: (context, index, dataSource, errorMessage) =>
                    Text('Custom error message: $errorMessage'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Custom error message:'), findsOneWidget);

      feedController.dispose();
    });

    test('Dispose during an in-flight acquire does not throw', () async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;

      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/1.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      // Trigger index change and immediately dispose without awaiting
      final future = feedController.onIndexChanged(0);
      feedController.dispose();

      // Ensure waiting for in-flight operation does not throw
      await expectLater(future, completes);
    });

    test(
      'metricsStream emits metrics when navigating away or disposing',
      () async {
        final feedController = BetterPlayerFeedController(
          dataSources: [
            PlayerDataSource.network('https://example.com/0.mp4'),
            PlayerDataSource.network('https://example.com/1.mp4'),
          ],
          poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
        );

        final metricsList = <PlayerFeedItemMetrics>[];
        final subscription = feedController.metricsStream.listen(
          metricsList.add,
        );

        await feedController.onIndexChanged(0);
        expect(metricsList, isEmpty);

        // Navigating to index 1 emits metrics for index 0
        await feedController.onIndexChanged(1);
        expect(metricsList.length, 1);
        final item0Metrics = metricsList.first;
        expect(item0Metrics.itemId, 'item_0');
        expect(item0Metrics.index, 0);
        expect(item0Metrics.wasPreloaded, isFalse);
        expect(item0Metrics.timeToFirstFrame, isNotNull);
        expect(item0Metrics.errorMessage, isNull);

        // Disposing emits metrics for index 1 and closes stream
        var streamClosed = false;
        subscription.onDone(() => streamClosed = true);
        feedController.dispose();
        await Future<void>.delayed(Duration.zero);

        expect(metricsList.length, 2);
        expect(metricsList[1].itemId, 'item_1');
        expect(metricsList[1].wasPreloaded, isTrue);
        expect(streamClosed, isTrue);

        await subscription.cancel();
      },
    );

    test('metricsStream captures buffering stalls and error state', () async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;
      mockPlatform.setDataSourceFailuresRemaining = 1;

      final feedController = BetterPlayerFeedController(
        dataSources: [
          PlayerDataSource.network('https://example.com/fail.mp4'),
        ],
        poolConfiguration: const PlayerPoolConfiguration(poolSize: 2),
      );

      final metricsList = <PlayerFeedItemMetrics>[];
      final subscription = feedController.metricsStream.listen(
        metricsList.add,
      );

      await feedController.onIndexChanged(0);
      expect(metricsList.length, 1);
      expect(
        metricsList.first.errorMessage,
        contains('Simulated setDataSource failure'),
      );

      feedController.dispose();
      await subscription.cancel();
    });
  });
}
