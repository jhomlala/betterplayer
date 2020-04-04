import 'better_player_subtitles_source_type.dart';

class BetterPlayerSubtitlesSource {
  ///Source type
  final BetterPlayerSubtitlesSourceType type;

  ///Url of the subtitles, used with file or network subtitles
  final String url;

  ///Content of subtitles, used when type is memory
  final String content;

  BetterPlayerSubtitlesSource({this.type, this.url, this.content});
}
