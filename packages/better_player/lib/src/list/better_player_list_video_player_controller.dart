import 'package:better_player/better_player.dart';

///Controller of Better Player List Video Player.
class BetterPlayerListVideoPlayerController {
  BetterPlayerController? _betterPlayerController;

  /// Underlying [BetterPlayerController], or null if not yet attached.
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  void setVolume(double volume) {
    _betterPlayerController?.setVolume(volume);
  }

  void pause() {
    _betterPlayerController?.pause().catchError((_) {});
  }

  void play() {
    if (_betterPlayerController?.isVideoInitialized() ?? false) {
      _betterPlayerController?.play().catchError((_) {});
    }
  }

  void seekTo(Duration duration) {
    if (_betterPlayerController?.isVideoInitialized() ?? false) {
      _betterPlayerController?.seekTo(duration).catchError((_) {});
    }
  }

  // ignore: use_setters_to_change_properties
  void setBetterPlayerController(
    BetterPlayerController? betterPlayerController,
  ) {
    _betterPlayerController = betterPlayerController;
  }

  void setMixWithOthers(bool mixWithOthers) {
    _betterPlayerController?.setMixWithOthers(mixWithOthers);
  }
}
