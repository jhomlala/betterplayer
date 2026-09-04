part of '../better_player_controller.dart';

extension PlayerPlaybackExtension on BetterPlayerController {
  ///Start video playback. Play will be triggered only if current lifecycle state
  ///is resumed.
  Future<void> play() async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    if (_playbackState.appLifecycleState == AppLifecycleState.resumed) {
      await _engine!.play();
      _playbackState = _playbackState.copyWith(
        hasCurrentDataSourceStarted: true,
      );
      _playbackState = _playbackState.copyWith(
        wasPlayingBeforePause: false,
      );
      _postEvent(PlayerEvent(PlayerEventType.play));
      _postControllerEvent(PlayerControllerEvent.play);
    }
  }

  ///Enables/disables looping (infinity playback) mode.
  Future<void> setLooping(bool looping) async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    await _engine!.setLooping(looping);
  }

  ///Stop video playback.
  Future<void> pause() async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }

    await _engine!.pause();
    _postEvent(PlayerEvent(PlayerEventType.pause));
  }

  ///Move player to specific position/moment of the video.
  Future<void> seekTo(Duration moment) async {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    if (!(_engine?.value.initialized ?? false)) {
      throw StateError('The video has not been initialized yet.');
    }

    await _engine!.seekTo(moment);

    _postEvent(
      PlayerEvent(
        PlayerEventType.seekTo,
        parameters: <String, dynamic>{
          PlayerEventConstants.durationParameter: moment,
        },
      ),
    );

    final currentDuration = _engine!.value.duration;
    if (currentDuration == null) {
      return;
    }
    if (moment > currentDuration) {
      _postEvent(PlayerEvent(PlayerEventType.finished));
    } else {
      cancelNextVideoTimer();
    }
  }

  ///Set volume of player. Allows values from 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume must be between 0.0 and 1.0');
    }
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    await _engine!.setVolume(volume);
    _postEvent(
      PlayerEvent(
        PlayerEventType.setVolume,
        parameters: <String, dynamic>{
          PlayerEventConstants.volumeParameter: volume,
        },
      ),
    );
  }

  ///Set playback speed of video. Allows to set speed value between 0 and 2.
  Future<void> setSpeed(double speed) async {
    if (speed <= 0 || speed > 2) {
      throw ArgumentError('Speed must be between 0 and 2');
    }
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    await _engine?.setSpeed(speed);
    _postEvent(
      PlayerEvent(
        PlayerEventType.setSpeed,
        parameters: <String, dynamic>{
          PlayerEventConstants.speedParameter: speed,
        },
      ),
    );
  }

  ///Flag which determines whenever player is playing or not.
  bool? isPlaying() {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    return _engine!.value.isPlaying;
  }

  ///Flag which determines whenever player is loading video data or not.
  bool? isBuffering() {
    if (_engine == null) {
      throw StateError('The data source has not been initialized');
    }
    return _engine!.value.isBuffering;
  }
}
