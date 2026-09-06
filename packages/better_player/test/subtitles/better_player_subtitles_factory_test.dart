import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source_type.dart';
import 'package:better_player/src/subtitles/player_subtitles_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PlayerSubtitlesFactory tests', () {
    setUp(() {
      PlayerSubtitlesFactory.httpClient = null;
    });

    test('parseSubtitles from memory', () async {
      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.memory,
        content: '1\n00:00:01,000 --> 00:00:02,000\nHello\n\n',
      );
      final subtitles = await PlayerSubtitlesFactory.parseSubtitles(
        source,
      );
      expect(subtitles.length, 1);
      expect(subtitles[0].texts![0], 'Hello');
    });

    test('parseSubtitles from network', () async {
      PlayerSubtitlesFactory.httpClient = MockClient((request) async {
        return http.Response(
          '1\n00:00:01,000 --> 00:00:02,000\nHello\n\n',
          200,
        );
      });

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.network,
        urls: ['https://example.com/subs.srt'],
      );
      final subtitles = await PlayerSubtitlesFactory.parseSubtitles(
        source,
      );
      expect(subtitles.length, 1);
    });

    test('parseSubtitles from file handles non-existent file', () async {
      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.file,
        urls: ['non_existent_file.srt'],
      );
      final subtitles = await PlayerSubtitlesFactory.parseSubtitles(
        source,
      );
      expect(subtitles.length, 0);
    });
  });
}
