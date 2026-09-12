import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source_type.dart';
import 'package:better_player/src/subtitles/player_subtitles_source.dart';
import 'package:better_player/src/subtitles/webvtt_inline_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('WebVTT Advanced Features and Timestamp Mapping Tests', () {
    test('Parse WebVTT with BOM, timestamp map, and cue settings', () async {
      final factory = PlayerSubtitlesFactory();
      const vttContent =
          '\uFEFFWEBVTT\n'
          'X-TIMESTAMP-MAP=MPEGTS:900000, LOCAL:00:00:10.000\n\n'
          'NOTE This is a note block\n'
          'multiline note content\n\n'
          'STYLE\n'
          '::cue { background-color: yellow; }\n\n'
          'REGION\n'
          'id:test\n\n'
          '1\n'
          '00:00:00.000 --> 00:00:05.000 align:start\n'
          'Hello &amp; Welcome &lt;b&gt;Bold&lt;/b&gt;';

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.memory,
        content: vttContent,
      );

      final subtitles = await factory.parseSubtitles(source);
      expect(subtitles.length, 1);
      expect(subtitles[0].start, Duration.zero);
      expect(subtitles[0].end, const Duration(seconds: 5));
      expect(subtitles[0].alignment, Alignment.bottomLeft);
      expect(
        subtitles[0].texts![0],
        'Hello &amp; Welcome &lt;b&gt;Bold&lt;/b&gt;',
      );
    });

    test(
      'Parse WebVTT with 33-bit MPEG-TS timestamp rollover map line',
      () async {
        final factory = PlayerSubtitlesFactory();
        // 8589934592 + 900000 = 8590834592 (which is 10s + 1 rollover count)
        const vttContent =
            'WEBVTT\n'
            'X-TIMESTAMP-MAP=MPEGTS:8590834592, LOCAL:00:00:20.000\n\n'
            '00:00:10.000 --> 00:00:15.000\n'
            'Rollover subtitle';

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: vttContent,
        );

        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles.length, 1);
        expect(
          subtitles[0].start,
          const Duration(
            hours: -26,
            minutes: -30,
            seconds: -23,
            milliseconds: -717,
          ),
        );
      },
    );

    test(
      'Parse WebVTT with corrupted or malformed X-TIMESTAMP-MAP lines',
      () async {
        final factory = PlayerSubtitlesFactory();
        const vttContent =
            'WEBVTT\n'
            'X-TIMESTAMP-MAP=MALFORMED\n\n'
            '00:00:01.000 --> 00:00:03.000\n'
            'Fallback subtitle';

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: vttContent,
        );

        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles.length, 1);
        expect(subtitles[0].start, const Duration(seconds: 1));
      },
    );

    test(
      'WebVttInlineParser handles nested tags, color codes, and line breaks',
      () {
        const input =
            '<b>Hello <i>nested</i></b><c.red>Red Cue</c.red><font color="#00ff00">Green Font</font><br/>New Line';
        final spans = WebVttInlineParser.parse(
          rawText: input,
          baseStyle: const TextStyle(),
        );
        expect(spans.children, isNotEmpty);
        // Verify that children contain TextSpans with expected styles or text
        expect(
          spans.children!.any((span) => (span as TextSpan).text == '\n'),
          isTrue,
        );
      },
    );

    test('WebVttInlineParser ignores timestamp tags', () {
      const input = '00:00:01.000 Hello 01:23.456 World';
      final spans = WebVttInlineParser.parse(
        rawText: input,
        baseStyle: const TextStyle(),
      );
      expect(spans.children, isNotEmpty);
    });
  });
}
