import 'package:better_player/better_player.dart';
import 'package:better_player/src/core/state/player_subtitle_state.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerSubtitleState', () {
    test('should initialize with correct default values', () {
      final state = PlayerSubtitleState();

      expect(state.subtitlesSourceList, isEmpty);
      expect(state.subtitlesSource, isNull);
      expect(state.subtitlesLines, isEmpty);
      expect(state.renderedSubtitle, isNull);
      expect(state.asmsSegmentsLoading, isFalse);
      expect(state.asmsSegmentsLoaded, isEmpty);
    });

    test('should allow updating fields', () {
      final state = PlayerSubtitleState();

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.network,
        urls: ['url'],
      );
      final subtitle = PlayerSubtitle(
        '00:00:01.000 --> 00:00:02.000\nHello',
        false,
      );

      state.subtitlesSourceList.add(source);
      state.subtitlesSource = source;
      state.subtitlesLines.add(subtitle);
      state.renderedSubtitle = subtitle;
      state.asmsSegmentsLoading = true;
      state.asmsSegmentsLoaded.add('segment1');

      expect(state.subtitlesSourceList, hasLength(1));
      expect(state.subtitlesSource, source);
      expect(state.subtitlesLines, hasLength(1));
      expect(state.renderedSubtitle, subtitle);
      expect(state.asmsSegmentsLoading, isTrue);
      expect(state.asmsSegmentsLoaded, contains('segment1'));
    });
  });
}
