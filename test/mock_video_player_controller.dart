import 'package:better_player/src/video_player/video_player.dart';

class MockVideoPlayerController extends VideoPlayerController {
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
}
