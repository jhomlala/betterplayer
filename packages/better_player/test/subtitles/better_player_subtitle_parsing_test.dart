import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('PlayerSubtitle parsing tests', () {
    test('Parse SRT line with index', () {
      const line = '1\n00:00:01,000 --> 00:00:04,000\nHello World';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: false);
      expect(subtitle.index, 1);
      expect(subtitle.start, const Duration(seconds: 1));
      expect(subtitle.end, const Duration(seconds: 4));
      expect(subtitle.texts, ['Hello World']);
    });

    test('Parse SRT line without index', () {
      const line = '00:00:01,000 --> 00:00:04,000\nHello World';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: false);
      expect(subtitle.start, const Duration(seconds: 1));
      expect(subtitle.texts, ['Hello World']);
    });

    test('Parse WebVTT line', () {
      const line = '00:00:01.000 --> 00:00:04.000\nHello VTT';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: true);
      expect(subtitle.start, const Duration(seconds: 1));
      expect(subtitle.texts, ['Hello VTT']);
    });

    test('Parse line with 2 text lines', () {
      const line = '1\n00:00:01,000 --> 00:00:04,000\nLine 1\nLine 2';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: false);
      expect(subtitle.texts, ['Line 1', 'Line 2']);
    });

    test('Parse invalid time format', () {
      const line = '1\nINVALID --> INVALID\nHello';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: false);
      // It should return an empty or default subtitle instead of crashing
      expect(subtitle.start, const Duration());
    });

    test('Parse missing hour component MM:SS.mmm', () {
      const line = '01:23.456 --> 01:25.789\nMissing hour';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: true);
      expect(
        subtitle.start,
        const Duration(minutes: 1, seconds: 23, milliseconds: 456),
      );
      expect(
        subtitle.end,
        const Duration(minutes: 1, seconds: 25, milliseconds: 789),
      );
    });

    test('Parse WebVTT cue with alignment settings', () {
      const line =
          '00:01:00.000 --> 00:01:05.000 align:right line:0%\nAligned Subtitle';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: true);
      expect(subtitle.alignment, Alignment.bottomRight);
    });

    test('Parse WebVTT cue with center alignment settings', () {
      const line =
          '00:01:00.000 --> 00:01:05.000 align:center\nCenter Subtitle';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: true);
      expect(subtitle.alignment, Alignment.bottomCenter);
    });

    test('Parse WebVTT cue with corrupted align settings', () {
      const line =
          '00:01:00.000 --> 00:01:05.000 align:corrupted\nCorrupted Aligned Subtitle';
      final subtitle = PlayerSubtitle(value: line, isWebVTT: true);
      expect(subtitle.alignment, Alignment.bottomCenter);
    });

    test('Parse stringToDuration with space components', () {
      final duration = PlayerSubtitle.stringToDuration('01:02:03.456 ');
      expect(
        duration,
        const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 456),
      );
    });
  });
}
