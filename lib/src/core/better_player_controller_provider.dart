import 'package:better_player/src/core/better_player_controller.dart';
import 'package:flutter/material.dart';

///Widget which is used to inherit BetterPlayerController through widget tree.
class BetterPlayerControllerProvider extends InheritedWidget {
  const BetterPlayerControllerProvider({
    required this.controller, required Widget child, Key? key,
  }) : super(key: key, child: child);

  final BetterPlayerController controller;

  @override
  bool updateShouldNotify(BetterPlayerControllerProvider old) =>
      controller != old.controller;
}
