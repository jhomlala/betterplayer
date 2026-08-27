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
    final callback = BetterPlayerCallback.implement(\$BetterPlayerCallback(
      onEvent: (JString event, JMap<JString, JObject?> parameters) {
        // Implement parsing video events
      },
      onEvent\$async: true,
      onError: (JString errorCode, JString errorMessage, JString errorDetails) {
        // Implement parsing error events
      },
      onError\$async: true,
    ));

    final player = BetterPlayerApi.Companion.createPlayer(Jni.cachedApplicationContext, callback);
    if (player == null) return null;
    
    final textureId = player.textureId;
    _players[textureId] = player;
    _callbacks[textureId] = callback;
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();
    
    return textureId;
  }

  @override

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    final player = _players[textureId];
    if (player == null) return;
    
    final map = dataSourceToMap(dataSource);
    
    // Convert maps to JMap
    JMap<JString, JString>? headersMap;
    if (map['headers'] != null) {
      final m = map['headers'] as Map;
      headersMap = JMap(JString.type, JString.type);
      m.forEach((k, v) {
        headersMap!.put(k.toString().toJString(), v.toString().toJString());
      });
    }
    
    JMap<JString, JString>? drmHeadersMap;
    if (map['drmHeaders'] != null) {
      final m = map['drmHeaders'] as Map;
      drmHeadersMap = JMap(JString.type, JString.type);
      m.forEach((k, v) {
        drmHeadersMap!.put(k.toString().toJString(), v.toString().toJString());
      });
    }

    player.setDataSource(
      Jni.cachedApplicationContext,
      (map['key'] as String?)?.toJString(),
      (map['uri'] as String? ?? map['asset'] as String?)?.toJString(),
      (map['formatHint'] as String?)?.toJString(),
      headersMap,
      map['useCache'] as bool? ?? false,
      map['maxCacheSize'] as int? ?? 0,
      map['maxCacheFileSize'] as int? ?? 0,
      map['overriddenDuration'] as int? ?? 0,
      (map['licenseUrl'] as String?)?.toJString(),
      drmHeadersMap,
      (map['cacheKey'] as String?)?.toJString(),
      (map['clearKey'] as String?)?.toJString(),
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
    _players[textureId]?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    _players[textureId]?.setSpeed(speed);
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
  Widget buildView(int? textureId) {
    return Texture(textureId: textureId!);
  }

  Map<String, dynamic> dataSourceToMap(DataSource dataSource) {
    final map = <String, dynamic>{
      'key': dataSource.key,
      'useCache': false,
      'maxCacheSize': 0,
      'maxCacheFileSize': 0,
      'showNotification':
          dataSource.notificationConfiguration?.showNotification ?? false,
      'title': dataSource.notificationConfiguration?.title,
      'author': dataSource.notificationConfiguration?.author,
      'imageUrl': dataSource.notificationConfiguration?.imageUrl,
      'notificationChannelName':
          dataSource.notificationConfiguration?.notificationChannelName,
      'overriddenDuration': dataSource.overriddenDuration?.inMilliseconds,
      'activityName': dataSource.notificationConfiguration?.activityName,
    };

    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        map.addAll(<String, dynamic>{
          'asset': dataSource.asset,
          'package': dataSource.package,
        });
      case DataSourceType.network:
        map.addAll(<String, dynamic>{
          'uri': dataSource.uri,
          'formatHint': dataSource.rawFormalHint,
          'headers': dataSource.headers,
          'useCache': dataSource.cacheConfiguration?.useCache ?? false,
          'maxCacheSize': dataSource.cacheConfiguration?.maxCacheSize ?? 0,
          'maxCacheFileSize':
              dataSource.cacheConfiguration?.maxCacheFileSize ?? 0,
          'cacheKey': dataSource.cacheConfiguration?.key,
          'licenseUrl': dataSource.drmConfiguration?.licenseUrl,
          'certificateUrl': dataSource.drmConfiguration?.certificateUrl,
          'drmHeaders': dataSource.drmConfiguration?.headers,
          'clearKey': dataSource.drmConfiguration?.clearKey,
          'videoExtension': dataSource.videoExtension,
        });
      case DataSourceType.file:
      case DataSourceType.memory:
        map.addAll(<String, dynamic>{
          'uri': dataSource.uri,
          'formatHint': dataSource.rawFormalHint,
          'clearKey': dataSource.drmConfiguration?.clearKey,
        });
    }
    return map;
  }
}

