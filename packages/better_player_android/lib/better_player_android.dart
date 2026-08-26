import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';

class BetterPlayerAndroid extends MethodChannelVideoPlayer {
  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerAndroid();
  }

  @override
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }
}
