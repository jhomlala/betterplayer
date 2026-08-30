import 'package:better_player/src/configuration/player_log_level.dart';
import 'package:flutter/foundation.dart';

class PlayerLogConfiguration {
  const PlayerLogConfiguration({
    this.logLevel = PlayerLogLevel.info,
    this.alwaysLogErrors = true,
  });

  final PlayerLogLevel logLevel;
  final bool alwaysLogErrors;

  static PlayerLogConfiguration get defaultConfig =>
      const PlayerLogConfiguration(
        logLevel: kDebugMode ? PlayerLogLevel.debug : PlayerLogLevel.info,
      );
}
