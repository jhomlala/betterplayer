import 'dart:async';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';
import 'src/better_player_android_jni.g.dart';

class BetterPlayerAndroid extends VideoPlayerPlatform {
  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerAndroid();
  }

  final Map<int, BetterPlayer> _players = {};
  final Map<int, StreamController<VideoEvent>> _eventControllers = {};
  final Map<int, BetterPlayerCallback> _callbacks = {};

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
    
    _callbacks[textureId]?.release();
    _callbacks.remove(textureId);

    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    final callback = BetterPlayerCallback.implement($BetterPlayerCallback(
      onEvent: (JString event, JMap<JString, JObject?> parameters) {
        final eventStr = event.toDartString();
        // Since full JMap extraction requires JNI reflection which is tedious here,
        // we map it manually if needed, or assume empty parameters for now.
        final map = _jmapToMap(parameters);
        map['event'] = eventStr;
        final videoEvent = _parseVideoEvent(eventStr, map);
        // Note: we can't easily capture textureId in this callback since we don't have it yet!
        // We'll broadcast it to all controllers for now, or match by key.
        for (var controller in _eventControllers.values) {
          controller.add(videoEvent);
        }
      },
      onEvent$async: true,
      onError: (JString errorCode, JString errorMessage, JString errorDetails) {
        // Implement parsing error events
      },
      onError$async: true,
    ));

    final player = BetterPlayerApi.Companion.createPlayer(androidApplicationContext as Context, callback);
    if (player == null) return null;
    
    final textureId = player.textureId;
    _players[textureId] = player;
    _callbacks[textureId] = callback;
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();
    
    return textureId;
  }

  @override


  VideoEvent _parseVideoEvent(String eventType, Map<dynamic, dynamic> map) {
    final key = map['key'] as String?;
    switch (eventType) {
      case 'initialized':
        double width = 0;
        double height = 0;
        try {
          if (map.containsKey("width")) {
            final num widthNum = map["width"] as num;
            width = widthNum.toDouble();
          }
          if (map.containsKey("height")) {
            final num heightNum = map["height"] as num;
            height = heightNum.toDouble();
          }
        } catch (exception) {
          // ignore
        }
        return VideoEvent(
          eventType: VideoEventType.initialized,
          key: key,
          duration: Duration(milliseconds: (map['duration'] as num?)?.toInt() ?? 0),
          size: Size(width, height),
        );
      case 'completed':
        return VideoEvent(eventType: VideoEventType.completed, key: key);
      case 'bufferingUpdate':
        final List<dynamic> values = map['values'] as List<dynamic>? ?? [];
        return VideoEvent(
          eventType: VideoEventType.bufferingUpdate,
          key: key,
          buffered: values.map<DurationRange>((dynamic value) {
            final List<dynamic> range = value as List<dynamic>;
            return DurationRange(
              Duration(milliseconds: (range[0] as num).toInt()),
              Duration(milliseconds: (range[1] as num).toInt()),
            );
          }).toList(),
        );
      case 'bufferingStart':
        return VideoEvent(eventType: VideoEventType.bufferingStart, key: key);
      case 'bufferingEnd':
        return VideoEvent(eventType: VideoEventType.bufferingEnd, key: key);
      case 'play':
        return VideoEvent(eventType: VideoEventType.play, key: key);
      case 'pause':
        return VideoEvent(eventType: VideoEventType.pause, key: key);
      case 'seek':
        return VideoEvent(
          eventType: VideoEventType.seek,
          key: key,
          position: Duration(milliseconds: (map['position'] as num?)?.toInt() ?? 0),
        );
      case 'pipStart':
        return VideoEvent(eventType: VideoEventType.pipStart, key: key);
      case 'pipStop':
        return VideoEvent(eventType: VideoEventType.pipStop, key: key);
      default:
        return VideoEvent(eventType: VideoEventType.unknown, key: key);
    }
  }

  Map<dynamic, dynamic> _jmapToMap(JMap<JString, JObject?> jmap) {
    // Note: A proper mapping from JObject to Dart types would be needed here.
    // For now, we'll just implement a dummy mapping since jni_flutter returns proxies.
    // In a real implementation we would iterate the map and extract integers/strings.
    final result = <dynamic, dynamic>{};
    // Placeholder for actual JMap iteration
    return result;
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
        headersMap!.put(k.toString().toJString(), (v?.toString() ?? '').toJString());
      });
    }
    
    JMap<JString, JString>? drmHeadersMap;
    if (dataSource.drmConfiguration?.headers != null) {
      drmHeadersMap = (JHashMap() as JObject) as JMap<JString, JString>;
      dataSource.drmConfiguration!.headers!.forEach((k, v) {
        drmHeadersMap!.put(k.toString().toJString(), v.toString().toJString());
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

}

