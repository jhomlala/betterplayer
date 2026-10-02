import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_windows/src/mpv/mpv_ffi.dart';
import 'package:better_player_windows/src/mpv/mpv_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef WindowsPlayerFactory =
    Future<BetterPlayerWindowsPlayer> Function({
      BufferingConfiguration? bufferingConfiguration,
    });

/// Windows platform implementation for Better Player.
class BetterPlayerWindows extends BetterPlayerPlatform {
  BetterPlayerWindows({
    MethodChannel? channel,
    WindowsPlayerFactory? playerFactory,
  }) : _channel = channel ?? const MethodChannel('better_player_windows') {
    _playerFactory = playerFactory ?? _defaultPlayerFactory;
  }

  static void registerWith() {
    BetterPlayerPlatform.instance = BetterPlayerWindows();
  }

  final MethodChannel _channel;
  late final WindowsPlayerFactory _playerFactory;
  final Map<int, BetterPlayerWindowsPlayer> _players = {};

  void Function({required int levelIndex, required String message})?
  _logCallback;

  void _log({required String message, int levelIndex = 0}) {
    _logCallback?.call(levelIndex: levelIndex, message: message);
  }

  @visibleForTesting
  void registerPlayer({
    required int textureId,
    required BetterPlayerWindowsPlayer player,
  }) {
    _players[textureId] = player;
  }

  @visibleForTesting
  BetterPlayerWindowsPlayer? getPlayer(int? textureId) {
    if (textureId == null) return null;
    return _players[textureId];
  }

  Future<BetterPlayerWindowsPlayer> _defaultPlayerFactory({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>('create');
    final textureId = result?['textureId'] as int?;
    final mpvHandleAddress = result?['mpvHandle'] as int?;

    if (textureId == null || mpvHandleAddress == null) {
      throw PlatformException(
        code: 'CREATION_FAILED',
        message: 'Failed to create native Windows texture and mpv context.',
      );
    }

    final handle = ffi.Pointer<MpvHandle>.fromAddress(mpvHandleAddress);
    return MpvPlayer(textureId: textureId, handle: handle);
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
      final player = await _playerFactory(
        bufferingConfiguration: bufferingConfiguration,
      );
      final textureId = player.textureId;
      _players[textureId] = player;
      _log(message: 'Created player with textureId: $textureId', levelIndex: 1);
      return textureId;
    } catch (e, stackTrace) {
      _log(message: 'Error creating player: $e\n$stackTrace', levelIndex: 3);
      rethrow;
    }
  }

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) return;
    final player = _players.remove(textureId);
    if (player != null) {
      await player.dispose();
      await _channel.invokeMethod<void>('dispose', {'textureId': textureId});
      _log(message: 'Disposed player textureId: $textureId', levelIndex: 1);
    }
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    final player = getPlayer(textureId);
    if (player == null) return;
    await player.setDataSource(dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    final player = getPlayer(textureId);
    return player?.events ?? const Stream.empty();
  }

  @override
  Future<void> play(int? textureId) async {
    await getPlayer(textureId)?.play();
  }

  @override
  Future<void> pause(int? textureId) async {
    await getPlayer(textureId)?.pause();
  }

  @override
  Future<void> setVolume(int? textureId, double volume) async {
    await getPlayer(textureId)?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    await getPlayer(textureId)?.setSpeed(speed);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (position == null) return;
    await getPlayer(textureId)?.seekTo(position);
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    final player = getPlayer(textureId);
    if (player == null) return Duration.zero;
    return player.getPosition();
  }

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async {
    return null;
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    await getPlayer(textureId)?.setLooping(looping: looping);
  }

  @override
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) async {
    await getPlayer(textureId)?.setTrackParameters(
      width: width ?? 0,
      height: height ?? 0,
      bitrate: bitrate ?? 0,
    );
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {
    await getPlayer(
      textureId,
    )?.setAudioTrack(name: name ?? '', index: index ?? 0);
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {
    // libmpv mixes with system audio automatically
  }

  @override
  Future<void> clearCache() async {
    // Cache clearing is managed by mpv or local temporary directories
  }

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) async {
    // mpv supports network demuxer buffering out of the box
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {
    // No-op for demuxer-based buffering
  }

  @override
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }
}
