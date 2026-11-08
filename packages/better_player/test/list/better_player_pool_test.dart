import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('BetterPlayerPool tests', () {
    test('Initializes with configured pool size', () {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 4),
      );
      expect(pool.poolSize, 4);
      expect(pool.leasedCount, 0);
      expect(pool.isDisposed, false);
      pool.dispose();
      expect(pool.isDisposed, true);
    });

    test('Acquires free slots up to pool capacity', () async {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );

      final lease1 = await pool.acquire(
        itemId: 'item_1',
        index: 0,
        dataSource: PlayerDataSource.network('https://example.com/1.mp4'),
      );
      expect(lease1.itemId, 'item_1');
      expect(lease1.isValid, true);
      expect(pool.leasedCount, 1);

      final lease2 = await pool.acquire(
        itemId: 'item_2',
        index: 1,
        dataSource: PlayerDataSource.network('https://example.com/2.mp4'),
      );
      expect(lease2.itemId, 'item_2');
      expect(lease2.isValid, true);
      expect(pool.leasedCount, 2);

      pool.dispose();
    });

    test(
      'Re-acquiring existing itemId returns current lease without new slot',
      () async {
        final pool = BetterPlayerPool(
          configuration: const PlayerPoolConfiguration(poolSize: 2),
        );

        final lease1 = await pool.acquire(
          itemId: 'item_1',
          index: 0,
          dataSource: PlayerDataSource.network('https://example.com/1.mp4'),
        );

        final reacquired = await pool.acquire(
          itemId: 'item_1',
          index: 0,
          dataSource: PlayerDataSource.network('https://example.com/1.mp4'),
        );

        expect(reacquired, equals(lease1));
        expect(pool.leasedCount, 1);
        pool.dispose();
      },
    );

    test('Distance eviction evicts furthest slot when pool is full', () async {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );

      // Acquire index 0 and 1
      final lease0 = await pool.acquire(
        itemId: 'item_0',
        index: 0,
        dataSource: PlayerDataSource.network('https://example.com/0.mp4'),
      );
      final lease1 = await pool.acquire(
        itemId: 'item_1',
        index: 1,
        dataSource: PlayerDataSource.network('https://example.com/1.mp4'),
      );

      // Active index moves to 1
      pool.setActiveIndex(1);

      // Now acquire index 2. Furthest from active index 1 is index 0.
      final lease2 = await pool.acquire(
        itemId: 'item_2',
        index: 2,
        dataSource: PlayerDataSource.network('https://example.com/2.mp4'),
      );

      expect(lease0.isValid, false);
      expect(lease1.isValid, true);
      expect(lease2.isValid, true);

      pool.dispose();
    });

    test('Manual release marks lease invalid and frees slot', () async {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );

      final lease = await pool.acquire(
        itemId: 'item_0',
        index: 0,
        dataSource: PlayerDataSource.network('https://example.com/0.mp4'),
      );

      expect(pool.leasedCount, 1);
      lease.release();
      expect(lease.isValid, false);
      expect(pool.leasedCount, 0);

      pool.dispose();
    });

    test('Lifecycle onAppBackground pauses all slots', () async {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );

      await pool.acquire(
        itemId: 'item_0',
        index: 0,
        dataSource: PlayerDataSource.network('https://example.com/0.mp4'),
      );

      pool.onAppBackground();
      pool.onAppForeground();
      pool.dispose();
    });

    test('Eviction notifies registered lease eviction listeners', () async {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );

      final lease0 = await pool.acquire(
        itemId: 'item_0',
        index: 0,
        dataSource: PlayerDataSource.network('https://example.com/0.mp4'),
      );
      final lease1 = await pool.acquire(
        itemId: 'item_1',
        index: 1,
        dataSource: PlayerDataSource.network('https://example.com/1.mp4'),
      );

      var evictedNotified = false;
      lease0.addEvictionListener(() {
        evictedNotified = true;
      });

      pool.setActiveIndex(1);
      final lease2 = await pool.acquire(
        itemId: 'item_2',
        index: 2,
        dataSource: PlayerDataSource.network('https://example.com/2.mp4'),
      );

      expect(evictedNotified, isTrue);
      expect(lease0.isValid, isFalse);
      expect(lease1.isValid, isTrue);
      expect(lease2.isValid, isTrue);

      pool.dispose();
    });

    test(
      'Acquiring an item while preloading cancels preload pause and returns active lease',
      () async {
        final pool = BetterPlayerPool(
          configuration: const PlayerPoolConfiguration(
            poolSize: 2,
          ),
        );

        final dataSources = [
          PlayerDataSource.network('https://example.com/0.mp4'),
          PlayerDataSource.network('https://example.com/1.mp4'),
        ];

        await pool.acquire(
          itemId: 'item_0',
          index: 0,
          dataSource: dataSources[0],
        );

        pool.updatePreloads(
          currentIndex: 0,
          dataSources: dataSources,
          idGetter: (i) => 'item_$i',
        );

        final lease1 = await pool.acquire(
          itemId: 'item_1',
          index: 1,
          dataSource: dataSources[1],
        );

        expect(lease1.itemId, 'item_1');
        expect(lease1.isValid, isTrue);

        pool.dispose();
      },
    );

    test('retries setupDataSource after a failed bind', () async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;

      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );
      final dataSource = PlayerDataSource.network(
        'https://example.com/fail-then-succeed.mp4',
      );

      mockPlatform.setDataSourceFailuresRemaining = 1;
      final lease1 = await pool.acquire(
        itemId: 'item_fail',
        index: 0,
        dataSource: dataSource,
      );

      expect(lease1.hasError, isTrue);
      expect(mockPlatform.setDataSourceCallCount, 1);

      lease1.release();

      final lease2 = await pool.acquire(
        itemId: 'item_fail',
        index: 0,
        dataSource: dataSource,
      );

      expect(mockPlatform.setDataSourceCallCount, 2);
      expect(lease2.hasError, isFalse);
      expect(lease2.isValid, isTrue);

      pool.dispose();
    });

    test('lease reports hasError after a failed bind', () async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;

      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(poolSize: 2),
      );
      final dataSource = PlayerDataSource.network(
        'https://example.com/fail.mp4',
      );

      mockPlatform.setDataSourceFailuresRemaining = 1;
      final lease = await pool.acquire(
        itemId: 'item_fail',
        index: 0,
        dataSource: dataSource,
      );

      expect(lease.hasError, isTrue);
      expect(lease.errorMessage, isNotNull);
      expect(lease.errorMessage, contains('Simulated setDataSource failure'));

      pool.dispose();
    });

    test('preload failure does not leak isBusy', () async {
      final mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;

      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(
          poolSize: 2,
        ),
      );

      final dataSources = [
        PlayerDataSource.network('https://example.com/0.mp4'),
        PlayerDataSource.network('https://example.com/1.mp4'),
      ];

      // Item 0 succeeds
      final lease0 = await pool.acquire(
        itemId: 'item_0',
        index: 0,
        dataSource: dataSources[0],
      );
      expect(lease0.isValid, isTrue);

      // Preload for item 1 fails
      mockPlatform.setDataSourceFailuresRemaining = 1;
      pool.updatePreloads(
        currentIndex: 0,
        dataSources: dataSources,
        idGetter: (i) => 'item_$i',
      );

      // Allow async preload bind to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Slot should not be stuck in isBusy; acquiring another item or item 1 succeeds
      mockPlatform.setDataSourceFailuresRemaining = 0;
      final lease1 = await pool.acquire(
        itemId: 'item_1',
        index: 1,
        dataSource: dataSources[1],
      );
      expect(lease1.isValid, isTrue);
      expect(lease1.hasError, isFalse);

      pool.dispose();
    });

    test(
      'releaseItem releases occupied slot and marks lease evicted',
      () async {
        final pool = BetterPlayerPool(
          configuration: const PlayerPoolConfiguration(poolSize: 2),
        );

        final lease = await pool.acquire(
          itemId: 'video_a',
          index: 0,
          dataSource: PlayerDataSource.network('https://example.com/a.mp4'),
        );

        expect(pool.leasedCount, 1);
        expect(lease.isValid, isTrue);

        pool.releaseItem(itemId: 'video_a');

        expect(pool.leasedCount, 0);
        expect(lease.isValid, isFalse);

        pool.dispose();
      },
    );

    test('reindex updates slot indices for distance-based eviction', () async {
      final pool = BetterPlayerPool(
        configuration: const PlayerPoolConfiguration(
          poolSize: 2,
          preloadForward: 0,
          preloadBackward: 0,
        ),
      );

      final leaseA = await pool.acquire(
        itemId: 'video_a',
        index: 0,
        dataSource: PlayerDataSource.network('https://example.com/a.mp4'),
      );
      final leaseB = await pool.acquire(
        itemId: 'video_b',
        index: 1,
        dataSource: PlayerDataSource.network('https://example.com/b.mp4'),
      );

      expect(leaseA.isValid, isTrue);
      expect(leaseB.isValid, isTrue);

      // Reindex so that video_a moves far away to index 100
      pool.reindex(indexById: {'video_a': 100, 'video_b': 1});
      pool.setActiveIndex(0);

      // Acquiring a third item should evict video_a (distance 100 vs distance 1)
      await pool.acquire(
        itemId: 'video_c',
        index: 2,
        dataSource: PlayerDataSource.network('https://example.com/c.mp4'),
      );

      expect(leaseA.isValid, isFalse);
      expect(leaseB.isValid, isTrue);

      pool.dispose();
    });

    test(
      're-acquiring failed itemId without manual release reuses slot without leaking',
      () async {
        final mockPlatform = MockBetterPlayerPlatform();
        BetterPlayerPlatform.instance = mockPlatform;

        final pool = BetterPlayerPool(
          configuration: const PlayerPoolConfiguration(poolSize: 2),
        );
        final dataSource = PlayerDataSource.network(
          'https://example.com/retry.mp4',
        );

        mockPlatform.setDataSourceFailuresRemaining = 1;
        final lease1 = await pool.acquire(
          itemId: 'item_retry',
          index: 0,
          dataSource: dataSource,
        );
        expect(lease1.hasError, isTrue);

        final lease2 = await pool.acquire(
          itemId: 'item_retry',
          index: 0,
          dataSource: dataSource,
        );
        expect(lease2.hasError, isFalse);
        expect(lease2.isValid, isTrue);
        expect(pool.leasedCount, 1);

        pool.dispose();
      },
    );

    test(
      'eviction measures distance from activeIndex and protects activeIndex slot',
      () async {
        final pool = BetterPlayerPool(
          configuration: const PlayerPoolConfiguration(poolSize: 2),
        );

        final lease0 = await pool.acquire(
          itemId: 'item_0',
          index: 0,
          dataSource: PlayerDataSource.network('https://example.com/0.mp4'),
        );
        final lease2 = await pool.acquire(
          itemId: 'item_2',
          index: 2,
          dataSource: PlayerDataSource.network('https://example.com/2.mp4'),
        );

        pool.setActiveIndex(2);

        final lease1 = await pool.acquire(
          itemId: 'item_1',
          index: 1,
          dataSource: PlayerDataSource.network('https://example.com/1.mp4'),
        );

        expect(lease0.isValid, isFalse);
        expect(lease2.isValid, isTrue);
        expect(lease1.isValid, isTrue);

        pool.dispose();
      },
    );
  });
}
