import 'package:better_player/better_player.dart';
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
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }
}
