---
id: logging_configuration
title: Logging Configuration
---

# Logging Configuration

Better Player provides an extensible logging system centered around the `PlayerLogger`. It supports native-to-Dart log streaming from Android (ExoPlayer) and iOS (AVPlayer), automatic caller derivation, and custom output backends.

## Setup

The logging system is configured via `PlayerLoggerConfiguration`, which is passed to your `PlayerConfiguration`:

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

By default, Better Player uses `PlayerLoggerConfiguration.defaultConfig`, which sets the level to `debug` in debug mode and `info` in profile or release builds.

## Configuration Parameters

- **`logLevel`**: The minimum level required for a record to be sent to outputs. Use `PlayerLogLevel.none` to disable all logging.
- **`printCallerInfo`**: If `true`, the logger will automatically parse the stack trace to include the class and method name that triggered the log. (Default: `true`).
- **`outputs`**: A list of `PlayerLogOutput` instances. Defaults to `[ConsoleLogOutput()]`, which uses `dart:developer` for IDE and DevTools integration.

## Log Levels

Better Player uses the following hierarchy (from lowest to highest):

1.  `PlayerLogLevel.debug`: Fine-grained informational events that are most useful to debug an application.
2.  `PlayerLogLevel.info`: Informational messages that highlight the progress of the application at coarse-grained level.
3.  `PlayerLogLevel.warning`: Potentially harmful situations.
4.  `PlayerLogLevel.error`: Error events that might still allow the application to continue running.
5.  `PlayerLogLevel.none`: Special level used to turn off logging.

## Native Log Streaming

Better Player automatically captures logs from the native playback engines:
- **Android**: Internal events from ExoPlayer's `Player.Listener` and lifecycle logs.
- **iOS**: State changes via KVO (Key-Value Observing) on `AVPlayer` and lifecycle logs.

These logs are forwarded to Dart and routed through `PlayerLogger` with the `Android` or `iOS` tag, allowing you to see exactly what is happening in the native layer within your Flutter console or custom log backends.

## Custom Log Outputs

To send logs to external services like Sentry, Firebase Crashlytics, or a local file, extend the `PlayerLogOutput` class:

```dart
class CustomCrashlyticsOutput extends PlayerLogOutput {
  @override
  void onLog(PlayerLogRecord record) {
    if (record.level == PlayerLogLevel.error) {
       // Example: Crashlytics.instance.recordError(record.error, record.stackTrace);
    }
  }
}
```

### PlayerLogRecord Fields

Every log entry is encapsulated in a `PlayerLogRecord` containing:
- `level`: The `PlayerLogLevel`.
- `message`: The formatted log message.
- `tag`: The category (e.g., `BetterPlayerController`, `Android`, or a custom tag).
- `timestamp`: UTC `DateTime` when the log was created.
- `caller`: The derived calling method (if `printCallerInfo` is enabled).
- `error`: Optional error object.
- `stackTrace`: Optional stack trace.
