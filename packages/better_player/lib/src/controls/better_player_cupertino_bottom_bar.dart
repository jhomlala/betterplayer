import 'dart:ui';

import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_ui_utils.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoBottomBar extends StatelessWidget {
  const BetterPlayerCupertinoBottomBar({
    required this.controlsConfiguration,
    required this.barHeight,
    required this.iconColor,
    required this.onProgressBarDragStart,
    required this.onProgressBarDragEnd,
    required this.onProgressBarTapDown,
    required this.latestValue,
    required this.onPlayPause,
    super.key,
  });

  final PlayerControlsConfiguration controlsConfiguration;
  final double barHeight;
  final Color iconColor;
  final VoidCallback onProgressBarDragStart;
  final VoidCallback onProgressBarDragEnd;
  final VoidCallback onProgressBarTapDown;
  final VideoPlayerValue? latestValue;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }

    final isFullScreen = controller.isFullScreen;
    final horizontalMargin = isFullScreen ? 48.0 : 16.0;
    final bottomMargin = isFullScreen ? 24.0 : 16.0;

    return Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: bottomMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: controller.isLiveStream()
                ? _buildLiveStreamRow(controller)
                : _buildVodRow(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildVodRow(BetterPlayerController controller) {
    return Row(
      children: [
        if (controlsConfiguration.enableProgressText)
          Text(
            BetterPlayerUiUtils.formatDuration(
              latestValue?.position ?? Duration.zero,
            ),
            style: TextStyle(
              color: controlsConfiguration.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (controlsConfiguration.enableProgressBar)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BetterPlayerCupertinoVideoProgressBar(
                controller,
                colors: PlayerProgressColors(
                  playedColor: controlsConfiguration.progressBarPlayedColor,
                  handleColor: controlsConfiguration.progressBarHandleColor,
                  bufferedColor: controlsConfiguration.progressBarBufferedColor,
                  backgroundColor:
                      controlsConfiguration.progressBarBackgroundColor,
                ),
                onDragStart: onProgressBarDragStart,
                onDragEnd: onProgressBarDragEnd,
                onTapDown: onProgressBarTapDown,
              ),
            ),
          ),
        if (controlsConfiguration.enableProgressText)
          Text(
            '-${BetterPlayerUiUtils.formatDuration(
              (latestValue?.duration ?? Duration.zero) - (latestValue?.position ?? Duration.zero),
            )}',
            style: TextStyle(
              color: controlsConfiguration.textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildLiveStreamRow(BetterPlayerController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (controlsConfiguration.enablePlayPause)
          GestureDetector(
            onTap: onPlayPause,
            child: Icon(
              latestValue?.isPlaying == true
                  ? CupertinoIcons.pause_solid
                  : CupertinoIcons.play_arrow_solid,
              color: iconColor,
              size: 24,
            ),
          )
        else
          const SizedBox(),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              controller.translations.controlsLive,
              style: TextStyle(
                color: controlsConfiguration.textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
