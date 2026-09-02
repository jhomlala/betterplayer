import 'package:better_player/src/logging/player_log_level.dart';
import 'package:better_player/src/logging/player_log_output.dart';
import 'package:flutter/foundation.dart';

class PlayerLoggerConfiguration {
  const PlayerLoggerConfiguration({
    this.logLevel = PlayerLogLevel.info,
    this.printCallerInfo = true,
    this.outputs = const [ConsoleLogOutput()],
  });

  /// Minimum level that gets routed to outputs.
  /// Use PlayerLogLevel.none to silence all logs.
  final PlayerLogLevel logLevel;

  /// Whether to automatically include the calling class/method name in logs.
  /// Note: enabling this has a small performance cost due to stack trace parsing.
  final bool printCallerInfo;

  /// The chain of outputs to write to. Defaults to ConsoleLogOutput.
  final List<PlayerLogOutput> outputs;

  /// Sensible default: debug verbosity in debug mode, info in profile/release.
  static PlayerLoggerConfiguration get defaultConfig =>
      const PlayerLoggerConfiguration(
        logLevel: kDebugMode ? PlayerLogLevel.debug : PlayerLogLevel.info,
      );
}
