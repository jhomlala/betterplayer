import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      // A video listener that throws during subtitle processing
      controller.addVideoListener(() {
        throw StateError('Video listener failed');
      });

      // Loading segments will invoke listeners and throw inside the try block
      await controller.setupSubtitleSource(source);

      // In current code, because it threw before line 130, asmsSegmentsLoading remains true!
      expect(controller.subtitleState.asmsSegmentsLoading, isFalse);
      controller.dispose();
    },
  );
}
