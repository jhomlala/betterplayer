import 'package:better_player/src/core/better_player_controller.dart';

/// Base contract for BetterPlayer extensions.
abstract class BetterPlayerExtension {
  const BetterPlayerExtension();

  /// Called when the extension attaches to [BetterPlayerController].
  void onAttach(BetterPlayerController controller);

  /// Called when the extension detaches from [BetterPlayerController] or on controller disposal.
  void onDetach(BetterPlayerController controller);
}
