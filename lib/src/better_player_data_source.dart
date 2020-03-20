import 'dart:io';

import 'package:better_player/src/better_player_data_source_type.dart';

class BetterPlayerDataSource {
  final BetterPlayerDataSourceType type;
  final String url;
  final File subtitlesFile;

  BetterPlayerDataSource(this.type, this.url, {this.subtitlesFile});
}
