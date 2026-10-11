import 'package:better_player/better_player.dart';

/// Controller coordinating pooled video player instances for a scrolling list.
class ReusableVideoListController {
  /// Creates a controller managing a [BetterPlayerPool].
  ReusableVideoListController({int poolSize = 3})
    : pool = BetterPlayerPool(
        configuration: PlayerPoolConfiguration(
          poolSize: poolSize,
        ),
      );

  /// Underlying bounded player pool.
  final BetterPlayerPool pool;

  /// Disposes all pooled resources.
  void dispose() {
    pool.dispose();
  }
}
