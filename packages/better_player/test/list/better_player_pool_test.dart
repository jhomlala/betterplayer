import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
