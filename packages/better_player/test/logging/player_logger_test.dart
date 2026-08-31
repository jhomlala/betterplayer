import 'package:better_player/src/logging/player_log_configuration.dart';
import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_output.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:better_player/src/logging/player_logger.dart';
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
        PlayerLogConfiguration(
          logLevel: PlayerLogLevel.debug,
          outputs: [mockOutput],
        ),
      );
    });

    test('setup() initializes and destroys outputs', () {
      expect(mockOutput.initCount, 1);

      final secondMockOutput = MockLogOutput();
      PlayerLogger.setup(
        PlayerLogConfiguration(
          outputs: [secondMockOutput],
        ),
      );

      expect(mockOutput.destroyCount, 1);
      expect(secondMockOutput.initCount, 1);
    });

    test('logs messages when level >= logLevel', () {
      PlayerLogger.setup(
        PlayerLogConfiguration(
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
        PlayerLogConfiguration(
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

    test('onNativeLog maps level indices correctly', () {
      mockOutput.records.clear();

      // Mapping: 0:debug, 1:info, 2:warning, 3:error
      PlayerLogger.onNativeLog(0, 'NativeTag', 'debug msg');
      PlayerLogger.onNativeLog(3, 'NativeTag', 'error msg');
      PlayerLogger.onNativeLog(
        10,
        'NativeTag',
        'clamped msg',
      ); // Should clamp to error

      expect(mockOutput.records[0].level, PlayerLogLevel.debug);
      expect(mockOutput.records[1].level, PlayerLogLevel.error);
      expect(mockOutput.records[2].level, PlayerLogLevel.error);
      expect(mockOutput.records[2].message, 'clamped msg');
    });
  });
}
