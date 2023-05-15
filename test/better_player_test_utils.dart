import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';

import 'better_player_mock_controller.dart';
import 'mock_video_player_controller.dart';

class BetterPlayerTestUtils {
  static const String bugBuckBunnyVideoUrl =
      "https://workfields.backup-server222.lol/7d2473746a243c24296b63626f673129706f62636975295e4c7c60427f703e70755e51454b6d526d297573642930242a2475727463676b63744f62243c245f69737273646347686f6b63247b";
  static const String forBiggerBlazesUrl =
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";
  static const String elephantDreamStreamUrl =
      "http://cdn.theoplayer.com/video/elephants-dream/playlist.m3u8";

  static BetterPlayerMockController setupBetterPlayerMockController(
      {VideoPlayerController? controller}) {
    final mockController =
        BetterPlayerMockController(const BetterPlayerConfiguration());
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
