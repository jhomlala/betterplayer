import 'dart:async';

// ignore_for_file: avoid_setters_without_getters

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

  @override
  Future<void> setupLogCallback(
    void Function({
      required int levelIndex,
      required String tag,
      required String message,
    })?
    callback,
  ) async {
    if (callback == null) {
      BetterPlayerApi.Companion.logCallback = null;
      return;
    }
    final jniCallback = BetterPlayerLogCallback.implement(
      $BetterPlayerLogCallback(
        onLog: (int level, JString tag, JString message) {
          callback(
            levelIndex: level,
            tag: tag.toDartString(),
            message: message.toDartString(),
          );
        },
        onLog$async: true,
      ),
    );
    BetterPlayerApi.Companion.logCallback = jniCallback;
  }

  final Map<int, BetterPlayerWrapper> _players = {};
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, dynamic> _callbacks = {};

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) return;
    final player = _players[textureId];
    if (player is NativeBetterPlayerWrapper) {
      player.internalPlayer.disposeRemoteNotifications();
    }
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
          for (final controller in _eventControllers.values) {
            controller.add(
              VideoEvent(
                eventType: VideoEventType.changedSize,
                key: key?.toDartString(),
                size: Size(width.toDouble(), height.toDouble()),
              ),
            );
          }
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

    final textureId = getTextureIdFromPlayer(player);
    _players[textureId] = createWrapper(player);
    _callbacks[textureId] = callback;
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();

    return textureId;
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    final player = _players[textureId];
    if (player == null) return;

    player.setDataSource(
      dataSource.key,
      dataSource.uri ?? dataSource.asset ?? '',
      dataSource.rawFormalHint,
      dataSource.headers?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      dataSource.cacheConfiguration?.useCache ?? false,
      dataSource.cacheConfiguration?.maxCacheSize ?? 0,
      dataSource.cacheConfiguration?.maxCacheFileSize ?? 0,
      dataSource.overriddenDuration?.inMilliseconds ?? 0,
      dataSource.drmConfiguration?.licenseUrl,
      dataSource.drmConfiguration?.headers,
      dataSource.cacheConfiguration?.key,
      dataSource.drmConfiguration?.clearKey,
    );

    final notificationConfig = dataSource.notificationConfiguration;
    if (notificationConfig?.showNotification == true) {
      final playerWrapper = player as NativeBetterPlayerWrapper;
      playerWrapper.internalPlayer.setupPlayerNotification(
        androidApplicationContext as Context,
        (notificationConfig?.title ?? '').toJString(),
        notificationConfig?.author?.toJString(),
        notificationConfig?.imageUrl?.toJString(),
        notificationConfig?.notificationChannelName?.toJString(),
        (notificationConfig?.activityName ?? 'MainActivity').toJString(),
      );
    }
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    _players[textureId]?.looping = looping;
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
  Future<void> preCache(DataSource dataSource, int preCacheSize) async {
    jniPreCache(
      dataSource.uri ?? dataSource.asset ?? '',
      preCacheSize,
      dataSource.cacheConfiguration?.maxCacheSize ?? 0,
      dataSource.cacheConfiguration?.maxCacheFileSize ?? 0,
      dataSource.headers?.map((k, v) => MapEntry(k, v?.toString())),
      dataSource.cacheConfiguration?.key,
    );
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) async {
    jniStopPreCache(url);
  }

  @override
  Future<void> clearCache() async {
    jniClearCache();
  }

  @override
  Future<void> setTrackParameters(
    int? textureId,
    int? width,
    int? height,
    int? bitrate,
  ) async {
    _players[textureId]?.setTrackParameters(
      width ?? 0,
      height ?? 0,
      bitrate ?? 0,
    );
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) async {
    _players[textureId]?.setAudioTrack(name ?? '', index ?? 0);
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) async {
    _players[textureId]?.mixWithOthers = mixWithOthers;
  }

  @override
  Future<bool?> isPictureInPictureSupported(int? textureId) async {
    try {
      return BetterPlayer.Companion.isPictureInPictureSupported(
        androidApplicationContext as Context,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> enablePictureInPicture(
    int? textureId,
    double? top,
    double? left,
    double? width,
    double? height,
  ) async {
    BetterPlayer.Companion.enablePictureInPicture(
      androidApplicationContext as Context,
    );
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) async {
    BetterPlayer.Companion.disablePictureInPicture(
      androidApplicationContext as Context,
    );
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

  @visibleForTesting
  int getTextureIdFromPlayer(dynamic player) {
    return (player as BetterPlayer).textureId;
  }

  @visibleForTesting
  void jniPreCache(
    String dataSource,
    int preCacheSize,
    int maxCacheSize,
    int maxCacheFileSize,
    Map<String, String?>? headers,
    String? cacheKey,
  ) {
    final headersMap = (JHashMap() as JObject) as JMap<JString, JString?>;
    headers?.forEach((k, v) {
      headersMap.put(k.toJString(), v?.toJString());
    });

    BetterPlayer.Companion.preCache(
      androidApplicationContext as Context,
      dataSource.toJString(),
      preCacheSize,
      maxCacheSize,
      maxCacheFileSize,
      headersMap,
      cacheKey?.toJString(),
    );
  }

  @visibleForTesting
  void jniStopPreCache(String url) {
    BetterPlayer.Companion.stopPreCache(
      androidApplicationContext as Context,
      url.toJString(),
    );
  }

  @visibleForTesting
  void jniClearCache() {
    BetterPlayer.Companion.clearCache(androidApplicationContext as Context);
  }
}

abstract class BetterPlayerWrapper {
  void dispose();
  void release();
  void setDataSource(
    String key,
    String dataSource,
    String? formatHint,
    Map<String, String>? headers,
    bool useCache,
    int maxCacheSize,
    int maxCacheFileSize,
    int overriddenDuration,
    String? licenseUrl,
    Map<String, String>? drmHeaders,
    String? cacheKey,
    String? clearKey,
  );
  void setTrackParameters(int width, int height, int bitrate);
  void setAudioTrack(String name, int index);
  set mixWithOthers(bool mixWithOthers);
  void play();
  void pause();
  set looping(bool looping);
  set volume(double volume);
  set speed(double speed);
  void seekTo(int positionMs);
  int get position;
  int get absolutePosition;
}

class NativeBetterPlayerWrapper implements BetterPlayerWrapper {
  final BetterPlayer _player;

  NativeBetterPlayerWrapper(this._player);

  BetterPlayer get internalPlayer => _player;

  @override
  void dispose() => _player.dispose();

  @override
  void release() => _player.release();

  @override
  void setDataSource(
    String key,
    String dataSource,
    String? formatHint,
    Map<String, String>? headers,
    bool useCache,
    int maxCacheSize,
    int maxCacheFileSize,
    int overriddenDuration,
    String? licenseUrl,
    Map<String, String>? drmHeaders,
    String? cacheKey,
    String? clearKey,
  ) {
    // Convert headers to JMap
    JMap<JString, JString>? headersMap;
    if (headers != null) {
      headersMap = (JHashMap() as JObject) as JMap<JString, JString>;
      headers.forEach((k, v) {
        headersMap!.put(k.toJString(), v.toJString());
      });
    }

    JMap<JString, JString>? drmHeadersMap;
    if (drmHeaders != null) {
      drmHeadersMap = (JHashMap() as JObject) as JMap<JString, JString>;
      drmHeaders.forEach((k, v) {
        drmHeadersMap!.put(k.toJString(), v.toJString());
      });
    }

    _player.setDataSource(
      androidApplicationContext as Context,
      key.toJString(),
      dataSource.toJString(),
      formatHint?.toJString(),
      headersMap,
      useCache,
      maxCacheSize,
      maxCacheFileSize,
      overriddenDuration,
      licenseUrl?.toJString(),
      drmHeadersMap,
      cacheKey?.toJString(),
      clearKey?.toJString(),
    );
  }

  @override
  void setTrackParameters(int width, int height, int bitrate) =>
      _player.setTrackParameters(width, height, bitrate);

  @override
  void setAudioTrack(String name, int index) =>
      _player.setAudioTrack(name.toJString(), index);

  @override
  set mixWithOthers(bool mixWithOthers) =>
      _player.mixWithOthers = mixWithOthers;

  @override
  void play() => _player.play();

  @override
  void pause() => _player.pause();

  @override
  set looping(bool looping) => _player.looping = looping;

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
