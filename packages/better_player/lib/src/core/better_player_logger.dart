import 'dart:developer' as developer;
import 'package:better_player/src/configuration/player_log_configuration.dart';
import 'package:better_player/src/configuration/player_log_level.dart';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';

/// Singleton logger for Better Player.
class BetterPlayerLogger {
  BetterPlayerLogger._();

  static final BetterPlayerLogger instance = BetterPlayerLogger._();

  PlayerLogConfiguration _config = PlayerLogConfiguration.defaultConfig;

  /// Setup the logger with the provided configuration.
  void setup(PlayerLogConfiguration config) {
    _config = config;
    BetterPlayerUtils.logHandler = info;
  }

  /// Log a debug message.
  void debug(String message, {String? breadcrumb}) {
    _log(PlayerLogLevel.debug, message, breadcrumb: breadcrumb);
  }

  /// Log an info message.
  void info(String message, {String? breadcrumb}) {
    _log(PlayerLogLevel.info, message, breadcrumb: breadcrumb);
  }

  /// Log a warning message.
  void warning(String message, {String? breadcrumb}) {
    _log(PlayerLogLevel.warning, message, breadcrumb: breadcrumb);
  }

  /// Log an error message.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? breadcrumb,
  }) {
    _log(
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
