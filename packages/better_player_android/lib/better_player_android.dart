import 'dart:async';

import 'package:better_player_android/src/better_player_android_jni.g.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';

class BetterPlayerAndroid extends BetterPlayerPlatform {
  /// Registers this class as the default instance of [BetterPlayerPlatform].
  static void registerWith() {
    BetterPlayerPlatform.instance = BetterPlayerAndroid();
  }

  final Map<int, BetterPlayerWrapper> _players = {};
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, dynamic> _callbacks = {};

  @override
  Future<void> init() async {
    // Usually nothing globally required for Android initialization
    // unless clearing global caches.
  }

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) return;
    _players[textureId]?.dispose();
    _players[textureId]?.release();
    _players.remove(textureId);

    try {
      _callbacks[textureId]?.release();
    } catch (_) {}
    _callbacks.remove(textureId);

    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    final callback = buildCallback(
      $BetterPlayerCallback(
        onInitialized: (int durationMs, int width, int height, JString? key) {
          // Broadcast to all since we don't know textureId yet, or match by key.
          final videoEvent = VideoEvent(
            eventType: VideoEventType.initialized,
            key: key?.toDartString(),
            duration: Duration(milliseconds: durationMs),
            size: Size(width.toDouble(), height.toDouble()),
          );
          for (final controller in _eventControllers.values) {
            controller.add(videoEvent);
          }
        },
        onInitialized$async: true,
        onCompleted: (JString? key) {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(
                eventType: VideoEventType.completed,
                key: key?.toDartString(),
              ),
            );
          }
        },
        onCompleted$async: true,
        onPlay: () {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(eventType: VideoEventType.play, key: null),
            );
          }
        },
        onPlay$async: true,
        onPause: () {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(eventType: VideoEventType.pause, key: null),
            );
          }
        },
        onPause$async: true,
        onSeek: (int positionMs) {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(
                eventType: VideoEventType.seek,
                key: null,
                position: Duration(milliseconds: positionMs),
              ),
            );
          }
        },
        onSeek$async: true,
        onBufferingStart: () {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(eventType: VideoEventType.bufferingStart, key: null),
            );
          }
        },
        onBufferingStart$async: true,
        onBufferingEnd: () {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(eventType: VideoEventType.bufferingEnd, key: null),
            );
          }
        },
        onBufferingEnd$async: true,
        onBufferingUpdate: (int bufferedMs) {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                key: null,
                buffered: [
                  DurationRange(
                    Duration.zero,
                    Duration(milliseconds: bufferedMs),
                  ),
                ],
              ),
            );
          }
        },
        onBufferingUpdate$async: true,
        onPipStart: () {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(eventType: VideoEventType.pipStart, key: null),
            );
          }
        },
        onPipStart$async: true,
        onPipStop: () {
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(eventType: VideoEventType.pipStop, key: null),
            );
          }
        },
        onPipStop$async: true,
        onChangedSize: (int width, int height, JString? key) {
          // Internal usage, you can emit an event or handled it differently if needed.
          // Wait, better_player doesn't have a changedSize VideoEventType.
        },
        onChangedSize$async: true,
        onError:
            (JString errorCode, JString errorMessage, JString errorDetails) {
              for (final controller in _eventControllers.values) {
                controller.addError(
                  PlatformException(
                    code: errorCode.toDartString(),
                    message: errorMessage.toDartString(),
                    details: errorDetails.toDartString(),
                  ),
                );
              }
            },
        onError$async: true,
      ),
    );

    final player = createJniPlayer(callback);
    if (player == null) return null;

    final textureId = player.textureId;
    _players[textureId] = createWrapper(player);
    _callbacks[textureId] = callback;
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();

    return textureId;
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    final player = _players[textureId];
    if (player == null) return;

    // Convert headers to JMap
    JMap<JString, JString>? headersMap;
    if (dataSource.headers != null) {
      headersMap = (JHashMap() as JObject) as JMap<JString, JString>;
      dataSource.headers!.forEach((k, v) {
        headersMap!.put(k.toJString(), (v?.toString() ?? '').toJString());
      });
    }

    JMap<JString, JString>? drmHeadersMap;
    if (dataSource.drmConfiguration?.headers != null) {
      drmHeadersMap = (JHashMap() as JObject) as JMap<JString, JString>;
      dataSource.drmConfiguration!.headers!.forEach((k, v) {
        drmHeadersMap!.put(k.toJString(), v.toJString());
      });
    }

    final uri = (dataSource.uri ?? dataSource.asset ?? '').toJString();

    player.setDataSource(
      androidApplicationContext as Context,
      dataSource.key.toJString(),
      uri,
      dataSource.rawFormalHint?.toJString(),
      headersMap,
      dataSource.cacheConfiguration?.useCache ?? false,
      dataSource.cacheConfiguration?.maxCacheSize ?? 0,
      dataSource.cacheConfiguration?.maxCacheFileSize ?? 0,
      dataSource.overriddenDuration?.inMilliseconds ?? 0,
      dataSource.drmConfiguration?.licenseUrl?.toJString(),
      drmHeadersMap,
      dataSource.cacheConfiguration?.key?.toJString(),
      dataSource.drmConfiguration?.clearKey?.toJString(),
    );
  }

  @override
  Future<void> play(int? textureId) async {
    _players[textureId]?.play();
  }

  @override
  Future<void> pause(int? textureId) async {
    _players[textureId]?.pause();
  }

  @override
  Future<void> setVolume(int? textureId, double volume) async {
    _players[textureId]?.volume = volume;
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    _players[textureId]?.speed = speed;
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    _players[textureId]?.seekTo(position?.inMilliseconds ?? 0);
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    final pos = _players[textureId]?.position ?? 0;
    return Duration(milliseconds: pos);
  }

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async {
    final pos = _players[textureId]?.absolutePosition ?? 0;
    if (pos <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(pos);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _eventControllers[textureId]?.stream ?? const Stream.empty();
  }

  @override
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }

  @visibleForTesting
  dynamic buildCallback(dynamic impl) {
    return BetterPlayerCallback.implement(impl as $BetterPlayerCallback);
  }

  @visibleForTesting
  dynamic createJniPlayer(dynamic callback) {
    return BetterPlayerApi.Companion.createPlayer(
      androidApplicationContext as Context,
      callback as BetterPlayerCallback,
    );
  }

  @visibleForTesting
  BetterPlayerWrapper createWrapper(dynamic player) {
    return NativeBetterPlayerWrapper(player as BetterPlayer);
  }
}

