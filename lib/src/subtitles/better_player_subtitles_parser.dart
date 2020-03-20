import 'better_player_subtitle.dart';

class BetterPlayerSubtitlesParser {
  static List<BetterPlayerSubtitle> parseString(String value) {
    List<String> components = value.split('\r\n\r\n');
    if (components.length == 1) {
      components = value.split('\n\n');
    }

    final List<BetterPlayerSubtitle> subtitlesObj = List();

    for (var component in components) {
      if (component.isEmpty) {
        continue;
      }

      final subtitle = BetterPlayerSubtitle(component);
      if (subtitle != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }
}
