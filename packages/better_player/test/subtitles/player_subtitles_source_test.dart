import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerSubtitlesSource tests', () {
    test('Default values', () {
      final source = PlayerSubtitlesSource();
      expect(source.name, 'Default subtitles');
      expect(source.type, null);
    });

    test('Single factory', () {
      final sources = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.network,
        url: 'https://example.com/subs.vtt',
      );
      expect(sources.length, 1);
      expect(sources[0].type, PlayerSubtitlesSourceType.network);
      expect(sources[0].urls![0], 'https://example.com/subs.vtt');
    });
  });
}
