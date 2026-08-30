/// [PlayerLogLevel] defines the severity of the log messages.
enum PlayerLogLevel {
  /// [debug] — most verbose, used for internal troubleshooting.
  debug,

  /// [info] — general information about player state transitions.
  info,

  /// [warning] — potentially problematic events that don't stop playback.
  warning,

  /// [error] — critical issues that prevent playback or major features.
  error,

  /// [none] — disables all logs.
  none,
}
