import 'dart:ui';

import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoMiddleRow extends StatelessWidget {
  const BetterPlayerCupertinoMiddleRow({
    required this.controlsConfiguration,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onPlayPause,
    required this.latestValue,
    required this.iconColor,
    super.key,
  });

  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onPlayPause;
  final VideoPlayerValue? latestValue;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final isFullScreen = controller.isFullScreen;
    final iconSize = isFullScreen ? 32.0 : 24.0;

    PlayerLogger.debug(message: "E2E_LOG: BetterPlayerCupertinoMiddleRow.build | "
      "isFullScreen: $isFullScreen | enableSkips: ${controlsConfiguration.enableSkips} | "
      "enablePlayPause: ${controlsConfiguration.enablePlayPause} | "
      "isPlaying: ${latestValue?.isPlaying}",
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: controller.isLiveStream()
              ? const SizedBox()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (controlsConfiguration.enableSkips)
                      Expanded(
                        child: Center(
                          child: _BetterPlayerCupertinoHitAreaButton(
                            semanticsIdentifier:
                                'better_player_cupertino_controls_skip_back_button',
                            icon: controlsConfiguration.skipBackIcon,
                            size: iconSize,
                            onTap: onSkipBack,
                            iconColor: iconColor,
                            semanticsLabel: controller
                                .translations
                                .controlsSkipBackwardLabel,
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                    if (controlsConfiguration.enablePlayPause)
                      Expanded(
                        child: Center(
                          child: _BetterPlayerCupertinoHitAreaButton(
                            semanticsIdentifier:
                                'better_player_cupertino_controls_play_pause_button',
                            icon: latestValue?.isPlaying == true
                                ? controlsConfiguration.pauseIcon
                                : controlsConfiguration.playIcon,
                            size: iconSize + 8.0, // Play button slightly larger
                            onTap: onPlayPause,
                            iconColor: iconColor,
                            semanticsLabel: latestValue?.isPlaying == true
                                ? controller.translations.controlsPauseLabel
                                : controller.translations.controlsPlayLabel,
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                    if (controlsConfiguration.enableSkips)
                      Expanded(
                        child: Center(
                          child: _BetterPlayerCupertinoHitAreaButton(
                            semanticsIdentifier:
                                'better_player_cupertino_controls_skip_forward_button',
                            icon: controlsConfiguration.skipForwardIcon,
                            size: iconSize,
                            onTap: onSkipForward,
                            iconColor: iconColor,
                            semanticsLabel: controller
                                .translations
                                .controlsSkipForwardLabel,
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                  ],
                ),
        );
      },
    );
  }
}

class _BetterPlayerCupertinoHitAreaButton extends StatelessWidget {
  const _BetterPlayerCupertinoHitAreaButton({
    required this.semanticsIdentifier,
    required this.icon,
    required this.size,
    required this.onTap,
    required this.iconColor,
    this.semanticsLabel,
  });

  final String semanticsIdentifier;
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final String? semanticsLabel;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    PlayerLogger.debug(message: "E2E_LOG: _BetterPlayerCupertinoHitAreaButton.build | identifier: $semanticsIdentifier | label: $semanticsLabel | icon: $icon",
    );
    return Semantics(
      identifier: semanticsIdentifier,
      label: semanticsLabel ?? semanticsIdentifier,
      button: true,
      child: GestureDetector(
        onTap: () {
          PlayerLogger.debug(message: "E2E_LOG: onTap triggered for $semanticsIdentifier",
          );
          onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(48),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withValues(alpha: 0.3),
              child: Icon(
                icon,
                color: iconColor,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
