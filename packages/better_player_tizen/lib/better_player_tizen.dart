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

/// Tizen platform implementation of the Better Player plugin.
class BetterPlayerTizen extends BetterPlayerPlatform {
  /// Creates a new Tizen platform instance.
  BetterPlayerTizen({
    MethodChannel? channel,
    TizenPlayerFactory? playerFactory,
  })  : _channel = channel ?? const MethodChannel('better_player_tizen'),
        _playerFactory = playerFactory ?? _defaultPlayerFactory;

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
      final result =
          await _channel.invokeMapMethod<String, dynamic>('create');
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
      _log(
        message: 'Disposed Tizen player textureId: $textureId',
        levelIndex: 1,
      );
    }
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    _log(
      message: 'setDataSource: textureId=$textureId, url=${dataSource.url}',
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
          'setTrackParameters: textureId=$textureId, width=$width, height=$height, bitrate=$bitrate',
      levelIndex: 0,
    );
    await getPlayer(textureId)?.setTrackParameters(
      width: width ?? 0,
      height: height ?? 0,
      bitrate: bitrate ?? 0,
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
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }
}
