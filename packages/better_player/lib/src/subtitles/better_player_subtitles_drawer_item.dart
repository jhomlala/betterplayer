import 'package:better_player/src/subtitles/player_subtitles_configuration.dart';
import 'package:better_player/src/subtitles/webvtt_inline_parser.dart';
import 'package:material_ui/material_ui.dart';

class PlayerSubtitlesDrawerItem extends StatelessWidget {
  const PlayerSubtitlesDrawerItem({
    required this.subtitleText,
    required this.configuration,
    required this.innerTextStyle,
    this.cueAlignment,
    super.key,
  });
  final String subtitleText;
  final PlayerSubtitlesConfiguration configuration;
  final TextStyle innerTextStyle;
  final Alignment? cueAlignment;

  @override
  Widget build(BuildContext context) {
    final effectiveAlignment = cueAlignment ?? configuration.alignment;
    final textAlign =
        effectiveAlignment == Alignment.bottomLeft ||
            effectiveAlignment == Alignment.topLeft ||
            effectiveAlignment == Alignment.centerLeft
        ? TextAlign.left
        : effectiveAlignment == Alignment.bottomRight ||
              effectiveAlignment == Alignment.topRight ||
              effectiveAlignment == Alignment.centerRight
        ? TextAlign.right
        : TextAlign.center;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: effectiveAlignment,
            child: ColoredBox(
              color: configuration.backgroundColor,
              child: RichText(
                textAlign: textAlign,
                text: WebVttInlineParser.parse(
                  subtitleText,
                  innerTextStyle.copyWith(
                    shadows: configuration.outlineEnabled
                        ? [
                            Shadow(
                              color: configuration.outlineColor,
                              blurRadius: configuration.outlineSize * 2,
                              offset: const Offset(1, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
