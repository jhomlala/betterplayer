import 'dart:ui';
import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_controller.dart';
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

    return Center(
      child: controller.isLiveStream()
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controlsConfiguration.enableSkips)
                  _buildHitAreaButton(
                    semanticsIdentifier:
                        'better_player_cupertino_controls_skip_back_button',
                    icon: controlsConfiguration.skipBackIcon,
                    size: iconSize,
                    onTap: onSkipBack,
                    semanticsLabel:
                        controller.translations.controlsSkipBackwardLabel,
                  )
                else
                  const SizedBox(),
                SizedBox(width: isFullScreen ? 48 : 24),
                if (controlsConfiguration.enablePlayPause)
                  _buildHitAreaButton(
                    semanticsIdentifier:
                        'better_player_cupertino_controls_play_pause_button',
                    icon: latestValue?.isPlaying == true
                        ? controlsConfiguration.pauseIcon
                        : controlsConfiguration.playIcon,
                    size: iconSize + 8.0, // Play button slightly larger
                    onTap: onPlayPause,
                    semanticsLabel: latestValue?.isPlaying == true
                        ? controller.translations.controlsPauseLabel
                        : controller.translations.controlsPlayLabel,
                  )
                else
                  const SizedBox(),
                SizedBox(width: isFullScreen ? 48 : 24),
                if (controlsConfiguration.enableSkips)
                  _buildHitAreaButton(
                    semanticsIdentifier:
                        'better_player_cupertino_controls_skip_forward_button',
                    icon: controlsConfiguration.skipForwardIcon,
                    size: iconSize,
                    onTap: onSkipForward,
                    semanticsLabel:
                        controller.translations.controlsSkipForwardLabel,
                  )
                else
                  const SizedBox(),
              ],
            ),
    );
  }

  Widget _buildHitAreaButton({
    required String semanticsIdentifier,
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    String? semanticsLabel,
  }) {
    return BetterPlayerMaterialClickableWidget(
      semanticsIdentifier: semanticsIdentifier,
      semanticsLabel: semanticsLabel,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black.withOpacity(0.3),
            child: Icon(
              icon,
              color: iconColor,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
