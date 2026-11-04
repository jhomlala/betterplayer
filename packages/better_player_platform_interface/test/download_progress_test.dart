import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadProgress tests', () {
    test('initialization and properties', () {
      const progress = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.downloading,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );

      expect(progress.url, 'https://example.com/video.mpd');
      expect(progress.state, DownloadState.downloading);
      expect(progress.bytesDownloaded, 500);
      expect(progress.totalBytes, 1000);
      expect(progress.error, isNull);
      expect(progress.fraction, 0.5);
      expect(progress.percent, 50.0);
      expect(progress.hasTotalBytes, isTrue);
      expect(progress.isActive, isTrue);
      expect(progress.isCompleted, isFalse);
      expect(progress.hasError, isFalse);
    });

    test('unknown total size reports zero fraction and percent', () {
      const progress = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.downloading,
        bytesDownloaded: 215755118,
        totalBytes: 0,
      );

      expect(progress.hasTotalBytes, isFalse);
      expect(progress.fraction, 0.0);
      expect(progress.percent, 0.0);
      expect(progress.bytesDownloaded, 215755118);
    });

    test('fraction is clamped between 0 and 1', () {
      const over = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.downloading,
        bytesDownloaded: 1200,
        totalBytes: 1000,
      );
      const negative = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.downloading,
        bytesDownloaded: -5,
        totalBytes: 1000,
      );

      expect(over.fraction, 1.0);
      expect(over.percent, 100.0);
      expect(negative.fraction, 0.0);
    });

    test('completed state reports a playable download', () {
      const progress = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.completed,
        bytesDownloaded: 2408022281,
        totalBytes: 2408022281,
      );

      expect(progress.isCompleted, isTrue);
      expect(progress.isActive, isFalse);
      expect(progress.hasError, isFalse);
      expect(progress.fraction, 1.0);
    });

    test('failed state reports an error', () {
      const progress = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.failed,
        bytesDownloaded: 0,
        totalBytes: 0,
        error: 'Download failed: network unreachable',
      );

      expect(progress.hasError, isTrue);
      expect(progress.isCompleted, isFalse);
      expect(progress.isActive, isFalse);
      expect(progress.error, 'Download failed: network unreachable');
    });

    test('paused state is neither active nor completed', () {
      const progress = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.paused,
        bytesDownloaded: 100,
        totalBytes: 1000,
      );

      expect(progress.isActive, isFalse);
      expect(progress.isCompleted, isFalse);
      expect(progress.hasError, isFalse);
      expect(progress.fraction, 0.1);
    });

    test('equality and hashCode', () {
      const progress1 = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.downloading,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );
      const progress2 = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.downloading,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );
      const progress3 = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.paused,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );

      expect(progress1, equals(progress2));
      expect(progress1.hashCode, equals(progress2.hashCode));
      expect(progress1, isNot(equals(progress3)));
    });

    test('toString contains fields', () {
      const progress = DownloadProgress(
        url: 'https://example.com/video.mpd',
        state: DownloadState.failed,
        bytesDownloaded: 750,
        totalBytes: 1000,
        error: 'timed out',
      );

      final str = progress.toString();
      expect(str, contains('https://example.com/video.mpd'));
      expect(str, contains('DownloadState.failed'));
      expect(str, contains('750'));
      expect(str, contains('1000'));
      expect(str, contains('timed out'));
    });
  });
}
