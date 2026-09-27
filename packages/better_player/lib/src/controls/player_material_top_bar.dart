import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

class PlayerMaterialTopBar extends StatelessWidget {
  const PlayerMaterialTopBar({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onPlayerHide,
    required this.onShowMoreClicked,
    super.key,
  });
  final BetterPlayerController controller;
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onPlayerHide;
  final VoidCallback onShowMoreClicked;

  @override
  Widget build(BuildContext context) {
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }

    return Container(
      child: (controlsConfiguration.enableOverflowMenu)
          ? AnimatedOpacity(
              opacity: controlsNotVisible ? 0.0 : 1.0,
              duration: controlsConfiguration.controlsTransitionTime,
              onEnd: onPlayerHide,
              child: AnimatedSlide(
                offset: controlsNotVisible
                    ? const Offset(0, -0.2)
                    : Offset.zero,
                duration: controlsConfiguration.controlsTransitionTime,
                curve: Curves.easeOut,
                child: SizedBox(
                  height: controlsConfiguration.controlBarHeight,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (controlsConfiguration.enablePip)
                          _PlayerMaterialPipButtonWrapper(
                            controller: controller,
                            controlsConfiguration: controlsConfiguration,
                            controlsNotVisible: controlsNotVisible,
                            onPlayerHide: onPlayerHide,
                          )
                        else
                          const SizedBox(),
                        _PlayerMaterialMoreButton(
                          controller: controller,
                          controlsConfiguration: controlsConfiguration,
                          onShowMoreClicked: onShowMoreClicked,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(),
    );
  }
}

class _PlayerMaterialPipButtonWrapper extends StatefulWidget {
  const _PlayerMaterialPipButtonWrapper({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onPlayerHide,
  });
  final BetterPlayerController controller;
  final PlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onPlayerHide;

  @override
  State<_PlayerMaterialPipButtonWrapper> createState() =>
      _PlayerMaterialPipButtonWrapperState();
}

class _PlayerMaterialPipButtonWrapperState
    extends State<_PlayerMaterialPipButtonWrapper> {
  late Future<bool> _isPipSupportedFuture;

  @override
  void initState() {
    super.initState();
    _isPipSupportedFuture = widget.controller.isPictureInPictureSupported();
  }

  @override
  void didUpdateWidget(
    covariant _PlayerMaterialPipButtonWrapper oldWidget,
  ) {
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
          return AnimatedOpacity(
            opacity: widget.controlsNotVisible ? 0.0 : 1.0,
            duration: widget.controlsConfiguration.controlsTransitionTime,
            onEnd: widget.onPlayerHide,
            child: SizedBox(
              height: widget.controlsConfiguration.controlBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayerMaterialClickableWidget(
                    onTap: () {
                      widget.controller.enablePictureInPicture(
                        widget.controller.betterPlayerGlobalKey!,
                      );
                    },
                    semanticsLabel:
                        widget.controller.translations.controlsPipLabel,
                    semanticsIdentifier:
                        'better_player_material_controls_pip_button',
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        widget.controlsConfiguration.pipMenuIcon,
                        color: widget.controlsConfiguration.iconsColor,
                      ),
                    ),
                  ),
                ],
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

class _PlayerMaterialMoreButton extends StatelessWidget {
  const _PlayerMaterialMoreButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.onShowMoreClicked,
  });
  final BetterPlayerController controller;
  final PlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onShowMoreClicked;

  @override
  Widget build(BuildContext context) {
    return PlayerMaterialClickableWidget(
      onTap: onShowMoreClicked,
      semanticsLabel: controller.translations.overflowMenuLabel,
      semanticsIdentifier: 'better_player_material_controls_more_button',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          controlsConfiguration.overflowMenuIcon,
          color: controlsConfiguration.iconsColor,
        ),
      ),
    );
  }
}
