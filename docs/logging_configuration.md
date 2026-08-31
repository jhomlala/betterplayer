---
id: logging_configuration
title: Logging Configuration
---

# Logging Configuration

Better Player provides an extensible logging system with `PlayerLogger`. It supports native-to-Dart log streaming (from Android ExoPlayer and iOS AVPlayer) and automatic caller/tag derivation, making it easier to track what the player is doing under the hood.

## Setup

You can configure the logging system by passing a `PlayerLoggerConfiguration` to your `PlayerConfiguration`:

```dart
import 'package:better_player/better_player.dart';

var playerConfiguration = PlayerConfiguration(
  playerLogConfiguration: PlayerLoggerConfiguration(
    logLevel: PlayerLogLevel.debug,
    printCallerInfo: true,
    outputs: [ConsoleLogOutput()],
  ),
);
```

By default, Better Player uses a sensible default configuration which prints `debug` logs in debug mode and `info` logs in profile/release builds.

## Configuration Parameters

- `logLevel`: The minimum level that gets routed to outputs. Use `PlayerLogLevel.none` to silence all logs.
- `printCallerInfo`: Whether to automatically include the calling class/method name in logs. Note: enabling this has a small performance cost due to stack trace parsing. (Default: `true`).
- `outputs`: The chain of outputs to write to. Defaults to `ConsoleLogOutput` (which uses `dart:developer` under the hood for IDE/DevTools integration).

## Custom Log Outputs

You can easily create custom log outputs by extending `PlayerLogOutput`. This is useful if you want to write logs to a file, send them to a remote crash reporting tool (like Sentry or Crashlytics), or use a different internal logging library.

```dart
class CustomCrashlyticsOutput extends PlayerLogOutput {
  @override
  void init() {
    // Setup 
  }

  @override
  void onLog(PlayerLogRecord record) {
    if (record.level == PlayerLogLevel.error) {
       // Report error to crashlytics
       // Crashlytics.instance.recordError(record.error, record.stackTrace);
    }
  }

  @override
  void destroy() {
    // Cleanup
  }
}
```

Simply pass your custom output to the configuration:

```dart
playerLogConfiguration: PlayerLoggerConfiguration(
  outputs: [
    ConsoleLogOutput(),
    CustomCrashlyticsOutput(),
  ],
)
```
