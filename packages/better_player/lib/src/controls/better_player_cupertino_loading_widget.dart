import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoLoadingWidget extends StatelessWidget {
  const BetterPlayerCupertinoLoadingWidget({
    required this.controlsConfiguration,
    super.key,
  });
  final BetterPlayerControlsConfiguration controlsConfiguration;

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
