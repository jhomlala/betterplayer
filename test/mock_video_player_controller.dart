import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';

class MockVideoPlayerController extends VideoPlayerController {
  MockVideoPlayerController() : super(autoCreate: false);

  bool isLoopingState = false;

  VideoPlayerValue videoPlayerValue =
      VideoPlayerValue(duration: const Duration());

  @override
  Future<void> play() async {
    value = videoPlayerValue.copyWith(isPlaying: true);
    return;
  }

  @override
  Future<void> pause() async {
    value = videoPlayerValue.copyWith(isPlaying: false);
    return;
  }

  @override
  Future<void> setLooping(bool looping) async {
    isLoopingState = looping;
  }

  void setBuffering(bool buffering) {
    value = videoPlayerValue.copyWith(isBuffering: buffering);
  }

  @override
  Future<void> setNetworkDataSource(String dataSource,
      {VideoFormat? formatHint,
      Map<String, String?>? headers,
      bool useCache = false,
      int? maxCacheSize,
      int? maxCacheFileSize,
      String? cacheKey,
      bool? showNotification,
      String? title,
      String? author,
      String? imageUrl,
      String? notificationChannelName,
      Duration? overriddenDuration,
      String? licenseUrl,
      String? certificateUrl,
      Map<String, String>? drmHeaders,
      String? activityName,
      String? clearKey}) async {}
}
