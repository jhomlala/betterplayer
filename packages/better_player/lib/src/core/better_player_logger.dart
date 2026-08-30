import 'dart:developer' as developer;
import 'package:better_player/src/configuration/player_log_configuration.dart';
import 'package:better_player/src/configuration/player_log_level.dart';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';

/// Singleton logger for Better Player.
class BetterPlayerLogger {
  BetterPlayerLogger._();

  static final BetterPlayerLogger _instance = BetterPlayerLogger._();

  /// The singleton instance of [BetterPlayerLogger].
  static BetterPlayerLogger get instance => _instance;

  PlayerLogConfiguration _config = PlayerLogConfiguration.defaultConfig;

  /// Setup the logger with the provided configuration.
  static void setup(PlayerLogConfiguration config) => _instance._setup(config);

  void _setup(PlayerLogConfiguration config) {
    _config = config;
    BetterPlayerUtils.logHandler = info;
  }

  /// Log a debug message.
  static void debug(String message, {String? breadcrumb}) {
    _instance._log(PlayerLogLevel.debug, message, breadcrumb: breadcrumb);
  }

  /// Log an info message.
  static void info(String message, {String? breadcrumb}) {
    _instance._log(PlayerLogLevel.info, message, breadcrumb: breadcrumb);
  }

  /// Log a warning message.
  static void warning(String message, {String? breadcrumb}) {
    _instance._log(PlayerLogLevel.warning, message, breadcrumb: breadcrumb);
  }

  /// Log an error message.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? breadcrumb,
  }) {
    _instance._log(
      PlayerLogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      breadcrumb: breadcrumb,
    );
  }

  void _log(
    PlayerLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? breadcrumb,
  }) {
    if (level == PlayerLogLevel.none) return;

    final shouldLog =
        level.index >= _config.logLevel.index ||
        (_config.alwaysLogErrors && level == PlayerLogLevel.error);

    if (!shouldLog) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelLabel = level.name.toUpperCase();
    final breadcrumbLabel = breadcrumb != null
        ? ' [BetterPlayer/$breadcrumb]'
        : ' [BetterPlayer]';

    final formattedMessage =
        '[$timestamp] [$levelLabel]$breadcrumbLabel $message';

    developer.log(
      formattedMessage,
      name: 'BetterPlayer',
      level: _mapToDeveloperLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _mapToDeveloperLevel(PlayerLogLevel level) {
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

/// Shorthand for [BetterPlayerLogger].
typedef PlayerLogger = BetterPlayerLogger;
