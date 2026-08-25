import 'package:better_player_platform_interface/better_player_platform_interface.dart';

class BetterPlayerAndroid extends MethodChannelVideoPlayer {
  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerAndroid();
  }
}
