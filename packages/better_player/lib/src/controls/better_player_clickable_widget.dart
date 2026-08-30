// Flutter imports:
import 'package:better_player/better_player.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  const BetterPlayerMaterialClickableWidget({
    required this.onTap,
    required this.child,
    this.semanticsLabel,
    this.semanticsIdentifier,
    super.key,
  });
  final Widget child;
  final void Function() onTap;
  final String? semanticsLabel;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(60),
      ),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          BetterPlayerLogger.instance.debug(
            'Tapped on: $semanticsIdentifier ($semanticsLabel)',
            tag: 'ClickableWidget',
          );
          onTap();
        },
        child: Semantics(
          label: semanticsLabel,
          identifier: semanticsIdentifier,
          button: true,
          child: child,
        ),
      ),
    );
  }
}