abstract class BetterPlayerWrapper {
  void dispose();
  void release();
  void setDataSource(
    Context context,
    JString key,
    JString dataSource,
    JString? formatHint,
    JMap<JString, JString>? headers,
    bool useCache,
    int maxCacheSize,
    int maxCacheFileSize,
    int overriddenDuration,
    JString? licenseUrl,
    JMap<JString, JString>? drmHeaders,
    JString? cacheKey,
    JString? clearKey,
  );
  void play();
  void pause();
  set volume(double volume);
  set speed(double speed);
  void seekTo(int positionMs);
  int get position;
  int get absolutePosition;
}

class NativeBetterPlayerWrapper implements BetterPlayerWrapper {
  final BetterPlayer _player;

  NativeBetterPlayerWrapper(this._player);

  @override
  void dispose() => _player.dispose();

  @override
  void release() => _player.release();

  @override
  void setDataSource(
    Context context,
    JString key,
    JString dataSource,
    JString? formatHint,
    JMap<JString, JString>? headers,
    bool useCache,
    int maxCacheSize,
    int maxCacheFileSize,
    int overriddenDuration,
    JString? licenseUrl,
    JMap<JString, JString>? drmHeaders,
    JString? cacheKey,
    JString? clearKey,
  ) {
    _player.setDataSource(
      context,
      key,
      dataSource,
      formatHint,
      headers,
      useCache,
      maxCacheSize,
      maxCacheFileSize,
      overriddenDuration,
      licenseUrl,
      drmHeaders,
      cacheKey,
      clearKey,
    );
  }

  @override
  void play() => _player.play();

  @override
  void pause() => _player.pause();

  @override
  set volume(double volume) => _player.volume = volume;

  @override
  set speed(double speed) => _player.speed = speed;

  @override
  void seekTo(int positionMs) => _player.seekTo(positionMs);

  @override
  int get position => _player.position;

  @override
  int get absolutePosition => _player.absolutePosition;
}
