import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class PlayerCupertinoMiddleRow extends StatelessWidget {
  const PlayerCupertinoMiddleRow({
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
    final buttonSize = iconSize + 16.0;
    final playButtonSize = iconSize + 8.0 + 16.0;

    return Center(
      child: controller.isLiveStream()
          ? const SizedBox()
          : Semantics(
              explicitChildNodes: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (controlsConfiguration.enableSkips)
                    Expanded(
                      child: Semantics(
                        identifier:
                            'better_player_cupertino_controls_skip_back_button',
                        label:
                            controller.translations.controlsSkipBackwardLabel,
                        button: true,
                        container: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onSkipBack,
                          child: Center(
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controlsConfiguration.skipBackIcon,
                                color: iconColor,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  if (controlsConfiguration.enablePlayPause)
                    Expanded(
                      child: Semantics(
                        identifier:
                            'better_player_cupertino_controls_play_pause_button',
                        label: latestValue?.isPlaying == true
                            ? controller.translations.controlsPauseLabel
                            : controller.translations.controlsPlayLabel,
                        button: true,
                        container: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onPlayPause,
                          child: Center(
                            child: Container(
                              width: playButtonSize,
                              height: playButtonSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                latestValue?.isPlaying == true
                                    ? controlsConfiguration.pauseIcon
                                    : controlsConfiguration.playIcon,
                                color: iconColor,
                                size: iconSize + 8.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  if (controlsConfiguration.enableSkips)
                    Expanded(
                      child: Semantics(
                        identifier:
                            'better_player_cupertino_controls_skip_forward_button',
                        label: controller.translations.controlsSkipForwardLabel,
                        button: true,
                        container: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onSkipForward,
                          child: Center(
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controlsConfiguration.skipForwardIcon,
                                color: iconColor,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                ],
              ),
            ),
    );
  }
}
