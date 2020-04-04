import 'package:better_player/src/configuration/better_player_data_source_type.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';

class BetterPlayerDataSource {
  ///Type of source of video
  final BetterPlayerDataSourceType type;

  ///Url of the video
  final String url;

  ///Subtitles configuration
  final BetterPlayerSubtitlesSource subtitles;

  ///Flag to determine if current data source is live stream
  final bool liveStream;

  BetterPlayerDataSource(this.type, this.url,
      {this.subtitles, this.liveStream = false});

  @override
  String toString() {
    return 'BetterPlayerDataSource{type: $type, url: $url, subtitles: $subtitles, liveStream: $liveStream}';
  }
}
