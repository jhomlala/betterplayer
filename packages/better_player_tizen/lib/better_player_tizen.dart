import 'dart:async';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_tizen/src/player_tizen.dart';
import 'package:better_player_tizen/src/player_tizen_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Factory signature for creating a [PlayerTizen] instance.
typedef TizenPlayerFactory =
    Future<PlayerTizen> Function({
      required int textureId,
      BufferingConfiguration? bufferingConfiguration,
    });

/// Signature for custom Tizen view building, primarily for testing or custom renderers.
typedef TizenViewBuilder = Widget Function(int textureId);

/// Tizen platform implementation of the Better Player plugin.
class BetterPlayerTizen extends BetterPlayerPlatform {
  /// Creates a new Tizen platform instance.
  BetterPlayerTizen({
    MethodChannel? channel,
    TizenPlayerFactory? playerFactory,
    this.viewBuilder,
  }) : _channel = channel ?? const MethodChannel('better_player_tizen'),
       _playerFactory = playerFactory ?? _defaultPlayerFactory {
    _cleanupOrphanedPlayers();
  }

  Future<void>? _cleanupFuture;

  void _cleanupOrphanedPlayers() {
    _cleanupFuture = _channel
        .invokeMethod<void>('clear')
        .catchError((Object _) {})
        .whenComplete(() => _cleanupFuture = null);
  }

  /// Registers this class as the default instance of [BetterPlayerPlatform].
  static void register() {
    registerWith();
  }

  /// Registers this implementation with the platform interface.
  static void registerWith() {
    BetterPlayerPlatform.instance = BetterPlayerTizen();
  }

  final MethodChannel _channel;
  final TizenPlayerFactory _playerFactory;
  final Map<int, PlayerTizen> _players = <int, PlayerTizen>{};

  void Function({required int levelIndex, required String message})?
  _logCallback;

  void _log({required String message, required int levelIndex}) {
    _logCallback?.call(levelIndex: levelIndex, message: message);
  }

