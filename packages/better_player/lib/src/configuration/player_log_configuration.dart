import 'package:better_player/src/configuration/player_log_level.dart';
import 'package:flutter/foundation.dart';

/// [PlayerLogConfiguration] allows to configure the logging system of
/// Better Player.
class PlayerLogConfiguration {
  const PlayerLogConfiguration({
    this.logLevel = PlayerLogLevel.info,
    this.alwaysLogErrors = true,
  });

  /// The minimum log level to display.
  final PlayerLogLevel logLevel;

  /// Whether to always log errors, even if [logLevel] is [PlayerLogLevel.none].
  final bool alwaysLogErrors;

  /// Default configuration for the logger.
  /// In debug mode, [logLevel] is [PlayerLogLevel.debug].
  /// In release mode, [logLevel] is [PlayerLogLevel.info].
  static PlayerLogConfiguration get defaultConfig =>
      const PlayerLogConfiguration(
        logLevel: kDebugMode ? PlayerLogLevel.debug : PlayerLogLevel.info,
      );
}
