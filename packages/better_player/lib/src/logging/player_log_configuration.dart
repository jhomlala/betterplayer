import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_output.dart';
import 'package:flutter/foundation.dart';

class PlayerLogConfiguration {
  const PlayerLogConfiguration({
    this.logLevel = PlayerLogLevel.info,
    this.alwaysLogErrors = true,
    this.outputs = const [ConsoleLogOutput()],
  });

  /// Minimum level that gets routed to outputs.
  /// Use PlayerLogLevel.none to silence all logs.
  final PlayerLogLevel logLevel;

  /// When true, error-level records always pass the level filter
  /// regardless of logLevel. Default: true.
  final bool alwaysLogErrors;

  /// The chain of outputs to write to. Defaults to ConsoleLogOutput.
  final List<PlayerLogOutput> outputs;

  /// Sensible default: debug verbosity in debug mode, info in profile/release.
  static PlayerLogConfiguration get defaultConfig =>
      const PlayerLogConfiguration(
        logLevel: kDebugMode ? PlayerLogLevel.debug : PlayerLogLevel.info,
      );
}
