// Flutter imports:
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  final Widget child;
  final void Function() onTap;
  final String? semanticsLabel;
  final String? semanticsIdentifier;

  const BetterPlayerMaterialClickableWidget({
    required this.onTap,
    required this.child,
    this.semanticsLabel,
    this.semanticsIdentifier,
    super.key,
  });

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
          BetterPlayerUtils.log(
            'Tapped on: $semanticsIdentifier ($semanticsLabel)',
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
