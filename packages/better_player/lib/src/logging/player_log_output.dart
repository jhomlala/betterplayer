import 'dart:developer' as developer;

import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:meta/meta.dart';

/// Abstract base for all log output backends.
/// Implement this to add file logging, network logging, etc.
abstract class PlayerLogOutput {
  const PlayerLogOutput();

  /// Called once when the logger is set up.
  void init() {}

  /// Receives every log record that passes the level filter.
  void onLog(PlayerLogRecord record);

  /// Called when the logger is torn down (e.g. controller disposed).
  void destroy() {}
}

/// Default output: uses dart:developer log() for IDE/DevTools integration.
class ConsoleLogOutput extends PlayerLogOutput {
  const ConsoleLogOutput({this.usePrint = false});

  /// Whether to use standard print() instead of developer.log().
  /// Useful for CI or environments where developer.log() is not captured.
  final bool usePrint;

  static const _name = 'BetterPlayer';

  @visibleForTesting
  String formatMessage(PlayerLogRecord record) {
    var callerStr = record.caller;
    if (callerStr != null && callerStr.startsWith('${record.tag}.')) {
      callerStr = callerStr.substring(record.tag.length + 1);
    }
    return callerStr != null && callerStr.isNotEmpty
        ? '[$callerStr] ${record.message}'
        : record.message;
  }

  @override
  void onLog(PlayerLogRecord record) {
    final message = formatMessage(record);
    if (usePrint) {
      // ignore: avoid_print
      print(
        '[$_name/${record.tag}] [${record.level.name.toUpperCase()}] $message',
      );
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('StackTrace: ${record.stackTrace}');
      }
    } else {
      developer.log(
        message,
        time: record.timestamp,
        name: '$_name/${record.tag}',
        level: _toDevLevel(record.level),
        error: record.error,
        stackTrace: record.stackTrace,
      );
    }
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
