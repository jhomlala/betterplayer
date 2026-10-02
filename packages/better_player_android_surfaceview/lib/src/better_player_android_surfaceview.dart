import 'package:better_player_android/better_player_android.dart';
// The JNI bindings are not part of the public API of better_player_android;
// this package is its sibling and ships in the same repository.
// ignore: implementation_imports
import 'package:better_player_android/src/better_player_android_jni.g.dart';
import 'package:better_player_android_surfaceview/src/surface_video_view.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:jni_flutter/jni_flutter.dart';

/// [BetterPlayerAndroid] that renders video through a native `SurfaceView`
/// instead of Flutter's `Texture`.
///
/// Register it in `main()`, before `runApp()`:
///
/// ```dart
/// BetterPlayerAndroidSurfaceView.registerWith();
/// ```
///
/// Everything except how pixels reach the screen is inherited from
/// [BetterPlayerAndroid]. Trade-offs of a SurfaceView: it punches a hole in
/// the Flutter window, so `ClipRRect`, opacity and transforms do not apply
/// to the video, and overlays are composited by hybrid composition.
class BetterPlayerAndroidSurfaceView extends BetterPlayerAndroid {
  /// Makes this the default [BetterPlayerPlatform] instance.
  static void registerWith() {
    BetterPlayerPlatform.instance = BetterPlayerAndroidSurfaceView();
  }

  /// Whether players created from now on use a SurfaceView. Defaults to
  /// `true`; set it to `false` to fall back to the Texture pipeline for
  /// players created next, e.g. to try Texture first and SurfaceView only
  /// after it fails.
  ///
  /// Read synchronously inside `create()` before its first `await`, so set it
  /// right before the call that creates the player and restore it right
  /// after.
  static bool useSurfaceViewForNewPlayers = true;

  /// Whether [textureId] is rendered through a SurfaceView, as opposed to a
  /// Texture. False for unknown ids and when the platform instance is not a
  /// [BetterPlayerAndroidSurfaceView].
  static bool isSurfaceView(int? textureId) {
    final platform = BetterPlayerPlatform.instance;
    return platform is BetterPlayerAndroidSurfaceView &&
        platform._surfaceViewIds.contains(textureId);
  }

  final Set<int> _surfaceViewIds = {};
  bool _lastCreatedWasSurfaceView = false;

  @override
  dynamic createJniPlayer(dynamic callback) {
    _lastCreatedWasSurfaceView = useSurfaceViewForNewPlayers;
    return _lastCreatedWasSurfaceView
        ? createSurfaceViewJniPlayer(callback)
        : createTextureJniPlayer(callback);
  }

  @override
  int getTextureIdFromPlayer(dynamic player) {
    final id = readPlayerId(player);
    if (_lastCreatedWasSurfaceView) _surfaceViewIds.add(id);
    return id;
  }

  @override
  Future<void> dispose(int? textureId) async {
    _surfaceViewIds.remove(textureId);
    await super.dispose(textureId);
  }

  @override
  Widget buildView(int? textureId) {
    if (_surfaceViewIds.contains(textureId)) {
      return SurfaceVideoView(playerId: textureId!);
    }
    return super.buildView(textureId);
  }

  @visibleForTesting
  dynamic createSurfaceViewJniPlayer(dynamic callback) {
    return BetterPlayerApi.Companion.createSurfacePlayer(
      androidApplicationContext as Context,
      callback as BetterPlayerCallback,
    );
  }

  @visibleForTesting
  dynamic createTextureJniPlayer(dynamic callback) {
    return BetterPlayerApi.Companion.createPlayer(
      androidApplicationContext as Context,
      callback as BetterPlayerCallback,
    );
  }

  @visibleForTesting
  int readPlayerId(dynamic player) => (player as BetterPlayer).textureId;
}
