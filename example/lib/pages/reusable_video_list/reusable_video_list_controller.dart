import 'package:better_player/better_player.dart';
import 'package:collection/collection.dart' show IterableExtension;

class ReusableVideoListController {
  ReusableVideoListController() {
    for (var index = 0; index < 3; index++) {
      _betterPlayerControllerRegistry.add(
        BetterPlayerController(
          const BetterPlayerConfiguration(
              handleLifecycle: false, autoDispose: false),
        ),
      );
    }
  }
  final List<BetterPlayerController> _betterPlayerControllerRegistry = [];
  final List<BetterPlayerController> _usedBetterPlayerControllerRegistry = [];

  BetterPlayerController? getBetterPlayerController() {
    final freeController = _betterPlayerControllerRegistry.firstWhereOrNull(
      (controller) => !_usedBetterPlayerControllerRegistry.contains(controller),
    );

    if (freeController != null) {
      _usedBetterPlayerControllerRegistry.add(freeController);
    }

    return freeController;
  }

  void freeBetterPlayerController(
    BetterPlayerController? betterPlayerController,
  ) {
    _usedBetterPlayerControllerRegistry.remove(betterPlayerController);
  }

  void dispose() {
    for (final controller in _betterPlayerControllerRegistry) {
      controller.dispose();
    }
  }
}
