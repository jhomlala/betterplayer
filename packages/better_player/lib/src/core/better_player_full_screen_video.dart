import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerFullScreenVideo extends StatelessWidget {
  const BetterPlayerFullScreenVideo({
    required this.controllerProvider,
    super.key,
  });
  final BetterPlayerControllerProvider controllerProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SizedBox.expand(
          child: controllerProvider,
        ),
      ),
    );
  }
}
