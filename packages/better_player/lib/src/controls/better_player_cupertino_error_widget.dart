import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoErrorWidget extends StatelessWidget {
  const BetterPlayerCupertinoErrorWidget({
    required this.controller,
    required this.controlsConfiguration,
    super.key,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    final errorBuilder = controller.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
        context,
        controller.videoPlayerController!.value.errorDescription,
      );
    } else {
      final textStyle = TextStyle(color: controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              controller.translations.generalDefaultError,
              style: textStyle,
            ),
            if (controlsConfiguration.enableRetry)
              TextButton(
                onPressed: controller.retryDataSource,
                child: Text(
                  controller.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }
  }
}
