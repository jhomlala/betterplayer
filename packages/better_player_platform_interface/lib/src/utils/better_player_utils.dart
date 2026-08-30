import 'package:flutter/foundation.dart';

class BetterPlayerUtils {
  /// Flag to enable/disable persistent logging. Can be toggled for E2E testing.
  static bool enableLogging = !kReleaseMode;

  /// Custom log handler. If set, this handler will be used instead of [print].
  static void Function(String message)? logHandler;

  static void log(String logMessage) {
    if (logHandler != null) {
      logHandler!(logMessage);
      return;
    }
    if (enableLogging) {
      // ignore: avoid_print
      print('[BetterPlayer] $logMessage');
    }
  }
}
