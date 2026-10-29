import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_extension.dart';

/// Contract for casting extensions such as Chromecast or DLNA.
///
/// Lets third-party or companion packages integrate with Better Player
/// without adding dependencies to the core library.
abstract class PlayerCastExtension extends BetterPlayerExtension {
  /// Creates a cast extension.
  const PlayerCastExtension();

  /// Whether video currently casts to an external receiver.
  bool get isCasting => false;

  /// Stream that emits changes to the casting state.
  Stream<bool> get castingStream => const Stream<bool>.empty();

  /// Name of the target device that receives the stream.
  String? get targetDeviceName => null;

  /// Shows the device picker or connection interface.
  Future<void> showCastPicker();

  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}
