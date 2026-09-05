import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/web_video_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class BetterPlayerWeb extends BetterPlayerPlatform {
  /// Called by the plugin system to register this implementation.
  static void registerWith(Registrar registrar) {
    BetterPlayerPlatform.instance = BetterPlayerWeb();
  }

  // Map from textureId (we use int counter) to player instance
  final Map<int, WebVideoPlayer> _players = {};
  int _nextId = 0;

  WebVideoPlayer _player(int? textureId) {
    final player = _players[textureId];
    if (player == null) throw StateError('No player for textureId $textureId');
    return player;
  }

  @override
  Future<int?> create({BufferingConfiguration? bufferingConfiguration}) async {
    final id = _nextId++;
    final viewId = 'better_player_web_$id';

    final player = WebVideoPlayer(viewId: viewId);
    player.initialize();

    // Register the video element as a Flutter platform view
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
      return player.videoElement;
    });

    _players[id] = player;
    return id;
  }

  @override
  Future<void> dispose(int? textureId) async {
    await _player(textureId).dispose();
    _players.remove(textureId);
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    await _player(textureId).setDataSource(dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _player(textureId).events;
  }

  @override
  Future<void> play(int? textureId) async => _player(textureId).play();

  @override
  Future<void> pause(int? textureId) async => _player(textureId).pause();

  @override
  Future<void> setVolume(int? textureId, double volume) async =>
      _player(textureId).setVolume(volume);

  @override
  Future<void> setSpeed(int? textureId, double speed) async =>
      _player(textureId).setSpeed(speed);

  @override
  Future<void> setLooping(int? textureId, bool looping) async =>
      _player(textureId).setLooping(looping);

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (position != null) _player(textureId).seekTo(position);
  }

  @override
  Future<Duration> getPosition(int? textureId) async =>
      _player(textureId).getPosition();

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async =>
      _player(textureId).getAbsolutePosition();

  @override
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) async {
    _player(textureId).setTrackParameters(width, height, bitrate);
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async =>
      _player(textureId).setAudioTrack(name, index);

  @override
  Future<void> enablePictureInPicture(
    int? textureId,
    double? top,
    double? left,
    double? width,
    double? height,
  ) async {
    await _player(textureId).enablePictureInPicture();
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) async =>
      _player(textureId).disablePictureInPicture();

  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async =>
      _player(textureId).isPictureInPictureSupported();

  @override
  Widget buildView(int? textureId) {
    final viewId = _player(textureId).viewId;
    return HtmlElementView(viewType: viewId);
  }

  // ── No-ops (not applicable on web) ─────────────────────────────────────

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) async {}

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {}

  @override
  Future<void> setupLogCallback(
    void Function({required int levelIndex, required String message})? callback,
  ) async {
    // Shaka error events wiring
    /*for (final player in _players.values) {
      // player._shakaPlayer needs exposing or setup in web_video_player
    }*/
  }
}
