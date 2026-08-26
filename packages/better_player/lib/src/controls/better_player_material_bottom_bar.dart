import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_ui_utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialBottomBar extends StatelessWidget {
  const BetterPlayerMaterialBottomBar({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onPlayerHide,
    required this.onPlayPause,
    required this.onMute,
    required this.onExpandCollapse,
    required this.onProgressBarDragStart,
    required this.onProgressBarDragEnd,
    required this.onProgressBarTapDown,
    required this.latestValue,
    super.key,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onPlayerHide;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onExpandCollapse;
  final VoidCallback onProgressBarDragStart;
  final VoidCallback onProgressBarDragEnd;
  final VoidCallback onProgressBarTapDown;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: controlsConfiguration.controlsHideTime,
      onEnd: onPlayerHide,
      child: SizedBox(
        height: controlsConfiguration.controlBarHeight + 20.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 75,
              child: Row(
                children: [
                  if (controlsConfiguration.enablePlayPause)
                    _BetterPlayerMaterialPlayPauseButton(
                      controller: controller,
                      controlsConfiguration: controlsConfiguration,
                      onPlayPause: onPlayPause,
                      latestValue: latestValue,
                    )
                  else
                    const SizedBox(),
                  if (controller.isLiveStream())
                    _BetterPlayerMaterialLiveWidget(
                      controller: controller,
                      controlsConfiguration: controlsConfiguration,
                    )
                  else if (controlsConfiguration.enableProgressText)
                    Expanded(
                      child: _BetterPlayerMaterialPositionWidget(
                        controller: controller,
                        controlsConfiguration: controlsConfiguration,
                        latestValue: latestValue,
                      ),
                    )
                  else
                    const SizedBox(),
                  const Spacer(),
                  if (controlsConfiguration.enableMute)
                    _BetterPlayerMaterialMuteButton(
                      controller: controller,
                      controlsConfiguration: controlsConfiguration,
                      onMute: onMute,
                      controlsNotVisible: controlsNotVisible,
                      latestValue: latestValue,
                    )
                  else
                    const SizedBox(),
                  if (controlsConfiguration.enableFullscreen)
                    _BetterPlayerMaterialFullscreenButton(
                      controller: controller,
                      controlsConfiguration: controlsConfiguration,
                      onExpandCollapse: onExpandCollapse,
                      controlsNotVisible: controlsNotVisible,
                    )
                  else
                    const SizedBox(),
                ],
              ),
            ),
            if (controller.isLiveStream())
              const SizedBox()
            else if (controlsConfiguration.enableProgressBar)
              _BetterPlayerMaterialProgressBarWrapper(
                controller: controller,
                controlsConfiguration: controlsConfiguration,
                onProgressBarDragStart: onProgressBarDragStart,
                onProgressBarDragEnd: onProgressBarDragEnd,
                onProgressBarTapDown: onProgressBarTapDown,
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialPlayPauseButton extends StatelessWidget {
  const _BetterPlayerMaterialPlayPauseButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.onPlayPause,
    required this.latestValue,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onPlayPause;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final isPlaying = latestValue?.isPlaying ?? false;
    return BetterPlayerMaterialClickableWidget(
      key: const Key('better_player_material_controls_play_pause_button'),
      onTap: onPlayPause,
      semanticsLabel: isPlaying
          ? controller.translations.controlsPauseLabel
          : controller.translations.controlsPlayLabel,
      semanticsIdentifier: 'better_player_material_controls_play_pause_button',
      child: Container(
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          isPlaying
              ? controlsConfiguration.pauseIcon
              : controlsConfiguration.playIcon,
          color: controlsConfiguration.iconsColor,
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialMuteButton extends StatelessWidget {
  const _BetterPlayerMaterialMuteButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.onMute,
    required this.controlsNotVisible,
    required this.latestValue,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onMute;
  final bool controlsNotVisible;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    return BetterPlayerMaterialClickableWidget(
      onTap: onMute,
      semanticsLabel: (latestValue != null && latestValue!.volume > 0)
          ? controller.translations.controlsMuteLabel
          : controller.translations.controlsUnmuteLabel,
      semanticsIdentifier: 'better_player_material_controls_mute_button',
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: controlsConfiguration.controlsHideTime,
        child: ClipRect(
          child: Container(
            height: controlsConfiguration.controlBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              (latestValue != null && latestValue!.volume > 0)
                  ? controlsConfiguration.muteIcon
                  : controlsConfiguration.unMuteIcon,
              color: controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialFullscreenButton extends StatelessWidget {
  const _BetterPlayerMaterialFullscreenButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.onExpandCollapse,
    required this.controlsNotVisible,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onExpandCollapse;
  final bool controlsNotVisible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: BetterPlayerMaterialClickableWidget(
        key: const Key('better_player_material_controls_expand_button'),
        onTap: onExpandCollapse,
        semanticsLabel: controller.isFullScreen
            ? controller.translations.controlsExitFullscreenLabel
            : controller.translations.controlsFullscreenLabel,
        semanticsIdentifier: 'better_player_material_controls_expand_button',
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsHideTime,
          child: Container(
            height: controlsConfiguration.controlBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Icon(
                controller.isFullScreen
                    ? controlsConfiguration.fullscreenDisableIcon
                    : controlsConfiguration.fullscreenEnableIcon,
                color: controlsConfiguration.iconsColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialLiveWidget extends StatelessWidget {
  const _BetterPlayerMaterialLiveWidget({
    required this.controller,
    required this.controlsConfiguration,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return Text(
      controller.translations.controlsLive,
      style: TextStyle(
        color: controlsConfiguration.liveTextColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _BetterPlayerMaterialPositionWidget extends StatelessWidget {
  const _BetterPlayerMaterialPositionWidget({
    required this.controller,
    required this.controlsConfiguration,
    required this.latestValue,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final position = latestValue != null
        ? latestValue!.position
        : Duration.zero;
    final duration = latestValue != null && latestValue!.duration != null
        ? latestValue!.duration!
        : Duration.zero;

    return Padding(
      padding: controlsConfiguration.enablePlayPause
          ? const EdgeInsets.only(right: 24)
          : const EdgeInsets.symmetric(horizontal: 22),
      child: RichText(
        text: TextSpan(
          text: BetterPlayerUiUtils.formatDuration(position),
          style: TextStyle(
            fontSize: 10,
            color: controlsConfiguration.textColor,
            decoration: TextDecoration.none,
          ),
          children: <TextSpan>[
            TextSpan(
              text: ' / ${BetterPlayerUiUtils.formatDuration(duration)}',
              style: TextStyle(
                fontSize: 10,
                color: controlsConfiguration.textColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialProgressBarWrapper extends StatelessWidget {
  const _BetterPlayerMaterialProgressBarWrapper({
    required this.controller,
    required this.controlsConfiguration,
    required this.onProgressBarDragStart,
    required this.onProgressBarDragEnd,
    required this.onProgressBarTapDown,
  });
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onProgressBarDragStart;
  final VoidCallback onProgressBarDragEnd;
  final VoidCallback onProgressBarTapDown;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 40,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: BetterPlayerMaterialVideoProgressBar(
          controller.videoPlayerController,
          controller,
          onDragStart: onProgressBarDragStart,
          onDragEnd: onProgressBarDragEnd,
          onTapDown: onProgressBarTapDown,
          colors: BetterPlayerProgressColors(
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
