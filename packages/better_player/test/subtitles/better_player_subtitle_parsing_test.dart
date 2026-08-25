import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerSubtitle parsing tests', () {
    test('Parse SRT line with index', () {
      const line = '1\n00:00:01,000 --> 00:00:04,000\nHello World';
      final subtitle = BetterPlayerSubtitle(line, false);
      expect(subtitle.index, 1);
      expect(subtitle.start, const Duration(seconds: 1));
      expect(subtitle.end, const Duration(seconds: 4));
      expect(subtitle.texts, ['Hello World']);
    });

    test('Parse SRT line without index', () {
      const line = '00:00:01,000 --> 00:00:04,000\nHello World';
      final subtitle = BetterPlayerSubtitle(line, false);
      expect(subtitle.start, const Duration(seconds: 1));
      expect(subtitle.texts, ['Hello World']);
    });

    test('Parse WebVTT line', () {
      const line = '00:00:01.000 --> 00:00:04.000\nHello VTT';
      final subtitle = BetterPlayerSubtitle(line, true);
      expect(subtitle.start, const Duration(seconds: 1));
      expect(subtitle.texts, ['Hello VTT']);
    });

    test('Parse line with 2 text lines', () {
      const line = '1\n00:00:01,000 --> 00:00:04,000\nLine 1\nLine 2';
      final subtitle = BetterPlayerSubtitle(line, false);
      expect(subtitle.texts, ['Line 1', 'Line 2']);
    });

    test('Parse invalid time format', () {
      const line = '1\nINVALID --> INVALID\nHello';
      final subtitle = BetterPlayerSubtitle(line, false);
      // It should return an empty or default subtitle instead of crashing
      expect(subtitle.start, const Duration());
    });
  });
}
