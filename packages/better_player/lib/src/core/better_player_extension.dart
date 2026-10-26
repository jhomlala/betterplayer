import 'package:better_player/src/core/better_player_controller.dart';
import 'package:flutter/widgets.dart';

/// Base contract for BetterPlayer extensions.
abstract class BetterPlayerExtension {
  /// Creates a BetterPlayer extension.
  const BetterPlayerExtension();

  /// Called when the extension attaches to [BetterPlayerController].
  void onAttach(BetterPlayerController controller);

  /// Called when the extension detaches from [BetterPlayerController] or on controller disposal.
  void onDetach(BetterPlayerController controller);

  /// Optional overlay widget rendered above the video surface and below controls.
  Widget? get overlayWidget => null;
}
