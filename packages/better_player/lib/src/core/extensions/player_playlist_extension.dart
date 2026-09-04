part of '../better_player_controller.dart';

extension PlayerPlaylistExtension on BetterPlayerController {
  ///Start timer which will trigger next video. Used in playlist. Do not use
  ///manually.
  void startNextVideoTimer() {
    if (_nextVideoTimer == null) {
      if (betterPlayerPlaylistConfiguration == null) {
        PlayerLogger.warning(
          message: 'BetterPlayerPlaylistConfiguration has not been set!',
          textureId: textureId,
        );
        throw StateError(
          'BetterPlayerPlaylistConfiguration has not been set!',
        );
      }

      _nextVideoTime =
          betterPlayerPlaylistConfiguration!.nextVideoDelay.inSeconds;
      _nextVideoTimeStreamController.add(_nextVideoTime);
      if (_nextVideoTime == 0) {
        return;
      }

      _nextVideoTimer = Timer.periodic(const Duration(milliseconds: 1000), (
        timer,
      ) async {
        if (_nextVideoTime == 1) {
          timer.cancel();
          _nextVideoTimer = null;
        }
        if (_nextVideoTime != null) {
          _nextVideoTime = _nextVideoTime! - 1;
        }
        _nextVideoTimeStreamController.add(_nextVideoTime);
      });
    }
  }

  ///Cancel next video timer. Used in playlist. Do not use manually.
  void cancelNextVideoTimer() {
    _nextVideoTime = null;
    _nextVideoTimeStreamController.add(_nextVideoTime);
    _nextVideoTimer?.cancel();
    _nextVideoTimer = null;
  }

  ///Play next video form playlist. Do not use manually.
  void playNextVideo() {
    _nextVideoTime = 0;
    _nextVideoTimeStreamController.add(_nextVideoTime);
    _postEvent(PlayerEvent(PlayerEventType.changedPlaylistItem));
    cancelNextVideoTimer();
  }
}
