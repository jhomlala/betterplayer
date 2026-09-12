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
          'NOTE This is a note block\n\n'
          '1\n'
          '00:00:00.000 --> 00:00:05.000 align:start\n'
          'Hello &amp; Welcome &lt;b&gt;Bold&lt;/b&gt;';

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.memory,
        content: vttContent,
      );

      final subtitles = await factory.parseSubtitles(source);
      expect(subtitles.length, 1);
      expect(subtitles[0].start, const Duration(seconds: 0));
      expect(subtitles[0].end, const Duration(seconds: 5));
      expect(subtitles[0].alignment, Alignment.bottomLeft);
      // Note: HTML entities are intentionally preserved in the raw model texts
      // and decoded dynamically at render time by WebVttInlineParser.
      expect(
        subtitles[0].texts![0],
        'Hello &amp; Welcome &lt;b&gt;Bold&lt;/b&gt;',
      );
    });

    test('WebVttInlineParser decodes entities and parses tags', () {
      const input = 'Hello &amp; &lt;World&gt; <b>Bold</b> and <i>Italic</i>';
      final spans = WebVttInlineParser.parse(input, const TextStyle());
      expect(spans.children!.length, greaterThan(1));
    });
  });
}
