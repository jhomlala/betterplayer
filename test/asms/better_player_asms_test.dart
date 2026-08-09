import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayer ASMS models tests', () {
    test('BetterPlayerAsmsSubtitle initialization', () {
      final subtitle = BetterPlayerAsmsSubtitle(
        name: 'English',
        language: 'en',
        isDefault: true,
      );
      expect(subtitle.name, 'English');
      expect(subtitle.language, 'en');
      expect(subtitle.isDefault, true);
    });

    test('BetterPlayerAsmsSubtitleSegment initialization', () {
      final segment = BetterPlayerAsmsSubtitleSegment(
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        'https://example.com/seg1.vtt',
      );
      expect(segment.startTime, const Duration(seconds: 1));
      expect(segment.endTime, const Duration(seconds: 2));
      expect(segment.realUrl, 'https://example.com/seg1.vtt');
    });

    test('BetterPlayerAsmsTrack equality', () {
      final track1 =
          BetterPlayerAsmsTrack('1', 1920, 1080, 5000, 30, 'avc1', 'video/mp4');
      final track2 =
          BetterPlayerAsmsTrack('1', 1920, 1080, 5000, 30, 'avc1', 'video/mp4');
      final track3 =
          BetterPlayerAsmsTrack('2', 1280, 720, 2000, 30, 'avc1', 'video/mp4');

      expect(track1 == track2, true);
      expect(track1 == track3, false);
    });
  });
}
