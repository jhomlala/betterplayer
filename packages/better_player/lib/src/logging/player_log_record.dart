import 'package:better_player/src/logging/player_log_level.dart';

/// Immutable snapshot of a single log event.
class PlayerLogRecord {
  const PlayerLogRecord({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
    this.caller,
    this.error,
    this.stackTrace,
  });

  final PlayerLogLevel level;
  final String message;
  final String tag;
  final DateTime timestamp;

  /// Optional caller information (e.g. "ClassName.methodName").
  final String? caller;
  final Object? error;
  final StackTrace? stackTrace;

  /// ISO-8601 formatted prefix used by outputs.
  String get isoTimestamp => timestamp.toIso8601String();

  @override
  String toString() =>
      '[$isoTimestamp] [${level.name.toUpperCase()}] [$tag] ${caller != null ? '[$caller] ' : ''}$message'
      '${error != null ? '\nError: $error' : ''}'
      '${stackTrace != null ? '\n$stackTrace' : ''}';
}
