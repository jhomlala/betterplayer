/// Constants used as keys for parameters passed within [PlayerEvent].
class PlayerEventConstants {
  /// Parameter key used to pass the duration of the media.
  static const String durationParameter = 'duration';

  /// Parameter key used to pass the current playback progress of the media.
  static const String progressParameter = 'progress';

  /// Parameter key used to indicate the buffered ranges of the media stream.
  static const String bufferedParameter = 'buffered';

  /// Parameter key used to communicate changes in audio volume.
  static const String volumeParameter = 'volume';

  /// Parameter key used to communicate changes in playback speed (e.g. 1.0x, 2.0x).
  static const String speedParameter = 'speed';

  /// Parameter key used to attach the currently loaded [PlayerDataSource] to an event.
  static const String dataSourceParameter = 'dataSource';

  /// HTTP Header key used specifically for DRM authentication tokens.
  static const String authorizationHeader = 'Authorization';
}
