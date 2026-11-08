import 'dart:async';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';

/// Platform player interface for the Tizen media engine.
abstract class PlayerTizen {
  /// The native texture ID assigned to this player.
  int get textureId;

  /// Stream of playback events emitted by the native player.
  Stream<VideoEvent> get events;

  /// Releases native player resources and unregisters the texture.
  Future<void> dispose();

  /// Configures the media source to be played.
  Future<void> setDataSource(DataSource dataSource);

  /// Starts playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Sets audio volume between 0.0 and 1.0.
  Future<void> setVolume(double volume);

  /// Sets playback speed factor.
  Future<void> setSpeed(double speed);

  /// Seeks to the specified [position].
  Future<void> seekTo(Duration position);

  /// Retrieves the current playback position.
  Future<Duration> getPosition();

  /// Configures whether playback should loop when finished.
  Future<void> setLooping({required bool looping});

  /// Configures track parameters for adaptive streams.
  Future<void> setTrackParameters({
    required int width,
    required int height,
    required int bitrate,
  });
}
