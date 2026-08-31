import 'dart:async';
import 'package:better_player_platform_interface/src/models/buffering_configuration.dart';
import 'package:better_player_platform_interface/src/models/data_source.dart';
import 'package:better_player_platform_interface/src/models/video_event.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of better_player must implement.
///
/// Platform implementations should extend this class rather than implement it as `better_player`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [BetterPlayerPlatform] methods.
abstract class BetterPlayerPlatform extends PlatformInterface {
  /// Constructs a BetterPlayerPlatform.
  BetterPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static BetterPlayerPlatform _instance = _PlaceholderBetterPlayerPlatform();

  /// The default instance of [BetterPlayerPlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [BetterPlayerPlatform] when they
  /// register themselves.
  static BetterPlayerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [BetterPlayerPlatform] when they register themselves.
  static set instance(BetterPlayerPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Clears one video.
  Future<void> dispose(int? textureId) {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// Creates an instance of a video player and returns its textureId.
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
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

  Future<bool?> isPictureInPictureSupported(int? textureId) {
    throw UnimplementedError(
      'isPictureInPictureSupported() has not been implemented.',
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

  /// Register a callback to receive log records from the native layer.
  /// Only called when logLevel != none. When not called, native logCallback
  /// stays null — zero JNI/FFI overhead.
  Future<void> setupLogCallback(
    void Function(int levelIndex, String tag, String message)? callback,
  ) {
    throw UnimplementedError('setupLogCallback() has not been implemented.');
  }

  /// Returns a widget displaying the video with a given textureID.
  Widget buildView(int? textureId) {
    throw UnimplementedError('buildView() has not been implemented.');
  }
}

class _PlaceholderBetterPlayerPlatform extends BetterPlayerPlatform {}
