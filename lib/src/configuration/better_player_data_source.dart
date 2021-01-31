// Project imports:
import 'package:better_player/src/configuration/better_player_data_source_type.dart';
import 'package:better_player/src/configuration/better_player_notification_configuration.dart';
import 'package:better_player/src/configuration/better_player_video_format.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';

import 'better_player_cache_configuration.dart';

class BetterPlayerDataSource {
  ///Type of source of video
  final BetterPlayerDataSourceType type;

  ///Url of the video
  final String url;

  ///Subtitles configuration
  final List<BetterPlayerSubtitlesSource> subtitles;

  ///Flag to determine if current data source is live stream
  final bool liveStream;

  /// Custom headers for player
  final Map<String, String> headers;

  ///Should player use hls subtitles
  final bool useHlsSubtitles;

  ///Should player use hls tracks
  final bool useHlsTracks;

  ///List of strings that represents tracks names.
  ///If empty, then better player will choose name based on track parameters
  final List<String> hlsTrackNames;

  ///Optional, alternative resolutions for non-hls video. Used to setup
  ///different qualities for video.
  ///Data should be in given format:
  ///{"360p": "url", "540p": "url2" }
  final Map<String, String> resolutions;

  ///Optional cache configuration, used only for network data sources
  final BetterPlayerCacheConfiguration cacheConfiguration;

  ///List of bytes, used only in memory player
  final List<int> bytes;

  ///Configuration of remote controls notification
  final BetterPlayerNotificationConfiguration notificationConfiguration;

  ///Duration which will be returned instead of original duration
  final Duration overriddenDuration;

  ///Video format hint when data source url has not valid extension.
  final BetterPlayerVideoFormat videoFormat;

  BetterPlayerDataSource(
    this.type,
    this.url, {
    this.bytes,
    this.subtitles,
    this.liveStream = false,
    this.headers,
    this.useHlsSubtitles = true,
    this.useHlsTracks = true,
    this.hlsTrackNames,
    this.resolutions,
    this.cacheConfiguration,
    this.notificationConfiguration =
        const BetterPlayerNotificationConfiguration(showNotification: false),
    this.overriddenDuration,
    this.videoFormat,
  }) : assert(
            ((type == BetterPlayerDataSourceType.network ||
                        type == BetterPlayerDataSourceType.file) &&
                    url != null) ||
                (type == BetterPlayerDataSourceType.memory &&
                    bytes?.isNotEmpty == true),
            "Url can't be null in network or file data source | bytes can't be null when using memory data source");

  ///Factory method to build network data source which uses url as data source
  ///Bytes parameter is not used in this data source.
  factory BetterPlayerDataSource.network(
    String url, {
    List<BetterPlayerSubtitlesSource> subtitles,
    bool liveStream,
    Map<String, String> headers,
    bool useHlsSubtitles,
    bool useHlsTracks,
    Map<String, String> qualities,
    BetterPlayerCacheConfiguration cacheConfiguration,
    BetterPlayerNotificationConfiguration notificationConfiguration,
    Duration overriddenDuration,
  }) {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      subtitles: subtitles,
      liveStream: liveStream,
      headers: headers,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      resolutions: qualities,
      cacheConfiguration: cacheConfiguration,
      notificationConfiguration: notificationConfiguration,
      overriddenDuration: overriddenDuration,
    );
  }

  ///Factory method to build file data source which uses url as data source.
  ///Bytes parameter is not used in this data source.
  factory BetterPlayerDataSource.file(
    String url, {
    List<BetterPlayerSubtitlesSource> subtitles,
    bool useHlsSubtitles,
    bool useHlsTracks,
    Map<String, String> qualities,
    BetterPlayerCacheConfiguration cacheConfiguration,
    BetterPlayerNotificationConfiguration notificationConfiguration,
    Duration overriddenDuration,
  }) {
    return BetterPlayerDataSource(BetterPlayerDataSourceType.file, url,
        subtitles: subtitles,
        useHlsSubtitles: useHlsSubtitles,
        useHlsTracks: useHlsTracks,
        resolutions: qualities,
        cacheConfiguration: cacheConfiguration,
        notificationConfiguration: notificationConfiguration,
        overriddenDuration: overriddenDuration);
  }

  ///Factory method to build network data source which uses bytes as data source.
  ///Url parameter is not used in this data source.
  factory BetterPlayerDataSource.memory(
    List<int> bytes, {
    List<BetterPlayerSubtitlesSource> subtitles,
    bool useHlsSubtitles,
    bool useHlsTracks,
    Map<String, String> qualities,
    BetterPlayerCacheConfiguration cacheConfiguration,
    BetterPlayerNotificationConfiguration notificationConfiguration,
    Duration overriddenDuration,
  }) {
    return BetterPlayerDataSource(BetterPlayerDataSourceType.memory, "",
        bytes: bytes,
        subtitles: subtitles,
        useHlsSubtitles: useHlsSubtitles,
        useHlsTracks: useHlsTracks,
        resolutions: qualities,
        cacheConfiguration: cacheConfiguration,
        notificationConfiguration: notificationConfiguration,
        overriddenDuration: overriddenDuration);
  }

  BetterPlayerDataSource copyWith({
    BetterPlayerDataSourceType type,
    String url,
    List<int> bytes,
    List<BetterPlayerSubtitlesSource> subtitles,
    bool liveStream,
    Map<String, String> headers,
    bool useHlsSubtitles,
    bool useHlsTracks,
    Map<String, String> resolutions,
    BetterPlayerCacheConfiguration cacheConfiguration,
    BetterPlayerNotificationConfiguration notificationConfiguration,
    Duration overriddenDuration,
  }) {
    return BetterPlayerDataSource(
      type ?? this.type,
      url ?? this.url,
      bytes: bytes ?? this.bytes,
      subtitles: subtitles ?? this.subtitles,
      liveStream: liveStream ?? this.liveStream,
      headers: headers ?? this.headers,
      useHlsSubtitles: useHlsSubtitles ?? this.useHlsSubtitles,
      useHlsTracks: useHlsTracks ?? this.useHlsTracks,
      resolutions: resolutions ?? this.resolutions,
      cacheConfiguration: cacheConfiguration ?? this.cacheConfiguration,
      notificationConfiguration:
          notificationConfiguration ?? this.notificationConfiguration,
      overriddenDuration: overriddenDuration ?? this.overriddenDuration,
    );
  }
}
