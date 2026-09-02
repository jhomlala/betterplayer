import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoLoadingWidget extends StatelessWidget {
  const BetterPlayerCupertinoLoadingWidget({
    required this.controlsConfiguration,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    if (controlsConfiguration.loadingWidget != null) {
      return controlsConfiguration.loadingWidget!;
    }

    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        controlsConfiguration.loadingColor,
      ),
    );
  }
}
