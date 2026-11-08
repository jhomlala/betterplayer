import 'dart:convert';
import 'dart:io';

import 'package:better_player/src/subtitles/player_subtitles_factory.dart';
import 'package:better_player/src/subtitles/player_subtitles_source.dart';
import 'package:better_player/src/subtitles/player_subtitles_source_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PlayerSubtitlesFactory tests', () {
    test('parseSubtitles from memory', () async {
      final factory = PlayerSubtitlesFactory();
      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.memory,
        content: '1\n00:00:01,000 --> 00:00:02,000\nHello\n\n',
      );
      final subtitles = await factory.parseSubtitles(
        source,
      );
      expect(subtitles.length, 1);
      expect(subtitles[0].texts![0], 'Hello');
    });

    test('parseSubtitles from network', () async {
      final factory = PlayerSubtitlesFactory(
        httpClient: MockClient((request) async {
          return http.Response(
            '1\n00:00:01,000 --> 00:00:02,000\nHello\n\n',
            200,
          );
        }),
      );

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.network,
        urls: ['https://example.com/subs.srt'],
      );
      final subtitles = await factory.parseSubtitles(
        source,
      );
      expect(subtitles.length, 1);
    });

    test(
      'parseSubtitles from network correctly decodes UTF-8 with special characters',
      () async {
        const srtContent =
            '1\n00:00:01,000 --> 00:00:02,000\nCześć! Dzień dobry, Señor José\n\n';
        final utf8Bytes = utf8.encode(srtContent);

        final factory = PlayerSubtitlesFactory(
          httpClient: MockClient((request) async {
            // Send Content-Type: text/vtt with NO charset parameter to verify bodyBytes decoding
            return http.Response.bytes(
              utf8Bytes,
              200,
              headers: {'content-type': 'text/vtt'},
            );
          }),
        );

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.network,
          urls: ['https://example.com/subs.vtt'],
        );
        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles.length, 1);
        expect(subtitles[0].texts![0], 'Cześć! Dzień dobry, Señor José');
      },
    );

    test(
      'parseSubtitles from network ignores HTTP 404 error responses',
      () async {
        final factory = PlayerSubtitlesFactory(
          httpClient: MockClient((request) async {
            return http.Response(
              '<!DOCTYPE html><html><body>404 Not Found</body></html>',
              404,
            );
          }),
        );

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.network,
          urls: ['https://example.com/missing.srt'],
        );
        final subtitles = await factory.parseSubtitles(source);
        expect(subtitles, isEmpty);
      },
    );

    test('parseSubtitles from file handles non-existent file', () async {
      final factory = PlayerSubtitlesFactory();
      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.file,
        urls: ['non_existent_file.srt'],
      );
      final subtitles = await factory.parseSubtitles(
        source,
      );
      expect(subtitles.length, 0);
    });

    test('parseSubtitles from file', () async {
      final factory = PlayerSubtitlesFactory();
      final file = File('${Directory.systemTemp.path}/test_subs.srt');
      await file.writeAsString(
        '1\n00:00:01,000 --> 00:00:02,000\nHello from file\n\n',
      );

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.file,
        urls: [file.path],
      );
      final subtitles = await factory.parseSubtitles(source);
      expect(subtitles.length, 1);
      expect(subtitles[0].texts![0], 'Hello from file');

      await file.delete();
    });
  });
}
