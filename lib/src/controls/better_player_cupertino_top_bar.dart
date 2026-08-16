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

class _BetterPlayerCupertinoPipButton extends StatefulWidget {
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
  State<_BetterPlayerCupertinoPipButton> createState() =>
      _BetterPlayerCupertinoPipButtonState();
}

class _BetterPlayerCupertinoPipButtonState
    extends State<_BetterPlayerCupertinoPipButton> {
  late Future<bool> _isPipSupportedFuture;

  @override
  void initState() {
    super.initState();
    _isPipSupportedFuture = widget.controller.isPictureInPictureSupported();
  }

  @override
  void didUpdateWidget(covariant _BetterPlayerCupertinoPipButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _isPipSupportedFuture = widget.controller.isPictureInPictureSupported();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPipSupportedFuture,
      builder: (context, snapshot) {
        final isPipSupported = snapshot.data ?? false;
        if (isPipSupported && widget.controller.betterPlayerGlobalKey != null) {
          return GestureDetector(
            onTap: () => widget.controller.enablePictureInPicture(
              widget.controller.betterPlayerGlobalKey!,
            ),
            child: Semantics(
              label: widget.controller.translations.controlsPipLabel,
              button: true,
              child: AnimatedOpacity(
                opacity: widget.controlsNotVisible ? 0.0 : 1.0,
                duration: widget.controlsConfiguration.controlsHideTime,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: widget.barHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.buttonPadding,
                    ),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor.withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Icon(
                        widget.controlsConfiguration.pipMenuIcon,
                        color: widget.iconColor,
                        size: widget.iconSize,
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
