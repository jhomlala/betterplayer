import 'dart:async';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:objective_c/objective_c.dart' as objc;
import 'package:better_player_ios/src/better_player_ios_ffi.g.dart';

class BetterPlayerIOS extends VideoPlayerPlatform {
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerIOS();
  }

  final Map<int, StreamController<VideoEvent>> _eventControllers = {};

  @override
  Future<void> init() async {
  }

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) return;
    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    final callback = BetterPlayerCallback$Builder.implementAsBlocking(
      onEvent_parameters_: (objc.NSString event, objc.NSString parameters) {
        // Implement parsing video events
      },
      onError_errorMessage_errorDetails_: (objc.NSString errorCode, objc.NSString errorMessage, objc.NSString errorDetails) {
        // Implement parsing error events
      },
    );

    final textureId = BetterPlayerApi.createPlayerWithCallback(callback);
    
    // NOTE: BetterPlayer methods (play, pause, setDataSource) are missing from better_player_ios_ffi.g.dart
    // because BetterPlayer.swift was not annotated with @objc properly for ffigen.
    
    _eventControllers[textureId] = StreamController<VideoEvent>.broadcast();
    return textureId;
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
}
