import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:objective_c/objective_c.dart' as objc;
import 'package:better_player_ios/src/better_player_ios_ffi.g.dart';

BetterPlayer? _getPlayer(int textureId) => BetterPlayerApi.getPlayer(textureId);

class BetterPlayerIOS extends VideoPlayerPlatform {
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerIOS();
  }

  final Map<int, StreamController<VideoEvent>> _eventControllers = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) return;
    _getPlayer(textureId)?.dispose();
    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    int? currentTextureId;

    final callback = BetterPlayerCallback$Builder.implementAsBlocking(
      onEvent_parameters_: (objc.NSString event, objc.NSString parameters) {
        if (currentTextureId == null) return;
        final eventStr = event.toString();
        if (eventStr == 'initialized') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.initialized, key: ''));
        } else if (eventStr == 'completed') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.completed, key: ''));
        } else if (eventStr == 'play') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.play, key: ''));
        } else if (eventStr == 'pause') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.pause, key: ''));
        } else if (eventStr == 'bufferingStart') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.bufferingStart, key: ''));
        } else if (eventStr == 'bufferingUpdate') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.bufferingUpdate, key: ''));
        } else if (eventStr == 'bufferingEnd') {
          _eventControllers[currentTextureId]?.add(VideoEvent(eventType: VideoEventType.bufferingEnd, key: ''));
        }
      },
      onError_errorMessage_errorDetails_: (objc.NSString errorCode, objc.NSString errorMessage, objc.NSString errorDetails) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.addError(PlatformException(
            code: errorCode.toString(),
            message: errorMessage.toString(),
            details: errorDetails.toString(),
        ));
      },
    );

    currentTextureId = BetterPlayerApi.createPlayerWithCallback(callback);
    
    _eventControllers[currentTextureId] = StreamController<VideoEvent>.broadcast();
    return currentTextureId;
  }

  @override
  Widget buildView(int? textureId) {
    return UiKitView(
      viewType: 'better_player_view',
      creationParamsCodec: const StandardMessageCodec(),
      creationParams: {'textureId': textureId!},
    );
  }

  Map<String, dynamic> dataSourceToMap(DataSource dataSource) {
    if (dataSource.uri?.contains('.mpd') == true ||
        dataSource.formatHint == VideoFormat.dash) {
      throw Exception(
        'DASH streams are not supported on iOS platform. Please use HLS instead.',
      );
    }
    
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

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    if (textureId == null) return;
    final map = dataSourceToMap(dataSource);
    final player = _getPlayer(textureId);
    if (player == null) return;
    
    final cacheManager = BetterPlayerApi.createCacheManager();
    final overriddenDuration = (map['overriddenDuration'] as int?) ?? 0;

    if (dataSource.sourceType == DataSourceType.asset) {
      player.setDataSourceAsset(
        (map['asset'] as String).toNSString(),
        key: (map['key'] as String?)?.toNSString(),
        cacheManager: cacheManager,
        overriddenDuration: overriddenDuration,
      );
    } else {
      player.setDataSourceURLString(
        (map['uri'] as String).toNSString(),
        key: (map['key'] as String?)?.toNSString(),
        certificateUrl: null,
        licenseUrl: null,
        useCache: map['useCache'] as bool? ?? false,
        cacheKey: null,
        cacheManager: cacheManager,
        overriddenDuration: overriddenDuration,
        videoExtension: null,
      );
    }
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    if (textureId == null) return;
    _getPlayer(textureId)?.setLooping(looping);
  }

  @override
  Future<void> play(int? textureId) async {
    if (textureId == null) return;
    _getPlayer(textureId)?.play();
  }

  @override
  Future<void> pause(int? textureId) async {
    if (textureId == null) return;
    _getPlayer(textureId)?.pause();
  }

  @override
  Future<void> setVolume(int? textureId, double volume) async {
    if (textureId == null) return;
    _getPlayer(textureId)?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    if (textureId == null) return;
    _getPlayer(textureId)?.setSpeed(speed);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (textureId == null || position == null) return;
    _getPlayer(textureId)?.seekTo(position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    if (textureId == null) return Duration.zero;
    final pos = _getPlayer(textureId)?.position();
    return Duration(milliseconds: pos ?? 0);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _eventControllers[textureId]?.stream ?? const Stream.empty();
  }
}
