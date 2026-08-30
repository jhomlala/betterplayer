import 'dart:developer' as developer;
import 'player_log_level.dart';
import 'player_log_record.dart';

/// Abstract base for all log output backends.
/// Implement this to add file logging, network logging, etc.
abstract class PlayerLogOutput {
  const PlayerLogOutput();

  /// Called once when the logger is set up.
  void init() {}

  /// Receives every log record that passes the level filter.
  void output(PlayerLogRecord record);

  /// Called when the logger is torn down (e.g. controller disposed).
  void destroy() {}
}

/// Default output: uses dart:developer log() for IDE/DevTools integration.
class ConsoleLogOutput extends PlayerLogOutput {
  const ConsoleLogOutput();

  static const _name = 'BetterPlayer';

  @override
  void output(PlayerLogRecord record) {
    developer.log(
      record.message,
      time: record.timestamp,
      name: '$_name/${record.tag}',
      level: _toDevLevel(record.level),
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }

  int _toDevLevel(PlayerLogLevel level) {
    switch (level) {
      case PlayerLogLevel.debug:
        return 500;
      case PlayerLogLevel.info:
        return 800;
      case PlayerLogLevel.warning:
        return 900;
      case PlayerLogLevel.error:
        return 1000;
      case PlayerLogLevel.none:
        return 0;
    }
  }
}
