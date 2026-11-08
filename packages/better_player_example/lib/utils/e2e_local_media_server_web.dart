import 'package:better_player_example/constants.dart';

/// Web implementation of the E2E local media server.
class E2ELocalMediaServer {
  static bool get isRunning => false;

  static String get mp4Url => Constants.bugBuckBunnyVideoUrl;

  static String get secondaryMp4Url => Constants.forBiggerBlazesUrl;

  static String get hlsUrl => Constants.hlsTestStreamUrl;

  static String get errorUrl =>
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/404.mp4';

  static Future<void> ensureStarted({bool force = false}) async {}

  static Future<void> stop() async {}
}
