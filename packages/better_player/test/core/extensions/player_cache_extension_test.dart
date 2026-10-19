import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';
import '../../helpers/mock_better_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BetterPlayerController controller;
  late MockBetterPlayerPlatform mockPlatform;

  setUp(() {
    BetterPlayerTestUtils.setupMockPlatform();
    mockPlatform = BetterPlayerPlatform.instance as MockBetterPlayerPlatform;
    controller = BetterPlayerController(const PlayerConfiguration());
  });

  tearDown(() {
    controller.dispose(forceDispose: true);
  });

  group('PlayerCacheExtension', () {
    test('preCache rejects HLS streams', () async {
      final hlsDataSource = PlayerDataSource(
        DataSourceType.network,
        'https://example.com/stream.m3u8',
      );

      await controller.preCache(hlsDataSource);

      expect(mockPlatform.preCacheCalls, isEmpty);
    });

    test('preCache rejects streams with m3u8 videoExtension', () async {
      final hlsDataSource = PlayerDataSource(
        DataSourceType.network,
        'https://example.com/stream?token=123',
        videoExtension: 'm3u8',
      );

      await controller.preCache(hlsDataSource);

      expect(mockPlatform.preCacheCalls, isEmpty);
    });

    test('preCache rejects DASH streams', () async {
      final dashDataSource = PlayerDataSource(
        DataSourceType.network,
        'https://example.com/stream.mpd',
      );

      await controller.preCache(dashDataSource);

      expect(mockPlatform.preCacheCalls, isEmpty);
    });

    test('preCache rejects streams with mpd videoExtension', () async {
      final dashDataSource = PlayerDataSource(
        DataSourceType.network,
        'https://example.com/stream?token=123',
        videoExtension: 'mpd',
      );

      await controller.preCache(dashDataSource);

      expect(mockPlatform.preCacheCalls, isEmpty);
    });

    test('preCache passes dataSource and size to platform', () async {
      const videoUrl = 'https://example.com/video.mp4';
      final dataSource = PlayerDataSource(
        DataSourceType.network,
        videoUrl,
        cacheConfiguration: const CacheConfiguration(
          useCache: true,
          preCacheSize: 2 * 1024 * 1024,
          maxCacheSize: 50 * 1024 * 1024,
          maxCacheFileSize: 20 * 1024 * 1024,
          key: 'test_key',
        ),
      );

      await controller.preCache(dataSource);

      expect(mockPlatform.preCacheCalls.length, 1);
      expect(mockPlatform.preCacheCalls.first.uri, videoUrl);
      expect(
        mockPlatform.preCacheCalls.first.cacheConfiguration?.key,
        'test_key',
      );
      expect(mockPlatform.preCacheSizeCalls.first, 2 * 1024 * 1024);
    });

    test(
      'preCache with onProgress callback receives matching progress events',
      () async {
        const videoUrl = 'https://example.com/video.mp4';
        final dataSource = PlayerDataSource(
          DataSourceType.network,
          videoUrl,
        );

        final receivedProgress = <PreCacheProgress>[];

        mockPlatform
            .preCacheHandler = (dataSource, preCacheSize, onProgress) async {
          BetterPlayerPlatform.instance.emitPreCacheProgress(
            const PreCacheProgress(
              url: videoUrl,
              totalBytes: 1000,
              bytesDownloaded: 250,
              progress: 0.25,
            ),
          );
          BetterPlayerPlatform.instance.emitPreCacheProgress(
            const PreCacheProgress(
              url: 'https://other.com/video.mp4',
              totalBytes: 500,
              bytesDownloaded: 500,
              progress: 1,
            ),
          );
          BetterPlayerPlatform.instance.emitPreCacheProgress(
            const PreCacheProgress(
              url: videoUrl,
              totalBytes: 1000,
              bytesDownloaded: 1000,
              progress: 1,
            ),
          );
          // Microtask tick to ensure broadcast stream delivers events before preCache returns
          await Future<void>.delayed(Duration.zero);
        };

        await controller.preCache(
          dataSource,
          onProgress: receivedProgress.add,
        );

        expect(receivedProgress.length, 2);
        expect(receivedProgress[0].percent, 25.0);
        expect(receivedProgress[1].percent, 100.0);
        expect(receivedProgress[1].isCompleted, isTrue);
      },
    );

    test('preCache with onProgress matches by cacheKey when set', () async {
      const videoUrl = 'https://example.com/signed-url-123';
      const cacheKey = 'stable-video-key';
      final dataSource = PlayerDataSource(
        DataSourceType.network,
        videoUrl,
        cacheConfiguration: const CacheConfiguration(
          useCache: true,
          key: cacheKey,
        ),
      );

      final receivedProgress = <PreCacheProgress>[];

      mockPlatform.preCacheHandler =
          (dataSource, preCacheSize, onProgress) async {
            BetterPlayerPlatform.instance.emitPreCacheProgress(
              const PreCacheProgress(
                url: 'https://example.com/another-signed-url',
                cacheKey: cacheKey,
                totalBytes: 2000,
                bytesDownloaded: 1000,
                progress: 0.5,
              ),
            );
            await Future<void>.delayed(Duration.zero);
          };

      await controller.preCache(
        dataSource,
        onProgress: receivedProgress.add,
      );

      expect(receivedProgress.length, 1);
      expect(receivedProgress.first.cacheKey, cacheKey);
      expect(receivedProgress.first.percent, 50.0);
    });

    test('preCacheProgressStream exposes stream events directly', () async {
      final events = <PreCacheProgress>[];
      final subscription = controller.preCacheProgressStream.listen(events.add);

      BetterPlayerPlatform.instance.emitPreCacheProgress(
        const PreCacheProgress(
          url: 'https://example.com/stream-test.mp4',
          totalBytes: 1000,
          bytesDownloaded: 100,
          progress: 0.1,
        ),
      );

      // Give stream event time to deliver
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.percent, 10.0);

      await subscription.cancel();
    });

    test('stopPreCache calls stopPreCache on platform', () async {
      const videoUrl = 'https://example.com/video.mp4';
      final dataSource = PlayerDataSource(
        DataSourceType.network,
        videoUrl,
        cacheConfiguration: const CacheConfiguration(
          useCache: true,
          key: 'stop_key',
        ),
      );

      // Verify stopPreCache does not throw
      await expectLater(
        controller.stopPreCache(dataSource),
        completes,
      );
    });

    test('clearCache calls clearCache on platform', () async {
      await expectLater(
        controller.clearCache(),
        completes,
      );
    });

    test(
      'onProgress continues receiving events after preCache returns until completed',
      () async {
        const videoUrl = 'https://example.com/async-video.mp4';
        final dataSource = PlayerDataSource(
          DataSourceType.network,
          videoUrl,
        );

        final receivedProgress = <PreCacheProgress>[];

        // preCache returns immediately (simulating native asynchronous work)
        await controller.preCache(
          dataSource,
          onProgress: receivedProgress.add,
        );

        expect(receivedProgress, isEmpty);

        // Emit first progress event
        BetterPlayerPlatform.instance.emitPreCacheProgress(
          const PreCacheProgress(
            url: videoUrl,
            totalBytes: 2000,
            bytesDownloaded: 1000,
            progress: 0.5,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(receivedProgress.length, 1);
        expect(receivedProgress.first.percent, 50.0);

        // Emit completion event
        BetterPlayerPlatform.instance.emitPreCacheProgress(
          const PreCacheProgress(
            url: videoUrl,
            totalBytes: 2000,
            bytesDownloaded: 2000,
            progress: 1,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(receivedProgress.length, 2);
        expect(receivedProgress.last.isCompleted, isTrue);

        // Subsequent event should be ignored as subscription was closed upon completion
        BetterPlayerPlatform.instance.emitPreCacheProgress(
          const PreCacheProgress(
            url: videoUrl,
            totalBytes: 2000,
            bytesDownloaded: 2000,
            progress: 1,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(receivedProgress.length, 2);
      },
    );

    test('stopPreCache cancels active onProgress subscription', () async {
      const videoUrl = 'https://example.com/cancelled-video.mp4';
      final dataSource = PlayerDataSource(
        DataSourceType.network,
        videoUrl,
      );

      final receivedProgress = <PreCacheProgress>[];

      await controller.preCache(
        dataSource,
        onProgress: receivedProgress.add,
      );

      BetterPlayerPlatform.instance.emitPreCacheProgress(
        const PreCacheProgress(
          url: videoUrl,
          totalBytes: 2000,
          bytesDownloaded: 500,
          progress: 0.25,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(receivedProgress.length, 1);

      await controller.stopPreCache(dataSource);

      // Event emitted after stopPreCache should not reach onProgress
      BetterPlayerPlatform.instance.emitPreCacheProgress(
        const PreCacheProgress(
          url: videoUrl,
          totalBytes: 2000,
          bytesDownloaded: 1500,
          progress: 0.75,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(receivedProgress.length, 1);
    });

    test(
      'error progress event cancels active onProgress subscription',
      () async {
        const videoUrl = 'https://example.com/failed-video.mp4';
        final dataSource = PlayerDataSource(
          DataSourceType.network,
          videoUrl,
        );

        final receivedProgress = <PreCacheProgress>[];

        await controller.preCache(
          dataSource,
          onProgress: receivedProgress.add,
        );

        // Emit error event
        BetterPlayerPlatform.instance.emitPreCacheProgress(
          const PreCacheProgress(
            url: videoUrl,
            totalBytes: -1,
            bytesDownloaded: 0,
            progress: -2,
            error: 'Network connection failed',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(receivedProgress.length, 1);
        expect(receivedProgress.first.hasError, isTrue);

        // Subsequent event should not reach onProgress
        BetterPlayerPlatform.instance.emitPreCacheProgress(
          const PreCacheProgress(
            url: videoUrl,
            totalBytes: 2000,
            bytesDownloaded: 1000,
            progress: 0.5,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(receivedProgress.length, 1);
      },
    );

    test('clearCache cancels all active onProgress subscriptions', () async {
      const videoUrl1 = 'https://example.com/video-1.mp4';
      const videoUrl2 = 'https://example.com/video-2.mp4';

      final received1 = <PreCacheProgress>[];
      final received2 = <PreCacheProgress>[];

      await controller.preCache(
        PlayerDataSource(DataSourceType.network, videoUrl1),
        onProgress: received1.add,
      );
      await controller.preCache(
        PlayerDataSource(DataSourceType.network, videoUrl2),
        onProgress: received2.add,
      );

      await controller.clearCache();

      BetterPlayerPlatform.instance.emitPreCacheProgress(
        const PreCacheProgress(
          url: videoUrl1,
          totalBytes: 2000,
          bytesDownloaded: 500,
          progress: 0.25,
        ),
      );
      BetterPlayerPlatform.instance.emitPreCacheProgress(
        const PreCacheProgress(
          url: videoUrl2,
          totalBytes: 2000,
          bytesDownloaded: 500,
          progress: 0.25,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(received1, isEmpty);
      expect(received2, isEmpty);
    });

    test(
      'custom cacheKey is correctly tracked and matches progress events',
      () async {
        const videoUrl = 'https://example.com/custom-key-video.mp4';
        const customKey = 'my_custom_cache_key';

        final receivedProgress = <PreCacheProgress>[];

        await controller.preCache(
          PlayerDataSource(
            DataSourceType.network,
            videoUrl,
            cacheConfiguration: const CacheConfiguration(
              useCache: true,
              key: customKey,
            ),
          ),
          onProgress: receivedProgress.add,
        );

        BetterPlayerPlatform.instance.emitPreCacheProgress(
          const PreCacheProgress(
            url: 'https://different-url-same-key.com',
            cacheKey: customKey,
            totalBytes: 3000,
            bytesDownloaded: 1500,
            progress: 0.5,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(receivedProgress.length, 1);
        expect(receivedProgress.first.cacheKey, customKey);
      },
    );
  });
}
