import 'package:better_player/src/logging/player_log_configuration.dart';
import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_record.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';

class BetterPlayerLogger {
  BetterPlayerLogger._();
  static final BetterPlayerLogger instance = BetterPlayerLogger._();

  PlayerLogConfiguration _config = PlayerLogConfiguration.defaultConfig;
  bool _nativeCallbackRegistered = false;

  /// Apply configuration and initialise outputs.
  void setup(PlayerLogConfiguration config) {
    for (final output in _config.outputs) {
      output.destroy();
    }
    _config = config;
    for (final output in _config.outputs) {
      output.init();
    }

    if (!_nativeCallbackRegistered && config.logLevel != PlayerLogLevel.none) {
      try {
        BetterPlayerPlatform.instance.setupLogCallback(onNativeLog);
        _nativeCallbackRegistered = true;
      } catch (e) {
        // Native logging not implemented on this platform yet
      }
    }
  }

  void debug(String message, {String tag = 'BetterPlayer'}) =>
      _log(PlayerLogLevel.debug, message, tag: tag);

  void info(String message, {String tag = 'BetterPlayer'}) =>
      _log(PlayerLogLevel.info, message, tag: tag);

  void warning(
    String message, {
    String tag = 'BetterPlayer',
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    PlayerLogLevel.warning,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  void error(
    String message, {
    String tag = 'BetterPlayer',
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    PlayerLogLevel.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Entry point for native → Dart log forwarding.
  void onNativeLog(int levelIndex, String tag, String message) {
    final clampedIndex = levelIndex.clamp(0, PlayerLogLevel.values.length - 1);
    final level = PlayerLogLevel.values[clampedIndex];
    _log(level, message, tag: tag);
  }

  void _log(
    PlayerLogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final shouldLog =
        level.index >= _config.logLevel.index ||
        (_config.alwaysLogErrors && level == PlayerLogLevel.error);
    if (!shouldLog) return;

    final record = PlayerLogRecord(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now().toUtc(),
      error: error,
      stackTrace: stackTrace,
    );

    for (final output in _config.outputs) {
      output.output(record);
    }
  }
}
