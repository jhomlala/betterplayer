import 'package:better_player/src/core/better_player_controller.dart';
import 'package:flutter/material.dart';

class BetterPlayerControllerProvider extends InheritedWidget {
  const BetterPlayerControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final BetterPlayerController controller;

  @override
  bool updateShouldNotify(BetterPlayerControllerProvider old) =>
      controller != old.controller;
}
