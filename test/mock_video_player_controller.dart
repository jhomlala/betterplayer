import 'package:better_player/src/video_player/video_player.dart';

class MockVideoPlayerController extends VideoPlayerController {

  bool isLoopingState = false;

  @override
  Future<void> setLooping(bool looping) async {
    isLoopingState = looping;
  }
}
