// Project imports:
import 'better_player_subtitles_source_type.dart';

///Representation of subtitles source. Used to define subtitles in Better
/// Player.
class BetterPlayerSubtitlesSource {
  ///Source type
  final BetterPlayerSubtitlesSourceType? type;

  ///Name of the subtitles, default value is "Default subtitles"
  final String? name;

  ///Url of the subtitles, used with file or network subtitles
  final List<String?>? urls;

  ///Content of subtitles, used when type is memory
  final String? content;

  ///Subtitles selected by default, without user interaction
  final bool? selectedByDefault;

  BetterPlayerSubtitlesSource({
    this.type,
    this.name = "Default subtitles",
    this.urls,
    this.content,
    this.selectedByDefault,
  });

  ///Creates list with only one subtitles
  static List<BetterPlayerSubtitlesSource> single({
    BetterPlayerSubtitlesSourceType? type,
    String name = "Default subtitles",
    String? url,
    String? content,
    bool? selectedByDefault,
  }) =>
      [
        BetterPlayerSubtitlesSource(
          type: type,
          name: name,
          urls: [url],
          content: content,
          selectedByDefault: selectedByDefault,
        )
      ];
}
