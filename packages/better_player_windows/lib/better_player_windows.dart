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

  void _log({required String message, required int levelIndex}) {
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
        message:
            'Failed to create native Windows texture and mpv context: mpv-2.dll not found, see README.',
      );
    }

    final handle = ffi.Pointer<MpvHandle>.fromAddress(mpvHandleAddress);
    return MpvPlayer(
      textureId: textureId,
      handle: handle,
      onLog: _log,
    );
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
      if (bufferingConfiguration != null) {
        _log(
          message:
              'BufferingConfiguration is ignored on Windows (managed by mpv)',
          levelIndex: 0,
        );
      }
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
    _log(
      message: 'setDataSource: textureId=$textureId, dataSource=$dataSource',
      levelIndex: 1,
    );
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
    _log(
      message: 'seekTo: textureId=$textureId, position=$position',
      levelIndex: 1,
    );
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
    _log(
      message:
          'getAbsolutePosition: textureId=$textureId (absolute position not supported on Windows)',
      levelIndex: 0,
    );
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
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {
    _log(
      message: 'setAudioTrack: textureId=$textureId, name=$name, index=$index',
      levelIndex: 0,
    );
    await getPlayer(
      textureId,
    )?.setAudioTrack(name: name ?? '', index: index ?? 0);
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {
    _log(
      message:
          'setMixWithOthers: textureId=$textureId, mixWithOthers=$mixWithOthers '
          '(system audio mixing is handled automatically by mpv)',
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
          '(frame rate matching is not applicable on Windows)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> clearCache() async {
    _log(
      message: 'clearCache (cache lifecycle is managed by mpv)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) async {
    _log(
      message:
          'preCache: url=${dataSource.uri ?? dataSource.asset}, preCacheSize=$preCacheSize '
          '(network demuxer buffering is handled automatically by mpv)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {
    _log(
      message:
          'stopPreCache: url=$url, cacheKey=$cacheKey (demuxer buffering handles cache)',
      levelIndex: 0,
    );
  }

  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async {
    _log(
      message:
          'isPictureInPictureSupported: textureId=$textureId (picture-in-picture is not supported on Windows)',
      levelIndex: 0,
    );
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
      message: 'Picture-in-picture is not supported on Windows',
      levelIndex: 2,
    );
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) async {
    _log(
      message: 'Picture-in-picture is not supported on Windows',
      levelIndex: 2,
    );
  }

  @override
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }
}
