import 'dart:io';

import 'package:better_player/src/better_player_data_source_type.dart';

class BetterPlayerDataSource {
  final BetterPlayerDataSourceType type;
  final String url;
  final File subtitlesFile;
  final bool liveStream;

  BetterPlayerDataSource(this.type, this.url,
      {this.subtitlesFile, this.liveStream = false});

  @override
  String toString() {
    return 'BetterPlayerDataSource{type: $type, url: $url, subtitlesFile: $subtitlesFile, liveStream: $liveStream}';
  }
}
