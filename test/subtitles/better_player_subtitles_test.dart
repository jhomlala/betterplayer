import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerSubtitlesFactory tests', () {
    test('Parse SRT subtitles from memory', () async {
      const srtContent = '''
1
00:00:01,000 --> 00:00:04,000
Hello World

2
00:00:05,000 --> 00:00:08,000
Better Player Subtitles
''';
      final source = BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.memory,
        content: srtContent,
      );
      final subtitles =
          await BetterPlayerSubtitlesFactory.parseSubtitles(source);

      expect(subtitles.length, 2);
      expect(subtitles[0].start, const Duration(seconds: 1));
      expect(subtitles[0].end, const Duration(seconds: 4));
      expect(subtitles[0].texts!.first, 'Hello World');
    });

    test('Parse WebVTT subtitles from memory', () async {
      const vttContent = '''
WEBVTT

00:00:01.000 --> 00:00:04.000
Hello World VTT

00:00:05.000 --> 00:00:08.000
Better Player Subtitles VTT
''';
      final source = BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.memory,
        content: vttContent,
      );
      final subtitles =
          await BetterPlayerSubtitlesFactory.parseSubtitles(source);

      expect(subtitles.length, 2);
      expect(subtitles[0].texts!.first, 'Hello World VTT');
    });

    test('Parse invalid content should return empty list', () async {
      const invalidContent = 'NOT SUBTITLES';
      final source = BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.memory,
        content: invalidContent,
      );
      final subtitles =
          await BetterPlayerSubtitlesFactory.parseSubtitles(source);
      expect(subtitles.isEmpty, true);
    });
  });
}
