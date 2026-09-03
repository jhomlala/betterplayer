import 'package:better_player/better_player.dart';

class BetterPlayerMockController extends BetterPlayerController {
  BetterPlayerMockController(
    super.betterPlayerConfiguration, {
    PlayerPlaylistConfiguration super.betterPlayerPlaylistConfiguration =
        const PlayerPlaylistConfiguration(),
    super.playerEngineController,
  });
}
