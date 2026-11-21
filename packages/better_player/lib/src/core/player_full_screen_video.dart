import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/player_cupertino_localizations_delegate.dart';
import 'package:better_player/src/controls/player_material_localizations_delegate.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class PlayerFullScreenVideo extends StatelessWidget {
  const PlayerFullScreenVideo({
    required this.controllerProvider,
    super.key,
  });
  final BetterPlayerControllerProvider controllerProvider;

  @override
  Widget build(BuildContext context) {
    final translations = controllerProvider.controller.translations;
    return Localizations.override(
      context: context,
      delegates: [
        PlayerMaterialLocalizationsDelegate(translations),
        PlayerCupertinoLocalizationsDelegate(translations),
      ],
      child: Scaffold(
        backgroundColor: controllerProvider
            .controller
            .betterPlayerControlsConfiguration
            .backgroundColor,
        resizeToAvoidBottomInset: false,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: SizedBox.expand(
            child: controllerProvider,
          ),
        ),
      ),
    );
  }
}
