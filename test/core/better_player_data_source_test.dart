import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerDataSource tests', () {
    test('Network factory', () {
      final source = BetterPlayerDataSource.network(
        'https://example.com/video.mp4',
      );
      expect(source.type, BetterPlayerDataSourceType.network);
      expect(source.url, 'https://example.com/video.mp4');
    });

    test('File factory', () {
      final source = BetterPlayerDataSource.file('/path/to/video.mp4');
      expect(source.type, BetterPlayerDataSourceType.file);
      expect(source.url, '/path/to/video.mp4');
    });

    test('Memory factory', () {
      final source = BetterPlayerDataSource.memory([1, 2, 3]);
      expect(source.type, BetterPlayerDataSourceType.memory);
      expect(source.bytes, [1, 2, 3]);
    });

    test('copyWith', () {
      final source = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        'https://example.com/video.mp4',
      );
      final newSource = source.copyWith(
        url: 'https://example.com/new.mp4',
        liveStream: true,
        useAsmsTracks: false,
      );
      expect(newSource.url, 'https://example.com/new.mp4');
      expect(newSource.type, BetterPlayerDataSourceType.network);
      expect(newSource.liveStream, true);
      expect(newSource.useAsmsTracks, false);
      expect(newSource.useAsmsSubtitles, true); // Should remain default
    });

    test('Network factory with all parameters', () {
      final source = BetterPlayerDataSource.network(
        'url',
        subtitles: [
          BetterPlayerSubtitlesSource(name: 'en'),
        ],
        liveStream: true,
        headers: {'header': 'value'},
        useAsmsSubtitles: false,
        useAsmsTracks: false,
        useAsmsAudioTracks: false,
        qualities: {'720p': 'url720'},
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
        ),
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: true,
          title: 'title',
        ),
        overriddenDuration: const Duration(seconds: 10),
        videoFormat: BetterPlayerVideoFormat.hls,
        drmConfiguration: const BetterPlayerDrmConfiguration(
          drmType: BetterPlayerDrmType.clearKey,
        ),
      );

      expect(source.url, 'url');
      expect(source.subtitles?.length, 1);
      expect(source.liveStream, true);
      expect(source.headers?['header'], 'value');
      expect(source.useAsmsSubtitles, false);
      expect(source.useAsmsTracks, false);
      expect(source.useAsmsAudioTracks, false);
      expect(source.resolutions?['720p'], 'url720');
      expect(source.cacheConfiguration?.useCache, true);
      expect(source.notificationConfiguration?.showNotification, true);
      expect(source.notificationConfiguration?.title, 'title');
      expect(source.overriddenDuration?.inSeconds, 10);
      expect(source.videoFormat, BetterPlayerVideoFormat.hls);
      expect(source.drmConfiguration?.drmType, BetterPlayerDrmType.clearKey);
    });

    test('File factory with all parameters', () {
      final source = BetterPlayerDataSource.file(
        'file_url',
        subtitles: [
          BetterPlayerSubtitlesSource(name: 'en'),
        ],
        useAsmsSubtitles: false,
        useAsmsTracks: false,
        qualities: {'720p': 'url720'},
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
        ),
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
        overriddenDuration: const Duration(seconds: 10),
      );

      expect(source.url, 'file_url');
      expect(source.type, BetterPlayerDataSourceType.file);
      expect(source.subtitles?.length, 1);
      expect(source.useAsmsSubtitles, false);
      expect(source.useAsmsTracks, false);
      expect(source.resolutions?['720p'], 'url720');
      expect(source.cacheConfiguration?.useCache, true);
    });

    test('Memory factory with all parameters', () {
      final source = BetterPlayerDataSource.memory(
        [1, 2, 3],
        videoExtension: 'mp4',
        subtitles: [
          BetterPlayerSubtitlesSource(name: 'en'),
        ],
        useAsmsSubtitles: false,
        useAsmsTracks: false,
        qualities: {'720p': 'url720'},
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
        ),
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
        overriddenDuration: const Duration(seconds: 10),
      );

      expect(source.bytes, [1, 2, 3]);
      expect(source.type, BetterPlayerDataSourceType.memory);
      expect(source.videoExtension, 'mp4');
      expect(source.subtitles?.length, 1);
      expect(source.useAsmsSubtitles, false);
      expect(source.useAsmsTracks, false);
      expect(source.resolutions?['720p'], 'url720');
      expect(source.cacheConfiguration?.useCache, true);
    });

    test('memory source assertion works', () {
      expect(
        () => BetterPlayerDataSource(
          BetterPlayerDataSourceType.memory,
          '',
          bytes: [],
        ),
        throwsAssertionError,
      );
    });

    test('network source factories', () {
      final source = BetterPlayerDataSource.network(
        'url',
        liveStream: true,
      );
      expect(source.liveStream, true);
    });
  });
}
