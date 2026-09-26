import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialHitArea extends StatelessWidget {
  const BetterPlayerMaterialHitArea({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onReplay,
    required this.latestValue,
    required this.isVideoFinished,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onReplay;
  final VideoPlayerValue? latestValue;
  final bool isVideoFinished;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }
    return Container(
      child: Center(
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsTransitionTime,
          child: BetterPlayerMaterialMiddleRow(
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
  const BetterPlayerMaterialMiddleRow({
    required this.controlsConfiguration,
    required this.onSkipBack,
    required this.onSkipForward,
    required this.onReplay,
    required this.latestValue,
    required this.isVideoFinished,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;
  final VoidCallback onReplay;
  final VideoPlayerValue? latestValue;
  final bool isVideoFinished;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final isFullScreen = controller.isFullScreen;
    final skipIconSize = isFullScreen ? 36.0 : 28.0;
    final skipPadding = isFullScreen ? 12.0 : 8.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black54,
            Colors.black26,
            Colors.black26,
            Colors.black87,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.2, 0.7, 1.0],
        ),
      ),
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
                      icon: Ink(
                        padding: EdgeInsets.all(skipPadding),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controlsConfiguration.skipBackIcon,
                          size: skipIconSize,
                          color: controlsConfiguration.iconsColor,
                        ),
                      ),
                      onClicked: onSkipBack,
                      semanticsLabel:
                          controller.translations.controlsSkipBackwardLabel,
                      semanticsIdentifier:
                          'better_player_material_controls_skip_back_button',
                    ),
                  )
                else
                  const SizedBox(),
                Expanded(
                  child: _BetterPlayerMaterialReplayButton(
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
                      icon: Ink(
                        padding: EdgeInsets.all(skipPadding),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controlsConfiguration.skipForwardIcon,
                          size: skipIconSize,
                          color: controlsConfiguration.iconsColor,
                        ),
                      ),
                      onClicked: onSkipForward,
                      semanticsLabel:
                          controller.translations.controlsSkipForwardLabel,
                      semanticsIdentifier:
                          'better_player_material_controls_skip_forward_button',
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
  const _BetterPlayerMaterialHitAreaClickableButton({
    required this.onClicked,
    required this.icon,
    this.semanticsLabel,
    this.semanticsIdentifier,
    super.key,
  });
  final VoidCallback onClicked;
  final Widget icon;
  final String? semanticsLabel;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100, maxWidth: 100),
      child: Center(
        child: BetterPlayerMaterialClickableWidget(
          onTap: onClicked,
          semanticsLabel: semanticsLabel,
          semanticsIdentifier: semanticsIdentifier,
          child: icon,
        ),
      ),
    );
  }
}

class _BetterPlayerMaterialReplayButton extends StatelessWidget {
  const _BetterPlayerMaterialReplayButton({
    required this.controlsConfiguration,
    required this.onReplay,
    required this.latestValue,
    required this.isVideoFinished,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onReplay;
  final VideoPlayerValue? latestValue;
  final bool isVideoFinished;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final isPlaying = controller.videoPlayerValue?.isPlaying == true;
    final isFullScreen = controller.isFullScreen;

    final iconSize = isFullScreen ? 56.0 : 42.0;
    final padding = isFullScreen ? 14.0 : 10.0;

    var semanticsLabel = isPlaying
        ? controller.translations.controlsPauseLabel
        : controller.translations.controlsPlayLabel;
    if (isVideoFinished) {
      semanticsLabel = controller.translations.controlsPlayLabel;
    }

    if (isVideoFinished && !controlsConfiguration.enableReplay) {
      return const SizedBox();
    }
    if (!isVideoFinished && !controlsConfiguration.enablePlayPause) {
      return const SizedBox();
    }

    return _BetterPlayerMaterialHitAreaClickableButton(
      key: const Key('better_player_material_controls_replay_button'),
      semanticsLabel: semanticsLabel,
      semanticsIdentifier: 'better_player_material_controls_replay_button',
      icon: Ink(
        padding: EdgeInsets.all(padding),
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isVideoFinished
                ? Icons.replay
                : (isPlaying
                      ? controlsConfiguration.pauseIcon
                      : controlsConfiguration.playIcon),
            key: ValueKey<bool>(isPlaying),
            size: iconSize,
            color: controlsConfiguration.iconsColor,
          ),
        ),
      ),
      onClicked: onReplay,
    );
  }
}
