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

typedef WebPlayerFactory = BetterPlayerWebPlayer Function({
  required String viewId,
  required void Function(String) onLog,
});

class BetterPlayerWeb extends BetterPlayerPlatform {
  BetterPlayerWeb({WebPlayerFactory? playerFactory})
    : _playerFactory =
          playerFactory ??
          (({required viewId, required onLog}) =>
              BetterPlayerWebPlayer(viewId: viewId, onLog: onLog));

  /// Called by the plugin system to register this implementation.
  static void registerWith(Registrar registrar) {
    BetterPlayerPlatform.instance = BetterPlayerWeb();
  }

  final WebPlayerFactory _playerFactory;

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
    logWeb('Creating player with id: $id');
    final viewId = 'better_player_web_$id';

    final player = _playerFactory(viewId: viewId, onLog: logWeb);
    logWeb('Initializing player: $viewId');
    player.initialize();

    // Register the video element as a Flutter platform view
    logWeb('Registering view factory for: $viewId');
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
      return player.videoElement;
    });

    _players[id] = player;
    logWeb('Player created and registered: $id');
    return id;
  }

  @override
  Future<void> dispose(int? textureId) async {
    logWeb('Disposing player: $textureId');
    await _getPlayer(textureId).dispose();
    _players.remove(textureId);
    logWeb('Player disposed: $textureId');
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    logWeb('Setting data source for player $textureId: ${dataSource.uri}');
    await _getPlayer(textureId).setDataSource(dataSource);
    logWeb('Data source set for player $textureId');
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _getPlayer(textureId).events;
  }

  @override
  Future<void> play(int? textureId) async {
    logWeb('Play called for player: $textureId');
    return _getPlayer(textureId).play();
  }

  @override
  Future<void> pause(int? textureId) async {
    logWeb('Pause called for player: $textureId');
    return _getPlayer(textureId).pause();
  }

  @override
  Future<void> setVolume(int? textureId, double volume) async {
    logWeb('SetVolume called for player $textureId: $volume');
    return _getPlayer(textureId).setVolume(volume);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    logWeb('SetSpeed called for player $textureId: $speed');
    return _getPlayer(textureId).setSpeed(speed);
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    logWeb('SetLooping called for player $textureId: $looping');
    return _getPlayer(textureId).setLooping(looping);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    logWeb('SeekTo called for player $textureId: $position');
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
