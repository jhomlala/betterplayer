import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';

import 'better_player_mock_controller.dart';
import 'mock_video_player_controller.dart';

class BetterPlayerTestUtils {
  static const String bugBuckBunnyVideoUrl =
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  static const String forBiggerBlazesUrl =
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";
  static const String elephantDreamStreamUrl =
      "http://cdn.theoplayer.com/video/elephants-dream/playlist.m3u8";

  static BetterPlayerMockController setupBetterPlayerMockController(
      {VideoPlayerController? controller}) {
    final mockController =
        BetterPlayerMockController(BetterPlayerConfiguration());
    if (controller != null) {
      mockController.videoPlayerController = controller;
    }
    return mockController;
  }

  static MockVideoPlayerController setupMockVideoPlayerControler() {
    final mockVideoPlayerController = MockVideoPlayerController();
    mockVideoPlayerController
        .setNetworkDataSource(BetterPlayerTestUtils.forBiggerBlazesUrl);
    return mockVideoPlayerController;
  }
}
