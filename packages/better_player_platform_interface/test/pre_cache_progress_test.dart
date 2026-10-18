import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreCacheProgress tests', () {
    test('initialization and properties', () {
      const progress = PreCacheProgress(
        url: 'https://example.com/video.mp4',
        cacheKey: 'video_key',
        progress: 0.5,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );

      expect(progress.url, 'https://example.com/video.mp4');
      expect(progress.cacheKey, 'video_key');
      expect(progress.progress, 0.5);
      expect(progress.percent, 50.0);
      expect(progress.isCompleted, isFalse);
      expect(progress.bytesDownloaded, 500);
      expect(progress.totalBytes, 1000);
    });

    test('isCompleted returns true when progress >= 1.0', () {
      const completed = PreCacheProgress(
        url: 'https://example.com/video.mp4',
        progress: 1,
        bytesDownloaded: 1000,
        totalBytes: 1000,
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.percent, 100.0);
    });

    test('equality and hashCode', () {
      const progress1 = PreCacheProgress(
        url: 'https://example.com/video.mp4',
        cacheKey: 'video_key',
        progress: 0.5,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );
      const progress2 = PreCacheProgress(
        url: 'https://example.com/video.mp4',
        cacheKey: 'video_key',
        progress: 0.5,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );
      const progress3 = PreCacheProgress(
        url: 'https://example.com/video.mp4',
        cacheKey: 'different_key',
        progress: 0.5,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );

      expect(progress1, equals(progress2));
      expect(progress1.hashCode, equals(progress2.hashCode));
      expect(progress1, isNot(equals(progress3)));
    });

    test('toString contains fields', () {
      const progress = PreCacheProgress(
        url: 'https://example.com/video.mp4',
        cacheKey: 'video_key',
        progress: 0.75,
        bytesDownloaded: 750,
        totalBytes: 1000,
      );

      final str = progress.toString();
      expect(str, contains('https://example.com/video.mp4'));
      expect(str, contains('video_key'));
      expect(str, contains('0.75'));
      expect(str, contains('750'));
      expect(str, contains('1000'));
    });
  });
}
