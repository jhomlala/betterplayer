import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:flutter/material.dart';

class BetterPlayerWebErrorWidget extends StatelessWidget {
  const BetterPlayerWebErrorWidget({
    required this.controlsConfiguration,
    this.errorDescription,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final String? errorDescription;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final errorBuilder = controller.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
        context,
        errorDescription ?? controller.videoPlayerValue?.errorDescription,
      );
    } else {
      final textStyle = TextStyle(color: controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: controlsConfiguration.iconsColor,
              size: 42,
            ),
            const SizedBox(height: 8),
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
