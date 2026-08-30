import 'dart:async';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';

class MockBetterPlayerPlatform extends BetterPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};

  @override
  Future<void> dispose(int? textureId) async {
    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    const textureId = 1;
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();
    return textureId;
  }

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) async {}

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {}

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    if (textureId != null) {
      sendEvent(
        textureId,
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 10),
          size: const Size(1280, 720),
          key: dataSource.key,
        ),
      );
    }
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _eventControllers[textureId]?.stream ?? const Stream.empty();
  }

  void sendEvent(int textureId, VideoEvent event) {
    _eventControllers[textureId]?.add(event);
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
  Future<Duration> getPosition(int? textureId) async {
    return Duration.zero;
  }

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async {
    return null;
  }

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
  Future<bool?> isPictureInPictureSupported(int? textureId) async {
    return false;
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {}

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Widget buildView(int? textureId) {
    return const SizedBox();
  }
}
