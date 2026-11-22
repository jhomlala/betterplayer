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

  /// Whether the remote receiver is currently playing.
  /// Returns null when the extension does not override local playback state.
  bool? get isRemotePlaying => null;

  /// Whether the remote receiver is currently buffering or loading.
  /// Returns null when the extension does not override local buffering state.
  bool? get isRemoteBuffering => null;

  /// Current playback position on the remote receiver.
  /// Returns null when the extension does not report remote position.
  Duration? get remotePosition => null;

  /// Total media duration reported by the remote receiver.
  /// Returns null when the extension does not report remote duration.
  Duration? get remoteDuration => null;

  /// Current volume level (0.0 to 1.0) on the remote receiver.
  /// Returns null when the extension does not report remote volume.
  double? get remoteVolume => null;

  /// Resumes playback on the remote receiver.
  /// Returns true when handled remotely so the local engine stays paused.
  Future<bool> play() async => false;

  /// Pauses playback on the remote receiver.
  /// Returns true when handled remotely.
  Future<bool> pause() async => false;

  /// Seeks to [position] on the remote receiver.
  /// Returns true when handled remotely.
  Future<bool> seekTo(Duration position) async => false;

  /// Sets [volume] (0.0 to 1.0) on the remote receiver.
  /// Returns true when handled remotely.
  Future<bool> setVolume(double volume) async => false;

  @override
  void onAttach(BetterPlayerController controller) {}

  @override
  void onDetach(BetterPlayerController controller) {}
}
