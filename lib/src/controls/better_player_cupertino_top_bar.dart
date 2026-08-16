import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoTopBar extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final double buttonPadding;
  final double marginSize;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onExpandCollapse;
  final VoidCallback onShowMoreClicked;
  final VoidCallback onMute;
  final VideoPlayerValue? latestValue;

  const BetterPlayerCupertinoTopBar({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.buttonPadding,
    required this.marginSize,
    required this.backgroundColor,
    required this.iconColor,
    required this.onExpandCollapse,
    required this.onShowMoreClicked,
    required this.onMute,
    required this.latestValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }

    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          if (controlsConfiguration.enableFullscreen)
            _BetterPlayerCupertinoExpandButton(
              controller: controller,
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              buttonPadding: buttonPadding,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              onExpandCollapse: onExpandCollapse,
            )
          else
            const SizedBox(),
          const SizedBox(width: 4),
          if (controlsConfiguration.enablePip)
            _BetterPlayerCupertinoPipButton(
              controller: controller,
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              buttonPadding: buttonPadding,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
            )
          else
            const SizedBox(),
          const Spacer(),
          if (controlsConfiguration.enableMute)
            _BetterPlayerCupertinoMuteButton(
              controller: controller,
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              buttonPadding: buttonPadding,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              onMute: onMute,
              latestValue: latestValue,
            )
          else
            const SizedBox(),
          const SizedBox(width: 4),
          if (controlsConfiguration.enableOverflowMenu)
            _BetterPlayerCupertinoMoreButton(
              controller: controller,
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              buttonPadding: buttonPadding,
              backgroundColor: backgroundColor,
              iconColor: iconColor,
              onShowMoreClicked: onShowMoreClicked,
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}

class _BetterPlayerCupertinoExpandButton extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final double buttonPadding;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onExpandCollapse;

  const _BetterPlayerCupertinoExpandButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.buttonPadding,
    required this.backgroundColor,
    required this.iconColor,
    required this.onExpandCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpandCollapse,
      child: Semantics(
        label: controller.isFullScreen
            ? controller.translations.controlsExitFullscreenLabel
            : controller.translations.controlsFullscreenLabel,
        button: true,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsHideTime,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.symmetric(horizontal: buttonPadding),
              decoration: BoxDecoration(color: backgroundColor),
              child: Center(
                child: Icon(
                  controller.isFullScreen
                      ? controlsConfiguration.fullscreenDisableIcon
                      : controlsConfiguration.fullscreenEnableIcon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoPipButton extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final double buttonPadding;
  final Color backgroundColor;
  final Color iconColor;

  const _BetterPlayerCupertinoPipButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.buttonPadding,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: controller.isPictureInPictureSupported(),
      builder: (context, snapshot) {
        final isPipSupported = snapshot.data ?? false;
        if (isPipSupported && controller.betterPlayerGlobalKey != null) {
          return GestureDetector(
            onTap: () => controller.enablePictureInPicture(
              controller.betterPlayerGlobalKey!,
            ),
            child: Semantics(
              label: controller.translations.controlsPipLabel,
              button: true,
              child: AnimatedOpacity(
                opacity: controlsNotVisible ? 0.0 : 1.0,
                duration: controlsConfiguration.controlsHideTime,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: barHeight,
                    padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                    decoration: BoxDecoration(
                      color: backgroundColor.withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Icon(
                        controlsConfiguration.pipMenuIcon,
                        color: iconColor,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class _BetterPlayerCupertinoMuteButton extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final double buttonPadding;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onMute;
  final VideoPlayerValue? latestValue;

  const _BetterPlayerCupertinoMuteButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.buttonPadding,
    required this.backgroundColor,
    required this.iconColor,
    required this.onMute,
    required this.latestValue,
  });

  @override
  Widget build(BuildContext context) {
    final isMuted = latestValue != null && latestValue!.volume == 0;
    final semanticsLabel = isMuted
        ? controller.translations.controlsUnmuteLabel
        : controller.translations.controlsMuteLabel;

    return GestureDetector(
      onTap: onMute,
      child: Semantics(
        label: semanticsLabel,
        button: true,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsHideTime,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(color: backgroundColor),
              child: Container(
                height: barHeight,
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                child: Icon(
                  (latestValue != null && latestValue!.volume > 0)
                      ? controlsConfiguration.muteIcon
                      : controlsConfiguration.unMuteIcon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoMoreButton extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final double buttonPadding;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onShowMoreClicked;

  const _BetterPlayerCupertinoMoreButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.buttonPadding,
    required this.backgroundColor,
    required this.iconColor,
    required this.onShowMoreClicked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onShowMoreClicked,
      child: Semantics(
        label: controller.translations.overflowMenuLabel,
        button: true,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsHideTime,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(color: backgroundColor),
              child: Container(
                height: barHeight,
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                child: Icon(
                  controlsConfiguration.overflowMenuIcon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
