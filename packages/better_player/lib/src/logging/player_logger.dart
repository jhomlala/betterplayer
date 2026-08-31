import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:better_player/src/logging/player_logger_configuration.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:meta/meta.dart';

/// Logger for Better Player.
@internal
class PlayerLogger {
  PlayerLogger._();

  static PlayerLoggerConfiguration _config =
      PlayerLoggerConfiguration.defaultConfig;
  static bool _nativeCallbackRegistered = false;

  /// Resets the logger state.
  @visibleForTesting
  static void reset() {
    _config = PlayerLoggerConfiguration.defaultConfig;
    _nativeCallbackRegistered = false;
  }

  /// Apply configuration and initialise outputs.
  static void setup(PlayerLoggerConfiguration config) {
    for (final output in _config.outputs) {
      output.destroy();
    }
    _config = config;
    for (final output in _config.outputs) {
      output.init();
    }

    final shouldRegisterNative = config.logLevel != PlayerLogLevel.none;
    if (shouldRegisterNative != _nativeCallbackRegistered) {
      try {
        BetterPlayerPlatform.instance.setupLogCallback(
          shouldRegisterNative ? onNativeLog : null,
        );
        _nativeCallbackRegistered = shouldRegisterNative;
      } catch (e) {
        // Native logging not implemented on this platform yet
      }
    }
  }

  static void debug({required String message, String? tag}) =>
      _log(level: PlayerLogLevel.debug, message: message, tag: tag);

  static void info({required String message, String? tag}) =>
      _log(level: PlayerLogLevel.info, message: message, tag: tag);

  static void warning({
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    level: PlayerLogLevel.warning,
    message: message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  static void error({
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    level: PlayerLogLevel.error,
    message: message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Entry point for native → Dart log forwarding.
  static void onNativeLog(int levelIndex, String tag, String message) {
    // Clamp to valid loggable levels (exclude 'none')
    final clampedIndex = levelIndex.clamp(0, PlayerLogLevel.values.length - 2);
    final level = PlayerLogLevel.values[clampedIndex];
    _log(
      level: level,
      message: message,
      tag: tag,
      includeCaller: false,
    );
  }

  static void _log({
    required PlayerLogLevel level,
    required String message,
    String? tag,
    bool includeCaller = true,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final shouldLog =
        level.index >= _config.logLevel.index ||
        (_config.alwaysLogErrors && level == PlayerLogLevel.error);
    if (!shouldLog) return;

    String? caller;
    if (includeCaller && _config.printCallerInfo) {
      caller = _getCaller();
    }

    final effectiveTag = tag ?? _deriveTag(caller) ?? 'BetterPlayer';

    final record = PlayerLogRecord(
      level: level,
      message: message,
      tag: effectiveTag,
      timestamp: DateTime.now().toUtc(),
      caller: caller,
      error: error,
      stackTrace: stackTrace,
    );

    for (final output in _config.outputs) {
      output.onLog(record);
    }
  }

  /// Derives a tag from the caller info (e.g. "BetterPlayerController.setup" -> "BetterPlayerController").
  static String? _deriveTag(String? caller) {
    if (caller == null) return null;
    final parts = caller.split(RegExp('[./]'));
    return parts.first;
  }

  /// Parses the stack trace to find the immediate caller of the logger.
  static String? _getCaller() {
    try {
      final lines = StackTrace.current.toString().split('\n');
      for (final line in lines) {
        if (line.isEmpty) continue;
        // Skip frames belonging to this logger to find the actual caller
        if (line.contains('PlayerLogger.')) continue;

        // Format: #3      ClassName.methodName (package:...)
        // Use non-greedy match until we hit a space followed by '(' to handle spaces in names (like <anonymous closure>)
        final match = RegExp(r'#\d+\s+(.+?)(?:\s+\(|$)').firstMatch(line);
        var caller = match?.group(1);

        // Simplify constructors (ClassName.new or ClassName/new -> ClassName)
        if (caller != null) {
          caller = caller.replaceAll(RegExp(r'[./]new$'), '');
          // Strip anonymous function suffixes (non-greedy to avoid stripping subsequent names)
          caller = caller.replaceAll(RegExp(r'\.<anonymous[^>]*>'), '');
          return caller;
        }
      }
    } catch (_) {
      // Fallback to null if parsing fails
    }
    return null;
  }
}
