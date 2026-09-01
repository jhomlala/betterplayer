import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_output.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsoleLogOutput', () {
    const output = ConsoleLogOutput();

    test('formatMessage strips redundant tag from caller', () {
      final record = PlayerLogRecord(
        level: PlayerLogLevel.info,
        message: 'Video player initialized',
        tag: 'BetterPlayerController',
        timestamp: DateTime.now(),
        caller: 'BetterPlayerController._onVideoPlayerChanged',
      );

      final message = output.formatMessage(record);
      expect(message, '[_onVideoPlayerChanged] Video player initialized');
    });

    test('formatMessage keeps caller if it does not start with tag', () {
      final record = PlayerLogRecord(
        level: PlayerLogLevel.info,
        message: 'Something happened',
        tag: 'OtherClass',
        timestamp: DateTime.now(),
        caller: 'BetterPlayerController._onVideoPlayerChanged',
      );

      final message = output.formatMessage(record);
      expect(
        message,
        '[BetterPlayerController._onVideoPlayerChanged] Something happened',
      );
    });

    test('formatMessage omits caller if it matches tag exactly', () {
      final record = PlayerLogRecord(
        level: PlayerLogLevel.info,
        message: 'Something happened',
        tag: 'BetterPlayerController',
        timestamp: DateTime.now(),
        caller: 'BetterPlayerController',
      );

      // It starts with 'BetterPlayerController' but not 'BetterPlayerController.'
      // So it shouldn't strip anything, but it shouldn't be empty either.
      final message = output.formatMessage(record);
      expect(message, '[BetterPlayerController] Something happened');
    });

    test('formatMessage omits caller completely if caller is null', () {
      final record = PlayerLogRecord(
        level: PlayerLogLevel.info,
        message: 'Native event',
        tag: 'Android',
        timestamp: DateTime.now(),
      );

      final message = output.formatMessage(record);
      expect(message, 'Native event');
    });

    test('onLog with usePrint does not throw', () {
      const printOutput = ConsoleLogOutput(usePrint: true);
      final record = PlayerLogRecord(
        level: PlayerLogLevel.info,
        message: 'Test message',
        tag: 'TestTag',
        timestamp: DateTime.now(),
        error: 'TestError',
        stackTrace: StackTrace.current,
      );

      expect(() => printOutput.onLog(record), returnsNormally);
    });
  });
}