  static Future<PlayerTizen> _defaultPlayerFactory({
    required int textureId,
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    return PlayerTizenController(textureId: textureId);
  }

  /// Returns the player instance associated with [textureId].
  @visibleForTesting
  PlayerTizen? getPlayer(int? textureId) {
    if (textureId == null) {
      return null;
    }
    return _players[textureId];
  }

  /// Registers a player instance for testing.
  @visibleForTesting
  void registerPlayer({
    required int textureId,
    required PlayerTizen player,
  }) {
    _players[textureId] = player;
  }

  @override
  Future<void> setupLogCallback(
    void Function({
      required int levelIndex,
      required String message,
    })?
    callback,
  ) async {
    _logCallback = callback;
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    try {
      if (_cleanupFuture != null) {
        await _cleanupFuture;
      }
      final result = await _channel.invokeMapMethod<String, dynamic>('create');
      final textureId = result?['textureId'] as int?;
      if (textureId == null) {
        throw PlatformException(
          code: 'CREATION_FAILED',
          message: 'Failed to create native Tizen media player instance.',
        );
      }

      final player = await _playerFactory(
        textureId: textureId,
        bufferingConfiguration: bufferingConfiguration,
      );
      _players[textureId] = player;
      _log(
        message: 'Created Tizen player with textureId: $textureId',
        levelIndex: 1,
      );
      return textureId;
    } catch (e, stackTrace) {
      _log(
        message: 'Error creating Tizen player: $e\n$stackTrace',
        levelIndex: 3,
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) {
      return;
    }
    final player = _players.remove(textureId);
    if (player != null) {
      await player.dispose();
    } else {
      await _channel.invokeMethod<void>('dispose', <String, dynamic>{
        'textureId': textureId,
      });
    }
    _log(
      message: 'Disposed Tizen player textureId: $textureId',
      levelIndex: 1,
    );
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    _log(
      message: 'setDataSource: textureId=$textureId, uri=${dataSource.uri}',
      levelIndex: 1,
    );
    final player = getPlayer(textureId);
    if (player == null) {
      return;
    }
    await player.setDataSource(dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    final player = getPlayer(textureId);
    return player?.events ?? const Stream<VideoEvent>.empty();
  }

  @override
  Future<void> play(int? textureId) async {
    _log(message: 'play: textureId=$textureId', levelIndex: 1);
    await getPlayer(textureId)?.play();
  }

  @override
  Future<void> pause(int? textureId) async {
    _log(message: 'pause: textureId=$textureId', levelIndex: 1);
    await getPlayer(textureId)?.pause();
  }

  @override
  Future<void> setVolume(int? textureId, double volume) async {
    _log(
      message: 'setVolume: textureId=$textureId, volume=$volume',
      levelIndex: 0,
    );
    await getPlayer(textureId)?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    _log(
      message: 'setSpeed: textureId=$textureId, speed=$speed',
      levelIndex: 0,
    );
    await getPlayer(textureId)?.setSpeed(speed);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (position == null) {
      return;
    }
    _log(
      message: 'seekTo: textureId=$textureId, position=$position',
      levelIndex: 1,
    );
    await getPlayer(textureId)?.seekTo(position);
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    final player = getPlayer(textureId);
    if (player == null) {
      return Duration.zero;
    }
    return player.getPosition();
  }

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async {
    return null;
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    _log(
      message: 'setLooping: textureId=$textureId, looping=$looping',
      levelIndex: 1,
    );
    await getPlayer(textureId)?.setLooping(looping: looping);
  }

  @override
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) async {
    _log(
      message:
          'setTrackParameters: textureId=$textureId, width=$width, height=$height, bitrate=$bitrate '
          '(adaptive track selection is managed automatically by Tizen player)',
      levelIndex: 0,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAudioTracks(int? textureId) async {
    _log(
      message:
          'getAudioTracks: textureId=$textureId '
          '(not supported in experimental Tizen implementation)',
      levelIndex: 0,
    );
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {
    _log(
      message:
          'setAudioTrack: textureId=$textureId, name=$name, index=$index '
          '(not supported in experimental Tizen implementation)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> setTextTrack(int? textureId, String? name, int? index) async {
    _log(
      message:
          'setTextTrack: textureId=$textureId, name=$name, index=$index '
          '(not supported in experimental Tizen implementation)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {
    _log(
      message:
          'setMixWithOthers: textureId=$textureId, mixWithOthers=$mixWithOthers '
          '(audio policy is managed by Tizen system sound manager)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> setAndroidMatchFrameRate(
    int? textureId,
    bool matchFrameRate,
  ) async {
    _log(
      message:
          'setAndroidMatchFrameRate: textureId=$textureId, matchFrameRate=$matchFrameRate '
          '(frame rate matching is not applicable on Tizen)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> clearCache() async {
    _log(
      message: 'clearCache is not supported on Tizen',
      levelIndex: 0,
    );
  }

  @override
  Future<void> preCache(
    DataSource dataSource,
    int preCacheSize, {
    void Function(PreCacheProgress progress)? onProgress,
  }) async {
    _log(
      message: 'preCache is not supported on Tizen',
      levelIndex: 2,
    );
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {
    _log(
      message: 'stopPreCache is not supported on Tizen',
      levelIndex: 2,
    );
  }

  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async {
    return false;
  }

  @override
  Future<void> enablePictureInPicture(
    int? textureId,
    double? top,
    double? left,
    double? width,
    double? height,
  ) async {
    _log(
      message: 'Picture-in-picture is not supported on Tizen',
      levelIndex: 2,
    );
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) async {
    _log(
      message: 'Picture-in-picture is not supported on Tizen',
      levelIndex: 2,
    );
  }

  @override
  Future<void> setScreenCaptureProtection({required bool enabled}) async {
    _log(
      message:
          'setScreenCaptureProtection: enabled=$enabled '
          '(screen capture protection is not applicable on Tizen)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> showExternalPlaybackPicker({required int? textureId}) async {
    _log(
      message:
          'showExternalPlaybackPicker: textureId=$textureId '
          '(external playback picker is not applicable on Tizen)',
      levelIndex: 0,
    );
  }

  /// Optional custom view builder for testing or custom renderers.
  final TizenViewBuilder? viewBuilder;

  @override
  Widget buildView(int? textureId) {
    if (textureId == null) {
      return const SizedBox.shrink();
    }
    final customBuilder = viewBuilder;
    if (customBuilder != null) {
      return customBuilder(textureId);
    }
    return Texture(textureId: textureId);
  }
}
