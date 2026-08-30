import 'dart:developer' as developer;
import 'package:better_player/better_player.dart';

class BetterPlayerLogger {
  BetterPlayerLogger._();

  static final BetterPlayerLogger instance = BetterPlayerLogger._();

  PlayerLogConfiguration _config = const PlayerLogConfiguration();

  void setup(PlayerLogConfiguration config) {
    _config = config;
  }

  void debug(String message, {String? breadcrumb}) {
    _log(PlayerLogLevel.debug, message, breadcrumb: breadcrumb);
  }

  void info(String message, {String? breadcrumb}) {
    _log(PlayerLogLevel.info, message, breadcrumb: breadcrumb);
  }

  void warning(String message, {String? breadcrumb}) {
    _log(PlayerLogLevel.warning, message, breadcrumb: breadcrumb);
  }

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
    if (_config.logLevel == PlayerLogLevel.none) return;

    final shouldLog =
        level.index >= _config.logLevel.index ||
        (_config.alwaysLogErrors && level == PlayerLogLevel.error);

    if (!shouldLog) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final breadcrumbPart = breadcrumb != null ? ' [$breadcrumb]' : '';
    final formattedMessage =
        '[$timestamp] [$levelName]$breadcrumbPart $message';

    developer.log(
      formattedMessage,
      name: 'BetterPlayer',
      level: _levelToDeveloperLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _levelToDeveloperLevel(PlayerLogLevel level) {
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
