import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialNextVideoWidget extends StatelessWidget {

  const BetterPlayerMaterialNextVideoWidget({
    required this.controller,
    required this.controlsConfiguration,
    super.key,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: controller.nextVideoTimeStream,
      builder: (context, snapshot) {
        final time = snapshot.data;
        if (time != null && time > 0) {
          return BetterPlayerMaterialClickableWidget(
            onTap: controller.playNextVideo,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.only(
                  bottom: controlsConfiguration.controlBarHeight + 20,
                  right: 24,
                ),
                decoration: BoxDecoration(
                  color: controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${controller.translations.controlsNextVideoIn} $time...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
