import 'package:better_player/src/logging/player_log_level.dart';

/// Immutable snapshot of a single log event.
class PlayerLogRecord {
  const PlayerLogRecord({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  final PlayerLogLevel level;
  final String message;
  final String tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  /// ISO-8601 formatted prefix used by outputs.
  String get isoTimestamp => timestamp.toIso8601String();

  @override
  String toString() =>
      '[$isoTimestamp] [${level.name.toUpperCase()}] [$tag] $message'
      '${error != null ? '\nError: $error' : ''}'
      '${stackTrace != null ? '\n$stackTrace' : ''}';
}
