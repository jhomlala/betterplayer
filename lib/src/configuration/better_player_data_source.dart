import 'package:better_player/src/configuration/better_player_data_source_type.dart';
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

  ///Is player controls notification enabled
  final bool showNotification;

  ///Title of the given data source, used in controls notification
  final String title;

  ///Author of the given data source, used in controls notification
  final String author;

  ///Image of the video, used in controls notification
  final String imageUrl;

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
    this.showNotification = false,
    this.title,
    this.author,
    this.imageUrl,
  }) : assert(
            ((type == BetterPlayerDataSourceType.NETWORK ||
                        type == BetterPlayerDataSourceType.FILE) &&
                    url != null) ||
                (type == BetterPlayerDataSourceType.MEMORY &&
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
    bool showNotification,
    String title,
    String author,
    String imageUrl,
  }) {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,
      url,
      subtitles: subtitles,
      liveStream: liveStream,
      headers: headers,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      resolutions: qualities,
      cacheConfiguration: cacheConfiguration,
      showNotification: showNotification,
      title: title,
      author: author,
      imageUrl: imageUrl,
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
    bool showNotification,
    String title,
    String author,
    String imageUrl,
  }) {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,
      url,
      subtitles: subtitles,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      resolutions: qualities,
      showNotification: showNotification,
      title: title,
      author: author,
      imageUrl: imageUrl,
    );
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
    bool showNotification,
    String title,
    String author,
    String imageUrl,
  }) {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.MEMORY,
      "",
      bytes: bytes,
      subtitles: subtitles,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      resolutions: qualities,
      showNotification: showNotification,
      title: title,
      author: author,
      imageUrl: imageUrl,
    );
  }

  BetterPlayerDataSource copyWith(
      {BetterPlayerDataSourceType type,
      String url,
      List<int> bytes,
      List<BetterPlayerSubtitlesSource> subtitles,
      bool liveStream,
      Map<String, String> headers,
      bool useHlsSubtitles,
      bool useHlsTracks,
      Map<String, String> qualities,
      BetterPlayerCacheConfiguration cacheConfiguration,
      bool showNotification,
      String title,
      String author,
      String imageUrl}) {
    return BetterPlayerDataSource(
      type ?? this.type,
      url ?? this.url,
      bytes: bytes ?? this.bytes,
      subtitles: subtitles ?? this.subtitles,
      liveStream: liveStream ?? this.liveStream,
      headers: headers ?? this.headers,
      useHlsSubtitles: useHlsSubtitles ?? this.useHlsSubtitles,
      useHlsTracks: useHlsTracks ?? this.useHlsTracks,
      resolutions: qualities ?? this.resolutions,
      cacheConfiguration: cacheConfiguration ?? this.cacheConfiguration,
      showNotification: showNotification ?? this.showNotification,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
