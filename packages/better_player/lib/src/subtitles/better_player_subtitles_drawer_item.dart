import 'package:better_player/src/subtitles/player_subtitles_configuration.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:material_ui/material_ui.dart';

class PlayerSubtitlesDrawerItem extends StatelessWidget {
  const PlayerSubtitlesDrawerItem({
    required this.subtitleText,
    required this.configuration,
    required this.innerTextStyle,
    required this.outerTextStyle,
    super.key,
  });
  final String subtitleText;
  final PlayerSubtitlesConfiguration configuration;
  final TextStyle innerTextStyle;
  final TextStyle outerTextStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: configuration.alignment,
            child: _getTextWithStroke(subtitleText),
          ),
        ),
      ],
    );
  }

  Widget _getTextWithStroke(String subtitleText) {
    return ColoredBox(
      color: configuration.backgroundColor,
      child: Stack(
        children: [
          if (configuration.outlineEnabled)
            HtmlWidget(subtitleText, textStyle: outerTextStyle)
          else
            const SizedBox(),
          HtmlWidget(subtitleText, textStyle: innerTextStyle),
        ],
      ),
    );
  }
}
