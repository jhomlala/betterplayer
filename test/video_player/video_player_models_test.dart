import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataSource tests', () {
    test('DataSource initialization and key', () {
      final source = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );
      expect(source.sourceType, DataSourceType.network);
      expect(source.uri, 'https://example.com/video.mp4');
      expect(source.key, 'https://example.com/video.mp4');
    });

    test('DataSource asset and package key', () {
      final source = DataSource(
        sourceType: DataSourceType.asset,
        asset: 'assets/video.mp4',
        package: 'test_package',
      );
      expect(source.key, 'test_package:assets/video.mp4');
    });

    test('DataSource with formatHint key', () {
      final source = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video',
        formatHint: VideoFormat.hls,
      );
      expect(source.key, 'https://example.com/video:hls');
    });

    test('DataSource toString', () {
      final source = DataSource(sourceType: DataSourceType.network, uri: 'uri');
      expect(
        source.toString().contains('sourceType: DataSourceType.network'),
        true,
      );
    });
  });

  group('VideoEvent tests', () {
    test('VideoEvent equality', () {
      final event1 = VideoEvent(eventType: VideoEventType.play, key: '1');
      final event2 = VideoEvent(eventType: VideoEventType.play, key: '1');
      final event3 = VideoEvent(eventType: VideoEventType.pause, key: '1');

      expect(event1 == event2, true);
      expect(event1 == event3, false);
      expect(event1.hashCode == event2.hashCode, true);
    });
  });

  group('DurationRange tests', () {
    test('DurationRange fractions', () {
      final range = DurationRange(
        const Duration(seconds: 2),
        const Duration(seconds: 8),
      );
      const total = Duration(seconds: 10);
      expect(range.startFraction(total), 0.2);
      expect(range.endFraction(total), 0.8);
    });

    test('DurationRange equality', () {
      final range1 = DurationRange(
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      );
      final range2 = DurationRange(
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      );
      expect(range1 == range2, true);
      expect(range1.hashCode == range2.hashCode, true);
    });
  });
}
