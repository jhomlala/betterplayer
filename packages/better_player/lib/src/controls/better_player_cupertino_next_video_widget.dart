import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoNextVideoWidget extends StatelessWidget {
  const BetterPlayerCupertinoNextVideoWidget({
    required this.controlsConfiguration,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    return StreamBuilder<int?>(
      stream: controller.nextVideoTimeStream,
      builder: (context, snapshot) {
        final time = snapshot.data;
        if (time != null && time > 0) {
          return InkWell(
            onTap: controller.playNextVideo,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 8),
                decoration: BoxDecoration(
                  color: controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${controller.translations.controlsNextVideoIn} $time ...',
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




