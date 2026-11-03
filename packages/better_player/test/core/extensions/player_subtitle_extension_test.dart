import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';
import '../../helpers/mock_player_engine_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerSubtitleExtension', () {
    test(
      'asmsSegmentsLoading resets to false in finally block when an exception occurs during segment loading',
      () async {
        final controller = BetterPlayerController(const PlayerConfiguration());
        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          content: 'WEBVTT\n\n00:00:01.000 --> 00:00:03.000\nHello',
          asmsIsSegmented: true,
          asmsSegmentsTime: 1000,
          asmsSegments: [
            PlayerAsmsSubtitleSegment(
              Duration.zero,
              const Duration(seconds: 5),
              'https://example.com/segment1.vtt',
            ),
          ],
        );

        controller.addVideoListener(() {
          throw StateError('Video listener failed');
        });

        await controller.setupSubtitleSource(source);

        expect(controller.subtitleState.asmsSegmentsLoading, isFalse);
        controller.dispose();
      },
    );

    test('setupSubtitleSource with none clears active subtitles', () async {
      final engine = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: engine,
      );

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.none,
      );

      await controller.setupSubtitleSource(source);

      expect(controller.subtitleState.subtitlesSource, source);
      expect(controller.subtitlesLines, isEmpty);
      expect(engine.lastTextTrackName, '');
      expect(engine.lastTextTrackIndex, -1);

      controller.dispose();
    });

    test(
      'setupSubtitleSource with embedded configures text track on engine',
      () async {
        final engine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: engine,
            );

        final source = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.embedded,
          name: 'English CC',
          index: 1,
        );

        await controller.setupSubtitleSource(source);

        expect(controller.subtitleState.subtitlesSource, source);
        expect(engine.lastTextTrackName, 'English CC');
        expect(engine.lastTextTrackIndex, 1);

        controller.dispose();
      },
    );

    test('setupSubtitleSource with memory parses subtitle lines', () async {
      final engine = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: engine,
      );

      final source = PlayerSubtitlesSource(
        type: PlayerSubtitlesSourceType.memory,
        content: 'WEBVTT\n\n00:00:01.000 --> 00:00:03.000\nHello world',
      );

      await controller.setupSubtitleSource(source);

      expect(controller.subtitleState.subtitlesSource, source);
      expect(controller.subtitlesLines.isNotEmpty, isTrue);
      expect(controller.subtitlesLines.first.texts?.first, 'Hello world');

      controller.dispose();
    });
  });
}
