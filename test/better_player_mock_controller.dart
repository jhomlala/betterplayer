import 'package:better_player/better_player.dart';

class BetterPlayerMockController extends BetterPlayerController {
  BetterPlayerMockController(
      BetterPlayerConfiguration betterPlayerConfiguration)
      : super(betterPlayerConfiguration);

  bool isPlayingState = false;

  @override
  bool? isPlaying() {
    return isPlayingState;
  }

  @override
  Future<void> play() async {
    isPlayingState = true;
    return;
  }

  @override
  Future<void> pause() async {
    isPlayingState = false;
    return;
  }
}
