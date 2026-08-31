import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_output.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/logging/player_logger_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLogOutput extends PlayerLogOutput {
  final List<PlayerLogRecord> records = [];
  int initCount = 0;
  int destroyCount = 0;

  @override
  void init() {
    initCount++;
  }

  @override
  void output(PlayerLogRecord record) {
    records.add(record);
  }

  @override
  void destroy() {
    destroyCount++;
  }
}

void main() {
  group('PlayerLogger', () {
    late MockLogOutput mockOutput;

    setUp(() {
      mockOutput = MockLogOutput();
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          logLevel: PlayerLogLevel.debug,
          outputs: [mockOutput],
        ),
      );
    });

    test('setup() initializes and destroys outputs', () {
      expect(mockOutput.initCount, 1);

      final secondMockOutput = MockLogOutput();
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          outputs: [secondMockOutput],
        ),
      );

      expect(mockOutput.destroyCount, 1);
      expect(secondMockOutput.initCount, 1);
    });

    test('logs messages when level >= logLevel', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      PlayerLogger.debug('debug');
      PlayerLogger.info('info');
      PlayerLogger.warning('warning');
      PlayerLogger.error('error');

      expect(mockOutput.records.length, 3);
      expect(mockOutput.records[0].level, PlayerLogLevel.info);
      expect(mockOutput.records[1].level, PlayerLogLevel.warning);
      expect(mockOutput.records[2].level, PlayerLogLevel.error);
    });

    test('alwaysLogErrors logs error even if logLevel is none', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          logLevel: PlayerLogLevel.none,
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      PlayerLogger.info('info');
      PlayerLogger.error('error');

      expect(mockOutput.records.length, 1);
      expect(mockOutput.records[0].level, PlayerLogLevel.error);
      expect(mockOutput.records[0].message, 'error');
    });

    test('convenience methods pass all arguments', () {
      final error = Exception('test');
      final stackTrace = StackTrace.current;

      PlayerLogger.warning(
        'warn message',
        tag: 'CustomTag',
        error: error,
        stackTrace: stackTrace,
      );

      final record = mockOutput.records.last;
      expect(record.message, 'warn message');
      expect(record.tag, 'CustomTag');
      expect(record.level, PlayerLogLevel.warning);
      expect(record.error, error);
      expect(record.stackTrace, stackTrace);
    });

    test('onNativeLog maps level indices correctly and skips caller info', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          logLevel: PlayerLogLevel.debug,
          printCallerInfo: true,
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      // Mapping: 0:debug, 1:info, 2:warning, 3:error
      PlayerLogger.onNativeLog(0, 'NativeTag', 'debug msg');
      PlayerLogger.onNativeLog(3, 'NativeTag', 'error msg');
      PlayerLogger.onNativeLog(10, 'NativeTag', 'clamped msg');

      expect(mockOutput.records[0].level, PlayerLogLevel.debug);
      expect(mockOutput.records[0].caller, isNull);
      expect(mockOutput.records[1].level, PlayerLogLevel.error);
      expect(mockOutput.records[2].level, PlayerLogLevel.error);
    });

    test('captures caller info when enabled', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      PlayerLogger.info('test message');

      final record = mockOutput.records.last;
      expect(record.caller, isNotNull);
      // It should contain the test method name
      expect(record.caller, contains('main'));
    });

    test('derives tag from caller when manual tag is null', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      PlayerLogger.info('test message');

      final record = mockOutput.records.last;
      expect(record.tag, isNotNull);
      // Since it's called from 'main', tag should probably be 'main'
      expect(record.tag, contains('main'));
    });

    test('uses manual tag when provided', () {
      PlayerLogger.info('test message', tag: 'ManualTag');

      final record = mockOutput.records.last;
      expect(record.tag, 'ManualTag');
    });

    test('simplifies anonymous function names', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      // We can't easily mock the stack trace here without deep trickery,
      // but we can verify the regex logic by testing the internal _getCaller if it were accessible,
      // or just assume if this test is running inside an anonymous closure it works.
      // For now, let's just ensure the regex doesn't break things.
      void testClosure() {
        PlayerLogger.info('inside closure');
      }

      testClosure();
      final record = mockOutput.records.last;
      expect(record.caller, isNotNull);
      expect(record.caller, isNot(contains('<anonymous')));
    });

    test('skips caller info when disabled', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          printCallerInfo: false,
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      PlayerLogger.info('test message');

      final record = mockOutput.records.last;
      expect(record.caller, isNull);
    });
  });
}
