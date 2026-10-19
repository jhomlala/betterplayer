import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

/// Test platform interface stub for headless widget tests.
class MockBetterPlayerPlatform extends BetterPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  int _nextId = 1;

  @override
  Future<int?> create({BufferingConfiguration? bufferingConfiguration}) async {
    final id = _nextId++;
    _eventControllers[id] = StreamController<VideoEvent>.broadcast();
    return id;
  }

  @override
  Future<void> dispose(int? textureId) async {
    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    if (textureId != null) {
      Future.microtask(() {
        sendEvent(
          textureId,
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 10),
            size: const Size(1280, 720),
            key: dataSource.key,
          ),
        );
      });
    }
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _eventControllers[textureId]?.stream ?? const Stream.empty();
  }

  void sendEvent(int textureId, VideoEvent event) {
    if (_eventControllers.containsKey(textureId)) {
      _eventControllers[textureId]?.add(event);
    }
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {}

  @override
  Future<void> play(int? textureId) async {}

  @override
  Future<void> pause(int? textureId) async {}

  @override
  Future<void> setVolume(int? textureId, double volume) async {}

  @override
  Future<void> setSpeed(int? textureId, double speed) async {}

  @override
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) async {}

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {}

  @override
  Future<Duration> getPosition(int? textureId) async => Duration.zero;

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async => null;

  @override
  Future<void> enablePictureInPicture(
    int? textureId,
    double? top,
    double? left,
    double? width,
    double? height,
  ) async {}

  @override
  Future<void> disablePictureInPicture(int? textureId) async {}

  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async => false;

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {}

  @override
  Future<void> setTextTrack(int? textureId, String? name, int? index) async {}

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {}

  List<DataSource> preCacheCalls = [];
  List<int> preCacheSizeCalls = [];
  Future<void> Function(
    DataSource dataSource,
    int preCacheSize,
    void Function(PreCacheProgress progress)? onProgress,
  )?
  preCacheHandler;

  @override
  Future<void> preCache(
    DataSource dataSource,
    int preCacheSize, {
    void Function(PreCacheProgress progress)? onProgress,
  }) async {
    preCacheCalls.add(dataSource);
    preCacheSizeCalls.add(preCacheSize);
    if (preCacheHandler != null) {
      await preCacheHandler!(dataSource, preCacheSize, onProgress);
    }
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Widget buildView(int? textureId) => const SizedBox();
}
