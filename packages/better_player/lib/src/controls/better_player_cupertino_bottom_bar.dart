import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_ui_utils.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoBottomBar extends StatelessWidget {
  const BetterPlayerCupertinoBottomBar({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.marginSize,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPlayPause,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onProgressBarDragStart,
    required this.onProgressBarDragEnd,
    required this.onProgressBarTapDown,
    required this.onPlayerHide,
    required this.latestValue,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double marginSize;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onProgressBarDragStart;
  final VoidCallback onProgressBarDragEnd;
  final VoidCallback onProgressBarTapDown;
  final VoidCallback onPlayerHide;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: controlsConfiguration.controlsHideTime,
      onEnd: onPlayerHide,
      child: Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(marginSize),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(color: backgroundColor),
            child: controller.isLiveStream()
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const SizedBox(width: 8),
                      if (controlsConfiguration.enablePlayPause)
                        _BetterPlayerCupertinoPlayPauseButton(
                          controlsConfiguration: controlsConfiguration,
                          onPlayPause: onPlayPause,
                          iconColor: iconColor,
                          barHeight: barHeight,
                          latestValue: latestValue,
                        )
                      else
                        const SizedBox(),
                      const SizedBox(width: 8),
                      _BetterPlayerCupertinoLiveWidget(
                        controlsConfiguration: controlsConfiguration,
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      if (controlsConfiguration.enableSkips)
                        _BetterPlayerCupertinoSkipButton(
                          onSkip: onSkipBack,
                          icon: controlsConfiguration.skipBackIcon,
                          semanticsLabel:
                              controller.translations.controlsSkipBackwardLabel,
                          iconColor: iconColor,
                          barHeight: barHeight,
                          isBack: true,
                        )
                      else
                        const SizedBox(),
                      if (controlsConfiguration.enablePlayPause)
                        _BetterPlayerCupertinoPlayPauseButton(
                          controlsConfiguration: controlsConfiguration,
                          onPlayPause: onPlayPause,
                          iconColor: iconColor,
                          barHeight: barHeight,
                          latestValue: latestValue,
                        )
                      else
                        const SizedBox(),
                      if (controlsConfiguration.enableSkips)
                        _BetterPlayerCupertinoSkipButton(
                          onSkip: onSkipForward,
                          icon: controlsConfiguration.skipForwardIcon,
                          semanticsLabel:
                              controller.translations.controlsSkipForwardLabel,
                          iconColor: iconColor,
                          barHeight: barHeight,
                          isBack: false,
                        )
                      else
                        const SizedBox(),
                      if (controlsConfiguration.enableProgressText)
                        _BetterPlayerCupertinoPositionWidget(
                          controlsConfiguration: controlsConfiguration,
                          latestValue: latestValue,
                        )
                      else
                        const SizedBox(),
                      if (controlsConfiguration.enableProgressBar)
                        _BetterPlayerCupertinoProgressBarWrapper(
                          controlsConfiguration: controlsConfiguration,
                          onDragStart: onProgressBarDragStart,
                          onDragEnd: onProgressBarDragEnd,
                          onTapDown: onProgressBarTapDown,
                        )
                      else
                        const SizedBox(),
                      if (controlsConfiguration.enableProgressText)
                        _BetterPlayerCupertinoRemainingWidget(
                          controlsConfiguration: controlsConfiguration,
                          latestValue: latestValue,
                        )
                      else
                        const SizedBox(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoPlayPauseButton extends StatelessWidget {
  const _BetterPlayerCupertinoPlayPauseButton({
    required this.controlsConfiguration,
    required this.onPlayPause,
    required this.iconColor,
    required this.barHeight,
    required this.latestValue,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onPlayPause;
  final Color iconColor;
  final double barHeight;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final isPlaying = latestValue?.isPlaying ?? false;
    return GestureDetector(
      onTap: onPlayPause,
      child: Semantics(
        label: isPlaying
            ? controller.translations.controlsPauseLabel
            : controller.translations.controlsPlayLabel,
        identifier: 'better_player_cupertino_controls_play_pause_button',
        button: true,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            isPlaying
                ? controlsConfiguration.pauseIcon
                : controlsConfiguration.playIcon,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoSkipButton extends StatelessWidget {
  const _BetterPlayerCupertinoSkipButton({
    required this.onSkip,
    required this.icon,
    required this.semanticsLabel,
    required this.iconColor,
    required this.barHeight,
    required this.isBack,
  });
  final VoidCallback onSkip;
  final IconData icon;
  final String semanticsLabel;
  final Color iconColor;
  final double barHeight;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSkip,
      child: Semantics(
        label: semanticsLabel,
        identifier: isBack
            ? 'better_player_cupertino_controls_skip_back_button'
            : 'better_player_cupertino_controls_skip_forward_button',
        button: true,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          margin: EdgeInsets.only(left: isBack ? 10 : 0, right: isBack ? 0 : 8),
          padding: EdgeInsets.symmetric(horizontal: isBack ? 8 : 6),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoLiveWidget extends StatelessWidget {
  const _BetterPlayerCupertinoLiveWidget({
    required this.controlsConfiguration,
  });
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    return Expanded(
      child: Text(
        controller.translations.controlsLive,
        style: TextStyle(
          color: controlsConfiguration.liveTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoPositionWidget extends StatelessWidget {
  const _BetterPlayerCupertinoPositionWidget({
    required this.controlsConfiguration,
    required this.latestValue,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final position = latestValue != null
        ? latestValue!.position
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        identifier: 'better_player_cupertino_controls_position_text',
        child: Text(
          BetterPlayerUiUtils.formatDuration(position),
          style: TextStyle(
            color: controlsConfiguration.textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoRemainingWidget extends StatelessWidget {
  const _BetterPlayerCupertinoRemainingWidget({
    required this.controlsConfiguration,
    required this.latestValue,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final remaining = latestValue != null && latestValue!.duration != null
        ? latestValue!.duration! - latestValue!.position
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        identifier: 'better_player_cupertino_controls_remaining_text',
        child: Text(
          '-${BetterPlayerUiUtils.formatDuration(remaining)}',
          style: TextStyle(
            color: controlsConfiguration.textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoProgressBarWrapper extends StatelessWidget {
  const _BetterPlayerCupertinoProgressBarWrapper({
    required this.controlsConfiguration,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onTapDown,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onTapDown;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: BetterPlayerCupertinoVideoProgressBar(
          controller,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          onTapDown: onTapDown,
          colors: PlayerProgressColors(
            playedColor: controlsConfiguration.progressBarPlayedColor,
            handleColor: controlsConfiguration.progressBarHandleColor,
            bufferedColor: controlsConfiguration.progressBarBufferedColor,
            backgroundColor: controlsConfiguration.progressBarBackgroundColor,
          ),
        ),
      ),
    );
  }
}
