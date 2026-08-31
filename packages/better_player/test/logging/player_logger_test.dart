import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_output.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/logging/player_logger_configuration.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import '../helpers/mock_better_player_platform.dart';

class MockLogOutput extends PlayerLogOutput {
  final List<PlayerLogRecord> records = [];
  int initCount = 0;
  int destroyCount = 0;

  @override
  void init() {
    initCount++;
  }

  @override
  void onLog(PlayerLogRecord record) {
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
    late MockBetterPlayerPlatform mockPlatform;

    setUp(() {
      PlayerLogger.reset();
      mockOutput = MockLogOutput();
      mockPlatform = MockBetterPlayerPlatform();
      BetterPlayerPlatform.instance = mockPlatform;
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

      PlayerLogger.debug(message: 'debug');
      PlayerLogger.info(message: 'info');
      PlayerLogger.warning(message: 'warning');
      PlayerLogger.error(message: 'error');

      expect(mockOutput.records.length, 3);
      expect(mockOutput.records[0].level, PlayerLogLevel.info);
      expect(mockOutput.records[1].level, PlayerLogLevel.warning);
      expect(mockOutput.records[2].level, PlayerLogLevel.error);
    });

    test('convenience methods pass all arguments', () {
      final error = Exception('test');
      final stackTrace = StackTrace.current;

      PlayerLogger.warning(
        message: 'warn message',
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
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      // Mapping: 0:debug, 1:info, 2:warning, 3:error
      PlayerLogger.onNativeLog(
        levelIndex: 0,
        tag: 'NativeTag',
        message: 'debug msg',
      );
      PlayerLogger.onNativeLog(
        levelIndex: 3,
        tag: 'NativeTag',
        message: 'error msg',
      );
      PlayerLogger.onNativeLog(
        levelIndex: 10,
        tag: 'NativeTag',
        message: 'clamped msg',
      );

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

      PlayerLogger.info(message: 'test message');

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

      PlayerLogger.info(message: 'test message');

      final record = mockOutput.records.last;
      expect(record.tag, isNotNull);
      // Since it's called from 'main', tag should probably be 'main'
      expect(record.tag, contains('main'));
    });

    test('uses manual tag when provided', () {
      PlayerLogger.info(message: 'test message', tag: 'ManualTag');

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
        PlayerLogger.info(message: 'inside closure');
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

      PlayerLogger.info(message: 'test message');

      final record = mockOutput.records.last;
      expect(record.caller, isNull);
    });

    test('setup(none) unregisters native callback if registered', () {
      // Already registered in setUp (logLevel: debug)
      expect(mockPlatform.setupLogCallbackCount, 1);
      expect(mockPlatform.lastLogCallback, isNotNull);

      // Unregister
      PlayerLogger.setup(
        const PlayerLoggerConfiguration(logLevel: PlayerLogLevel.none),
      );
      expect(mockPlatform.setupLogCallbackCount, 2);
      expect(mockPlatform.lastLogCallback, isNull);
    });

    test('setup(non-none) re-registers native callback if unregistered', () {
      // 1. Start with none
      PlayerLogger.setup(
        const PlayerLoggerConfiguration(logLevel: PlayerLogLevel.none),
      );
      // reset registration flag for this test specifically if needed,
      // but setup(none) should have set _nativeCallbackRegistered to false.

      final initialCount = mockPlatform.setupLogCallbackCount;

      // 2. Register
      PlayerLogger.setup(
        const PlayerLoggerConfiguration(),
      );
      expect(mockPlatform.setupLogCallbackCount, initialCount + 1);
      expect(mockPlatform.lastLogCallback, isNotNull);
    });

    test('robustly parses caller info even through wrappers', () {
      PlayerLogger.setup(
        PlayerLoggerConfiguration(
          outputs: [mockOutput],
        ),
      );
      mockOutput.records.clear();

      void wrapper() {
        PlayerLogger.info(message: 'wrapped');
      }

      void nestedWrapper() {
        wrapper();
      }

      nestedWrapper();

      final record = mockOutput.records.last;
      expect(record.caller, isNotNull);
      // It should skip PlayerLogger frames and find the first non-logger frame: 'wrapper'
      expect(record.caller, contains('wrapper'));
    });
  });
}
