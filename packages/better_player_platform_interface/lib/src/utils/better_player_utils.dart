import 'package:flutter/foundation.dart';

class BetterPlayerUtils {
  /// Flag to enable/disable persistent logging. Can be toggled for E2E testing.
  static bool enableLogging = !kReleaseMode;

  static void log(String logMessage) {
    if (enableLogging) {
      // ignore: avoid_print
      print('[BetterPlayer] $logMessage');
    }
  }
}
