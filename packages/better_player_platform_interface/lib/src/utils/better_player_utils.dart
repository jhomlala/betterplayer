import 'package:flutter/foundation.dart';

class BetterPlayerUtils {
  /// Flag to enable/disable persistent logging. Can be toggled for E2E testing.
  static bool enableLogging = !kReleaseMode;

  /// Callback for logging. If set, this callback will be used for logging.
  static void Function(String)? logCallback;

  static void log(String logMessage) {
    if (logCallback != null) {
      logCallback!(logMessage);
      return;
    }
    if (enableLogging) {
      // ignore: avoid_print
      print('[BetterPlayer] $logMessage');
    }
  }
}
