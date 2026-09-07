import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/web_video_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void Function({required int levelIndex, required String message})?
_customLogCallback;

void logWeb(String message) {
  if (_customLogCallback != null) {
    _customLogCallback!(levelIndex: 0, message: message);
  }
}

class BetterPlayerWeb extends BetterPlayerPlatform {
  /// Called by the plugin system to register this implementation.
  static void registerWith(Registrar registrar) {
    BetterPlayerPlatform.instance = BetterPlayerWeb();
  }

  // Map from textureId (we use int counter) to player instance
  final Map<int, BetterPlayerWebPlayer> _players = {};
  int _nextId = 0;

  BetterPlayerWebPlayer _getPlayer(int? textureId) {
    final player = _players[textureId];
    if (player == null) throw StateError('No player for textureId $textureId');
    return player;
  }

  @override
  Future<int?> create({BufferingConfiguration? bufferingConfiguration}) async {
    final id = _nextId++;
    final viewId = 'better_player_web_$id';

    final player = BetterPlayerWebPlayer(viewId: viewId, onLog: logWeb);
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
    await _getPlayer(textureId).dispose();
    _players.remove(textureId);
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    await _getPlayer(textureId).setDataSource(dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _getPlayer(textureId).events;
  }

  @override
  Future<void> play(int? textureId) async => _getPlayer(textureId).play();

  @override
  Future<void> pause(int? textureId) async => _getPlayer(textureId).pause();

  @override
  Future<void> setVolume(int? textureId, double volume) async =>
      _getPlayer(textureId).setVolume(volume);

  @override
  Future<void> setSpeed(int? textureId, double speed) async =>
      _getPlayer(textureId).setSpeed(speed);

  @override
  Future<void> setLooping(int? textureId, bool looping) async =>
      _getPlayer(textureId).setLooping(looping);

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (position != null) _getPlayer(textureId).seekTo(position);
  }

  @override
  Future<Duration> getPosition(int? textureId) async =>
      _getPlayer(textureId).getPosition();

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async =>
      _getPlayer(textureId).getAbsolutePosition();

  @override
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) async {
    _getPlayer(
      textureId,
    ).setTrackParameters(width: width, height: height, bitrate: bitrate);
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async =>
      _getPlayer(textureId).setAudioTrack(language: name, index: index);

  @override
  Future<void> enablePictureInPicture(
    int? textureId,
    double? top,
    double? left,
    double? width,
    double? height,
  ) async {
    await _getPlayer(textureId).enablePictureInPicture();
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) async =>
      _getPlayer(textureId).disablePictureInPicture();

  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async =>
      _getPlayer(textureId).isPictureInPictureSupported();

  @override
  Widget buildView(int? textureId) {
    final viewId = _getPlayer(textureId).viewId;
    return HtmlElementView(viewType: viewId);
  }

  // Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ No-ops / Unsupported on web Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) async {
    logWeb('preCache is not supported on web');
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {
    logWeb('stopPreCache is not supported on web');
  }

  @override
  Future<void> clearCache() async {
    logWeb('clearCache is not supported on web');
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {
    logWeb('setMixWithOthers is not supported on web');
  }

  @override
  Future<void> setupLogCallback(
    void Function({required int levelIndex, required String message})? callback,
  ) async {
    _customLogCallback = callback;
    logWeb('Log callback wired up for web');
  }
}
