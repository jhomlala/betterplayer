import 'dart:async';
import 'package:better_player_platform_interface/src/method_channel_video_player.dart';
import 'package:better_player_platform_interface/src/models/better_player_buffering_configuration.dart';
import 'package:better_player_platform_interface/src/models/data_source.dart';
import 'package:better_player_platform_interface/src/models/video_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of better_player must implement.
///
/// Platform implementations should extend this class rather than implement it as `better_player`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [VideoPlayerPlatform] methods.
abstract class VideoPlayerPlatform extends PlatformInterface {
  /// Constructs a VideoPlayerPlatform.
  VideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerPlatform _instance = MethodChannelVideoPlayer();

  /// The default instance of [VideoPlayerPlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [VideoPlayerPlatform] when they
  /// register themselves.
  ///
  /// Defaults to [MethodChannelVideoPlayer].
  static VideoPlayerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [VideoPlayerPlatform] when they register themselves.
  static set instance(VideoPlayerPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Initializes the platform interface and disposes all existing players.
  ///
  /// This method is called when the plugin is first initialized
  /// and on every full restart.
  Future<void> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Clears one video.
  Future<void> dispose(int? textureId) {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// Creates an instance of a video player and returns its textureId.
  Future<int?> create({
    BetterPlayerBufferingConfiguration? bufferingConfiguration,
  }) {
    throw UnimplementedError('create() has not been implemented.');
  }

  /// Pre-caches a video.
  Future<void> preCache(DataSource dataSource, int preCacheSize) {
    throw UnimplementedError('preCache() has not been implemented.');
  }

  /// Pre-caches a video.
  Future<void> stopPreCache(String url, String? cacheKey) {
    throw UnimplementedError('stopPreCache() has not been implemented.');
  }

  /// Set data source of video.
  Future<void> setDataSource(int? textureId, DataSource dataSource) {
    throw UnimplementedError('setDataSource() has not been implemented.');
  }

  /// Returns a Stream of [VideoEvent]s.
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    throw UnimplementedError('videoEventsFor() has not been implemented.');
  }

  /// Sets the looping attribute of the video.
  Future<void> setLooping(int? textureId, bool looping) {
    throw UnimplementedError('setLooping() has not been implemented.');
  }

  /// Starts the video playback.
  Future<void> play(int? textureId) {
    throw UnimplementedError('play() has not been implemented.');
  }

  /// Stops the video playback.
  Future<void> pause(int? textureId) {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Sets the volume to a range between 0.0 and 1.0.
  Future<void> setVolume(int? textureId, double volume) {
    throw UnimplementedError('setVolume() has not been implemented.');
  }

  /// Sets the video speed to a range between 0.0 and 2.0
  Future<void> setSpeed(int? textureId, double speed) {
    throw UnimplementedError('setSpeed() has not been implemented.');
  }

  /// Sets the video track parameters (used to select quality of the video)
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) {
    throw UnimplementedError('setTrackParameters() has not been implemented.');
  }

  /// Sets the video position to a [Duration] from the start.
  Future<void> seekTo(int? textureId, Duration? position) {
    throw UnimplementedError('seekTo() has not been implemented.');
  }

  /// Gets the video position as [Duration] from the start.
  Future<Duration> getPosition(int? textureId) {
    throw UnimplementedError('getPosition() has not been implemented.');
  }

  /// Gets the video position as [DateTime].
  Future<DateTime?> getAbsolutePosition(int? textureId) {
    throw UnimplementedError('getAbsolutePosition() has not been implemented.');
  }

  ///Enables PiP mode.
  Future<void> enablePictureInPicture(
    int? textureId,
    double? top,
    double? left,
    double? width,
    double? height,
  ) {
    throw UnimplementedError(
      'enablePictureInPicture() has not been implemented.',
    );
  }

  ///Disables PiP mode.
  Future<void> disablePictureInPicture(int? textureId) {
    throw UnimplementedError(
      'disablePictureInPicture() has not been implemented.',
    );
  }

  Future<bool?> isPictureInPictureEnabled(int? textureId) {
    throw UnimplementedError(
      'isPictureInPictureEnabled() has not been implemented.',
    );
  }

  Future<void> setAudioTrack(int? textureId, String? name, int? index) {
    throw UnimplementedError('setAudio() has not been implemented.');
  }

  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) {
    throw UnimplementedError('setMixWithOthers() has not been implemented.');
  }

  Future<void> clearCache() {
    throw UnimplementedError('clearCache() has not been implemented.');
  }

  /// Returns a widget displaying the video with a given textureID.
  Widget buildView(int? textureId) {
    throw UnimplementedError('buildView() has not been implemented.');
  }
}
