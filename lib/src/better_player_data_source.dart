import 'dart:io';

import 'package:better_player/src/better_player_data_source_type.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';

class BetterPlayerDataSource {
  final BetterPlayerDataSourceType type;
  final String url;
  final BetterPlayerSubtitlesSource subtitles;
  final bool liveStream;

  BetterPlayerDataSource(this.type, this.url,
      {this.subtitles, this.liveStream = false});

  @override
  String toString() {
    return 'BetterPlayerDataSource{type: $type, url: $url, subtitles: $subtitles, liveStream: $liveStream}';
  }
}
