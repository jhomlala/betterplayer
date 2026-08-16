import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialHitArea extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onReplay;
  final VideoPlayerValue? latestValue;
  final bool isVideoFinished;

  const BetterPlayerMaterialHitArea({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onReplay,
    required this.latestValue,
    required this.isVideoFinished,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }
    return Container(
      child: Center(
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsHideTime,
          child: BetterPlayerMaterialMiddleRow(
            controller: controller,
            controlsConfiguration: controlsConfiguration,
            onSkipBack: onSkipBack,
            onSkipForward: onSkipForward,
            onReplay: onReplay,
            latestValue: latestValue,
            isVideoFinished: isVideoFinished,
          ),
        ),
      ),
    );
  }
}

class BetterPlayerMaterialMiddleRow extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onReplay;
  final VideoPlayerValue? latestValue;
  final bool isVideoFinished;

  const BetterPlayerMaterialMiddleRow({
    required this.controller,
    required this.controlsConfiguration,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onReplay,
    required this.latestValue,
    required this.isVideoFinished,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: controlsConfiguration.controlBarColor,
      width: double.infinity,
      height: double.infinity,
      child: controller.isLiveStream()
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (controlsConfiguration.enableSkips)
                  Expanded(
                    child: _BetterPlayerMaterialHitAreaClickableButton(
                      key: const Key(
                        'better_player_material_controls_skip_back_button',
                      ),
                      icon: Icon(
                        controlsConfiguration.skipBackIcon,
                        size: 24,
                        color: controlsConfiguration.iconsColor,
                      ),
                      onClicked: onSkipBack,
                      semanticsLabel:
                          controller.translations.controlsSkipBackwardLabel,
                    ),
                  )
                else
                  const SizedBox(),
                Expanded(
                  child: _BetterPlayerMaterialReplayButton(
                    controller: controller,
                    controlsConfiguration: controlsConfiguration,
                    onReplay: onReplay,
                    latestValue: latestValue,
                    isVideoFinished: isVideoFinished,
                  ),
                ),
                if (controlsConfiguration.enableSkips)
                  Expanded(
                    child: _BetterPlayerMaterialHitAreaClickableButton(
                      key: const Key(
                        'better_player_material_controls_skip_forward_button',
                      ),
                      icon: Icon(
                        controlsConfiguration.skipForwardIcon,
                        size: 24,
                        color: controlsConfiguration.iconsColor,
                      ),
                      onClicked: onSkipForward,
                      semanticsLabel:
                          controller.translations.controlsSkipForwardLabel,
                    ),
                  )
                else
                  const SizedBox(),
              ],
            ),
    );
  }
}

class _BetterPlayerMaterialHitAreaClickableButton extends StatelessWidget {
  final VoidCallback onClicked;
  final Widget icon;
  final String? semanticsLabel;

  const _BetterPlayerMaterialHitAreaClickableButton({
    required this.onClicked,
    required this.icon,
    this.semanticsLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80, maxWidth: 80),
      child: BetterPlayerMaterialClickableWidget(
        onTap: onClicked,
        semanticsLabel: semanticsLabel,
        child: Align(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(48),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [icon],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialReplayButton extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onReplay;
  final VideoPlayerValue? latestValue;
  final bool isVideoFinished;

  const _BetterPlayerMaterialReplayButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.onReplay,
    required this.latestValue,
    required this.isVideoFinished,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = controller.videoPlayerController!.value.isPlaying;

    var semanticsLabel = isPlaying
        ? controller.translations.controlsPauseLabel
        : controller.translations.controlsPlayLabel;
    if (isVideoFinished) {
      semanticsLabel = controller.translations.controlsPlayLabel;
    }

    return _BetterPlayerMaterialHitAreaClickableButton(
      semanticsLabel: semanticsLabel,
      icon: isVideoFinished
          ? Icon(
              Icons.replay,
              size: 42,
              color: controlsConfiguration.iconsColor,
            )
          : Icon(
              isPlaying
                  ? controlsConfiguration.pauseIcon
                  : controlsConfiguration.playIcon,
              size: 42,
              color: controlsConfiguration.iconsColor,
            ),
      onClicked: onReplay,
    );
  }
}
