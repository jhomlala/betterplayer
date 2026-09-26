import 'dart:ui';
import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoTopBar extends StatelessWidget {
  const BetterPlayerCupertinoTopBar({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.buttonPadding,
    required this.iconColor,
    required this.onExpandCollapse,
    required this.onShowMoreClicked,
    required this.onMute,
    required this.latestValue,
    super.key,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final double buttonPadding;
  final Color iconColor;
  final VoidCallback onExpandCollapse;
  final VoidCallback onShowMoreClicked;
  final VoidCallback onMute;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }

    final isFullScreen = controller.isFullScreen;
    final horizontalMargin = isFullScreen ? 48.0 : 16.0;
    final topMargin = isFullScreen ? 24.0 : 16.0;

    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: topMargin,
        right: horizontalMargin,
        left: horizontalMargin,
      ),
      child: Row(
        children: <Widget>[
          if (controlsConfiguration.enableFullscreen)
            _BetterPlayerCupertinoExpandButton(
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              iconColor: iconColor,
              onExpandCollapse: onExpandCollapse,
            )
          else
            const SizedBox(),
          const SizedBox(width: 8),
          if (controlsConfiguration.enablePip)
            _BetterPlayerCupertinoPipButton(
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              iconColor: iconColor,
            )
          else
            const SizedBox(),
          const Spacer(),
          if (controlsConfiguration.enableMute)
            _BetterPlayerCupertinoMuteButton(
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
              iconColor: iconColor,
              onMute: onMute,
              latestValue: latestValue,
            )
          else
            const SizedBox(),
          const SizedBox(width: 8),
          if (controlsConfiguration.enableOverflowMenu)
            _BetterPlayerCupertinoMoreButton(
              controlsConfiguration: controlsConfiguration,
              controlsNotVisible: controlsNotVisible,
              barHeight: barHeight,
              iconSize: iconSize,
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
  const _BetterPlayerCupertinoExpandButton({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.iconColor,
    required this.onExpandCollapse,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final Color iconColor;
  final VoidCallback onExpandCollapse;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    return GestureDetector(
      onTap: onExpandCollapse,
      child: Semantics(
        label: controller.isFullScreen
            ? controller.translations.controlsExitFullscreenLabel
            : controller.translations.controlsFullscreenLabel,
        identifier: 'better_player_cupertino_controls_expand_button',
        button: true,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsTransitionTime,
          child: _BetterPlayerCupertinoGlassButton(
            barHeight: barHeight,
            icon: controller.isFullScreen
                ? controlsConfiguration.fullscreenDisableIcon
                : controlsConfiguration.fullscreenEnableIcon,
            iconColor: iconColor,
            iconSize: iconSize,
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoPipButton extends StatefulWidget {
  const _BetterPlayerCupertinoPipButton({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.iconColor,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final Color iconColor;

  @override
  State<_BetterPlayerCupertinoPipButton> createState() =>
      _BetterPlayerCupertinoPipButtonState();
}

class _BetterPlayerCupertinoPipButtonState
    extends State<_BetterPlayerCupertinoPipButton> {
  late Future<bool> _isPipSupportedFuture;

  BetterPlayerController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = BetterPlayerController.of(context);
    if (_controller != newController) {
      _controller = newController;
      _isPipSupportedFuture = _controller!.isPictureInPictureSupported();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    return FutureBuilder<bool>(
      future: _isPipSupportedFuture,
      builder: (context, snapshot) {
        final isPipSupported = snapshot.data ?? false;
        if (isPipSupported && controller.betterPlayerGlobalKey != null) {
          return GestureDetector(
            onTap: () => controller.enablePictureInPicture(
              controller.betterPlayerGlobalKey!,
            ),
            child: Semantics(
              label: controller.translations.controlsPipLabel,
              identifier: 'better_player_cupertino_controls_pip_button',
              button: true,
              child: AnimatedOpacity(
                opacity: widget.controlsNotVisible ? 0.0 : 1.0,
                duration: widget.controlsConfiguration.controlsTransitionTime,
                child: _BetterPlayerCupertinoGlassButton(
                  barHeight: widget.barHeight,
                  icon: widget.controlsConfiguration.pipMenuIcon,
                  iconColor: widget.iconColor,
                  iconSize: widget.iconSize,
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
  const _BetterPlayerCupertinoMuteButton({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.iconColor,
    required this.onMute,
    required this.latestValue,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final Color iconColor;
  final VoidCallback onMute;
  final VideoPlayerValue? latestValue;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final isMuted = latestValue != null && latestValue!.volume == 0;
    final semanticsLabel = isMuted
        ? controller.translations.controlsUnmuteLabel
        : controller.translations.controlsMuteLabel;

    return GestureDetector(
      onTap: onMute,
      child: Semantics(
        label: semanticsLabel,
        identifier: 'better_player_cupertino_controls_mute_button',
        button: true,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsTransitionTime,
          child: _BetterPlayerCupertinoGlassButton(
            barHeight: barHeight,
            icon: (latestValue != null && latestValue!.volume > 0)
                ? controlsConfiguration.muteIcon
                : controlsConfiguration.unMuteIcon,
            iconColor: iconColor,
            iconSize: iconSize,
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoMoreButton extends StatelessWidget {
  const _BetterPlayerCupertinoMoreButton({
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.barHeight,
    required this.iconSize,
    required this.iconColor,
    required this.onShowMoreClicked,
  });
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final double barHeight;
  final double iconSize;
  final Color iconColor;
  final VoidCallback onShowMoreClicked;

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    return GestureDetector(
      onTap: onShowMoreClicked,
      child: Semantics(
        label: controller.translations.overflowMenuLabel,
        identifier: 'better_player_cupertino_controls_more_button',
        button: true,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: controlsConfiguration.controlsTransitionTime,
          child: _BetterPlayerCupertinoGlassButton(
            barHeight: barHeight,
            icon: controlsConfiguration.overflowMenuIcon,
            iconColor: iconColor,
            iconSize: iconSize,
          ),
        ),
      ),
    );
  }
}

class _BetterPlayerCupertinoGlassButton extends StatelessWidget {
  const _BetterPlayerCupertinoGlassButton({
    required this.barHeight,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  final double barHeight;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(48),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: barHeight,
          width: barHeight,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
