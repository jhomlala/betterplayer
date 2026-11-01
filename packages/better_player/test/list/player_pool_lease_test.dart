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

  group('PlayerPoolLease tests', () {
    test('Initializes with valid state and properties', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      var releaseCount = 0;
      final lease = PlayerPoolLease(
        itemId: 'item_1',
        controller: controller,
        index: 0,
        onRelease: (_) => releaseCount++,
      );

      expect(lease.itemId, 'item_1');
      expect(lease.index, 0);
      expect(lease.controller, equals(controller));
      expect(lease.isValid, isTrue);
      expect(releaseCount, 0);

      controller.dispose();
    });

    test('Release marks lease invalid and calls onRelease exactly once', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      var releaseCount = 0;
      final lease = PlayerPoolLease(
        itemId: 'item_1',
        controller: controller,
        index: 0,
        onRelease: (_) => releaseCount++,
      );

      lease.release();
      expect(lease.isValid, isFalse);
      expect(releaseCount, 1);

      // Idempotent: second release does nothing
      lease.release();
      expect(releaseCount, 1);

      controller.dispose();
    });

    test(
      'markEvicted marks lease invalid and fires all eviction listeners',
      () {
        final controller = BetterPlayerController(const PlayerConfiguration());
        var releaseCount = 0;
        final lease = PlayerPoolLease(
          itemId: 'item_1',
          controller: controller,
          index: 0,
          onRelease: (_) => releaseCount++,
        );

        var listener1Called = false;
        var listener2Called = false;

        lease
          ..addEvictionListener(() => listener1Called = true)
          ..addEvictionListener(() => listener2Called = true);

        lease.markEvicted();

        expect(lease.isValid, isFalse);
        expect(listener1Called, isTrue);
        expect(listener2Called, isTrue);
        // Eviction does not trigger client-initiated onRelease
        expect(releaseCount, 0);

        // Idempotent eviction does not re-trigger
        listener1Called = false;
        lease.markEvicted();
        expect(listener1Called, isFalse);

        controller.dispose();
      },
    );

    test('removeEvictionListener removes listener successfully', () {
      final controller = BetterPlayerController(const PlayerConfiguration());
      final lease = PlayerPoolLease(
        itemId: 'item_1',
        controller: controller,
        index: 0,
        onRelease: (_) {},
      );

      var listenerCalled = false;
      void listener() => listenerCalled = true;

      lease.addEvictionListener(listener);
      lease.removeEvictionListener(listener);

      lease.markEvicted();
      expect(listenerCalled, isFalse);

      controller.dispose();
    });
  });
}
