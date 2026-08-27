import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:objective_c/objective_c.dart' as objc;
import 'package:better_player_ios/src/better_player_ios_ffi.g.dart';

final _libObjC = ffi.DynamicLibrary.process();

final _selObjectForKey = objc.registerName('objectForKey:');
final _selNumberWithLongLong = objc.registerName('numberWithLongLong:');
final _classNSNumber = objc.getClass('NSNumber');

late final _objcMsgSendObjectForKey = _libObjC.lookupFunction<
    ffi.Pointer<objc.ObjCObjectImpl> Function(
        ffi.Pointer<objc.ObjCObjectImpl>,
        ffi.Pointer<objc.ObjCSelector>,
        ffi.Pointer<objc.ObjCObjectImpl>),
    ffi.Pointer<objc.ObjCObjectImpl> Function(
        ffi.Pointer<objc.ObjCObjectImpl>,
        ffi.Pointer<objc.ObjCSelector>,
        ffi.Pointer<objc.ObjCObjectImpl>)>('objc_msgSend');

late final _objcMsgSendNumberWithLongLong = _libObjC.lookupFunction<
    ffi.Pointer<objc.ObjCObjectImpl> Function(
        ffi.Pointer<objc.ObjCObjectImpl>,
        ffi.Pointer<objc.ObjCSelector>,
        ffi.Int64),
    ffi.Pointer<objc.ObjCObjectImpl> Function(
        ffi.Pointer<objc.ObjCObjectImpl>,
        ffi.Pointer<objc.ObjCSelector>,
        int)>('objc_msgSend');

BetterPlayer? _getPlayer(int textureId) {
  final dict = BetterPlayerApi.getPlayers();
  
  final numPtr = _objcMsgSendNumberWithLongLong(
      _classNSNumber, _selNumberWithLongLong, textureId);
      
  final playerPtr = _objcMsgSendObjectForKey(
      dict.ref.pointer, _selObjectForKey, numPtr);
      
  if (playerPtr.address == 0) return null;
  return BetterPlayer.fromPointer(playerPtr, retain: true, release: true);
}

late final _objcMsgSendNoArgs = _libObjC.lookupFunction<
    ffi.Pointer<objc.ObjCObjectImpl> Function(
        ffi.Pointer<objc.ObjCObjectImpl>,
        ffi.Pointer<objc.ObjCSelector>),
    ffi.Pointer<objc.ObjCObjectImpl> Function(
        ffi.Pointer<objc.ObjCObjectImpl>,
        ffi.Pointer<objc.ObjCSelector>)>('objc_msgSend');

  late final _selURLWithString = objc.registerName('URLWithString:');
  late final _classNSURL = objc.getClass('NSURL');
  late final _objcMsgSendURL = _libObjC.lookupFunction<
      ffi.Pointer<objc.ObjCObjectImpl> Function(
          ffi.Pointer<objc.ObjCObjectImpl>,
          ffi.Pointer<objc.ObjCSelector>,
          ffi.Pointer<objc.ObjCObjectImpl>),
      ffi.Pointer<objc.ObjCObjectImpl> Function(
          ffi.Pointer<objc.ObjCObjectImpl>,
          ffi.Pointer<objc.ObjCSelector>,
          ffi.Pointer<objc.ObjCObjectImpl>)>('objc_msgSend');

  objc.NSURL _createNSURL(String url) {
    final str = url.toNSString();
    final urlPtr = _objcMsgSendURL(_classNSURL, _selURLWithString, str.ref.pointer);
    return objc.NSURL.fromPointer(urlPtr, retain: true, release: true);
  }

CacheManager _createCacheManager() {
  final cls = objc.getClass('CacheManager');
  final selAlloc = objc.registerName('alloc');
  final selInit = objc.registerName('init');
  final allocPtr = _objcMsgSendNoArgs(cls, selAlloc);
  final initPtr = _objcMsgSendNoArgs(allocPtr, selInit);
  return CacheManager.fromPointer(initPtr);
}

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
        // Implement parsing error events
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
    
    final cacheManager = _createCacheManager();
    final overriddenDuration = (map['overriddenDuration'] as int?) ?? 0;

    if (dataSource.sourceType == DataSourceType.asset) {
      player.setDataSourceAsset(
        (map['asset'] as String).toNSString(),
        key: (map['key'] as String?)?.toNSString(),
        cacheManager: cacheManager,
        overriddenDuration: overriddenDuration,
      );
    } else {
      player.setDataSourceURL(
        _createNSURL(map['uri'] as String),
        key: (map['key'] as String?)?.toNSString(),
        headers: objc.NSDictionary(),
        useCache: map['useCache'] as bool? ?? false,
        cacheManager: cacheManager,
        overriddenDuration: overriddenDuration,
      );
    }
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    if (textureId == null) return;
    // _getPlayer(textureId)?.setLooping(looping); // Method not generated/annotated?
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
    // _getPlayer(textureId)?.setSpeed(speed);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (textureId == null) return;
    // _getPlayer(textureId)?.seekTo(position.inMilliseconds);
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
