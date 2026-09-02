import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialLoadingWidget extends StatelessWidget {
  const BetterPlayerMaterialLoadingWidget({
    required this.controlsConfiguration,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    if (controlsConfiguration.loadingWidget != null) {
      return ColoredBox(
        color: controlsConfiguration.controlBarColor,
        child: controlsConfiguration.loadingWidget,
      );
    }

    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        controlsConfiguration.loadingColor,
      ),
    );
  }
}


