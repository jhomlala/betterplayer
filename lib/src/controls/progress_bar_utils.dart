import 'package:better_player/better_player.dart';

import '../video_player/video_player.dart';

class ProgressbarUtils {
  ProgressbarUtils._();

  static bool canShowProgressbar(
    BetterPlayerControlsConfiguration controlsConfiguration,
    BetterPlayerController betterPlayerController,
    VideoPlayerController? videoPlayerController,
  ) {
    if (!controlsConfiguration.enableProgressBar) return false;
    if (!betterPlayerController.isLiveStream()) return true;

    final Duration contentDuration = videoPlayerController?.value.duration ?? Duration.zero;
    return contentDuration >= controlsConfiguration.minimumDurationToEnableProgressbar;
  }
}
