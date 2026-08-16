import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialTopBar extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onPlayerHide;
  final VoidCallback onShowMoreClicked;

  const BetterPlayerMaterialTopBar({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onPlayerHide,
    required this.onShowMoreClicked,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.controlsEnabled) {
      return const SizedBox();
    }

    return Container(
      child: (controlsConfiguration.enableOverflowMenu)
          ? AnimatedOpacity(
              opacity: controlsNotVisible ? 0.0 : 1.0,
              duration: controlsConfiguration.controlsHideTime,
              onEnd: onPlayerHide,
              child: Container(
                height: controlsConfiguration.controlBarHeight,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (controlsConfiguration.enablePip)
                      _BetterPlayerMaterialPipButtonWrapper(
                        controller: controller,
                        controlsConfiguration: controlsConfiguration,
                        controlsNotVisible: controlsNotVisible,
                        onPlayerHide: onPlayerHide,
                      )
                    else
                      const SizedBox(),
                    _BetterPlayerMaterialMoreButton(
                      controller: controller,
                      controlsConfiguration: controlsConfiguration,
                      onShowMoreClicked: onShowMoreClicked,
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(),
    );
  }
}

class _BetterPlayerMaterialPipButtonWrapper extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final bool controlsNotVisible;
  final VoidCallback onPlayerHide;

  const _BetterPlayerMaterialPipButtonWrapper({
    required this.controller,
    required this.controlsConfiguration,
    required this.controlsNotVisible,
    required this.onPlayerHide,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: controller.isPictureInPictureSupported(),
      builder: (context, snapshot) {
        final isPipSupported = snapshot.data ?? false;
        if (isPipSupported && controller.betterPlayerGlobalKey != null) {
          return AnimatedOpacity(
            opacity: controlsNotVisible ? 0.0 : 1.0,
            duration: controlsConfiguration.controlsHideTime,
            onEnd: onPlayerHide,
            child: Container(
              height: controlsConfiguration.controlBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BetterPlayerMaterialClickableWidget(
                    onTap: () {
                      controller.enablePictureInPicture(
                        controller.betterPlayerGlobalKey!,
                      );
                    },
                    semanticsLabel: controller.translations.controlsPipLabel,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        controlsConfiguration.pipMenuIcon,
                        color: controlsConfiguration.iconsColor,
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

class _BetterPlayerMaterialMoreButton extends StatelessWidget {
  final BetterPlayerController controller;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final VoidCallback onShowMoreClicked;

  const _BetterPlayerMaterialMoreButton({
    required this.controller,
    required this.controlsConfiguration,
    required this.onShowMoreClicked,
  });

  @override
  Widget build(BuildContext context) {
    return BetterPlayerMaterialClickableWidget(
      onTap: onShowMoreClicked,
      semanticsLabel: controller.translations.overflowMenuLabel,
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
