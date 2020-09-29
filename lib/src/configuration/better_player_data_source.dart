import 'package:better_player/src/configuration/better_player_data_source_type.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';

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

  final Map<String, String> qualities;

  BetterPlayerDataSource(
    this.type,
    this.url, {
    this.subtitles,
    this.liveStream = false,
    this.headers,
    this.useHlsSubtitles = true,
    this.useHlsTracks = true,
    this.hlsTrackNames,
    this.qualities,
  });

  @override
  String toString() {
    return 'BetterPlayerDataSource{type: $type, url: $url, subtitles: $subtitles,'
        ' liveStream: $liveStream, headers: $headers, useHlsSubtitles: $useHlsSubtitles}';
  }

  BetterPlayerDataSource copyWith(
      {BetterPlayerDataSourceType type,
      String url,
      List<BetterPlayerSubtitlesSource> subtitles,
      bool liveStream,
      Map<String, String> headers,
      bool useHlsSubtitles,
      bool useHlsTracks,
      Map<String, String> qualities}) {
    return BetterPlayerDataSource(
      type ?? this.type,
      url ?? this.url,
      subtitles: subtitles ?? this.subtitles,
      liveStream: liveStream ?? this.liveStream,
      headers: headers ?? this.headers,
      useHlsSubtitles: useHlsSubtitles ?? this.useHlsSubtitles,
      useHlsTracks: useHlsTracks ?? this.useHlsTracks,
      qualities: qualities ?? this.qualities,
    );
  }
}
