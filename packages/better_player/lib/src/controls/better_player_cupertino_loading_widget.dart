import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

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

    return CupertinoActivityIndicator(
      color: controlsConfiguration.loadingColor,
      radius: 14,
    );
  }
}
