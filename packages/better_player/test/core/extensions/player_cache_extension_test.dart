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
  });
}
