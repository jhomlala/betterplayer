// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'package:better_player/src/configuration/better_player_buffering_configuration.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'video_player_platform_interface.dart';

const MethodChannel _channel = MethodChannel('better_player_channel');

/// An implementation of [VideoPlayerPlatform] that uses method channels.
class MethodChannelVideoPlayer extends VideoPlayerPlatform {
  @override
  Future<void> init() {
    return _channel.invokeMethod<void>('init');
  }

  @override
  Future<void> dispose(int? textureId) {
    return _channel.invokeMethod<void>(
      'dispose',
      <String, dynamic>{'textureId': textureId},
    );
  }

  @override
  Future<int?> create({
    BetterPlayerBufferingConfiguration? bufferingConfiguration,
  }) async {
    late final Map<String, dynamic>? response;
    if (bufferingConfiguration == null) {
      response = await _channel.invokeMapMethod<String, dynamic>('create');
    } else {
      final responseLinkedHashMap = await _channel.invokeMethod<Map?>(
        'create',
        <String, dynamic>{
          'minBufferMs': bufferingConfiguration.minBufferMs,
          'maxBufferMs': bufferingConfiguration.maxBufferMs,
          'bufferForPlaybackMs': bufferingConfiguration.bufferForPlaybackMs,
          'bufferForPlaybackAfterRebufferMs':
              bufferingConfiguration.bufferForPlaybackAfterRebufferMs,
        },
      );

      response = responseLinkedHashMap != null
          ? Map<String, dynamic>.from(responseLinkedHashMap)
          : null;
    }
    return response?['textureId'] as int?;
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    Map<String, dynamic>? dataSourceDescription;
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        dataSourceDescription = <String, dynamic>{
          'key': dataSource.key,
          'asset': dataSource.asset,
          'package': dataSource.package,
          'useCache': false,
          'maxCacheSize': 0,
          'maxCacheFileSize': 0,
          'showNotification': dataSource.showNotification,
          'title': dataSource.title,
          'author': dataSource.author,
          'imageUrl': dataSource.imageUrl,
          'skipForwardTimeInMilliseconds':
              dataSource.skipForwardTimeInMilliseconds,
          'skipBackwardTimeInMilliseconds':
              dataSource.skipBackwardTimeInMilliseconds,
          'notificationChannelName': dataSource.notificationChannelName,
          'overriddenDuration': dataSource.overriddenDuration?.inMilliseconds,
          'activityName': dataSource.activityName
        };
        break;
      case DataSourceType.network:
        dataSourceDescription = <String, dynamic>{
          'key': dataSource.key,
          'uri': dataSource.uri,
          'formatHint': dataSource.rawFormalHint,
          'headers': dataSource.headers,
          'useCache': dataSource.useCache,
          'maxCacheSize': dataSource.maxCacheSize,
          'maxCacheFileSize': dataSource.maxCacheFileSize,
          'cacheKey': dataSource.cacheKey,
          'showNotification': dataSource.showNotification,
          'title': dataSource.title,
          'author': dataSource.author,
          'imageUrl': dataSource.imageUrl,
          'skipForwardTimeInMilliseconds':
              dataSource.skipForwardTimeInMilliseconds,
          'skipBackwardTimeInMilliseconds':
              dataSource.skipBackwardTimeInMilliseconds,
          'notificationChannelName': dataSource.notificationChannelName,
          'overriddenDuration': dataSource.overriddenDuration?.inMilliseconds,
          'licenseUrl': dataSource.licenseUrl,
          'certificateUrl': dataSource.certificateUrl,
          'drmHeaders': dataSource.drmHeaders,
          'activityName': dataSource.activityName,
          'clearKey': dataSource.clearKey,
          'videoExtension': dataSource.videoExtension,
        };
        break;
      case DataSourceType.file:
        dataSourceDescription = <String, dynamic>{
          'key': dataSource.key,
          'uri': dataSource.uri,
          'useCache': false,
          'maxCacheSize': 0,
          'maxCacheFileSize': 0,
          'showNotification': dataSource.showNotification,
          'title': dataSource.title,
          'author': dataSource.author,
          'imageUrl': dataSource.imageUrl,
          'skipForwardTimeInMilliseconds':
              dataSource.skipForwardTimeInMilliseconds,
          'skipBackwardTimeInMilliseconds':
              dataSource.skipBackwardTimeInMilliseconds,
          'notificationChannelName': dataSource.notificationChannelName,
          'overriddenDuration': dataSource.overriddenDuration?.inMilliseconds,
          'activityName': dataSource.activityName,
          'clearKey': dataSource.clearKey
        };
        break;
    }
    await _channel.invokeMethod<void>(
      'setDataSource',
      <String, dynamic>{
        'textureId': textureId,
        'dataSource': dataSourceDescription,
      },
    );
    return;
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) {
    return _channel.invokeMethod<void>(
      'setLooping',
      <String, dynamic>{
        'textureId': textureId,
        'looping': looping,
      },
    );
  }

  @override
  Future<void> play(int? textureId) {
    return _channel.invokeMethod<void>(
      'play',
      <String, dynamic>{'textureId': textureId},
    );
  }

  @override
  Future<void> pause(int? textureId) {
    return _channel.invokeMethod<void>(
      'pause',
      <String, dynamic>{'textureId': textureId},
    );
  }

  @override
  Future<void> setVolume(int? textureId, double volume) {
    return _channel.invokeMethod<void>(
      'setVolume',
      <String, dynamic>{
        'textureId': textureId,
        'volume': volume,
      },
    );
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) {
    return _channel.invokeMethod<void>(
      'setSpeed',
      <String, dynamic>{
        'textureId': textureId,
        'speed': speed,
      },
    );
  }

  @override
  Future<void> setTrackParameters(
      int? textureId, int? width, int? height, int? bitrate) {
    return _channel.invokeMethod<void>(
      'setTrackParameters',
      <String, dynamic>{
        'textureId': textureId,
        'width': width,
        'height': height,
        'bitrate': bitrate,
      },
    );
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) {
    return _channel.invokeMethod<void>(
      'seekTo',
      <String, dynamic>{
        'textureId': textureId,
        'location': position!.inMilliseconds,
      },
    );
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    return Duration(
        milliseconds: await _channel.invokeMethod<int>(
              'position',
              <String, dynamic>{'textureId': textureId},
            ) ??
            0);
  }

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async {
    final int milliseconds = await _channel.invokeMethod<int>(
          'absolutePosition',
          <String, dynamic>{'textureId': textureId},
        ) ??
        0;

    if (milliseconds <= 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  Future<void> enablePictureInPicture(int? textureId, double? top, double? left,
      double? width, double? height) async {
    return _channel.invokeMethod<void>(
      'enablePictureInPicture',
      <String, dynamic>{
        'textureId': textureId,
        'top': top,
        'left': left,
        'width': width,
        'height': height,
      },
    );
  }

  @override
  Future<bool?> isPictureInPictureEnabled(int? textureId) {
    return _channel.invokeMethod<bool>(
      'isPictureInPictureSupported',
      <String, dynamic>{
        'textureId': textureId,
      },
    );
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) {
    return _channel.invokeMethod<bool>(
      'disablePictureInPicture',
      <String, dynamic>{
        'textureId': textureId,
      },
    );
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) {
    return _channel.invokeMethod<void>(
      'setAudioTrack',
      <String, dynamic>{
        'textureId': textureId,
        'name': name,
        'index': index,
      },
    );
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) {
    return _channel.invokeMethod<void>(
      'setMixWithOthers',
      <String, dynamic>{
        'textureId': textureId,
        'mixWithOthers': mixWithOthers,
      },
    );
  }

  @override
  Future<void> clearCache() {
    return _channel.invokeMethod<void>(
      'clearCache',
      <String, dynamic>{},
    );
  }

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) {
    final Map<String, dynamic> dataSourceDescription = <String, dynamic>{
      'key': dataSource.key,
      'uri': dataSource.uri,
      'certificateUrl': dataSource.certificateUrl,
      'headers': dataSource.headers,
      'maxCacheSize': dataSource.maxCacheSize,
      'maxCacheFileSize': dataSource.maxCacheFileSize,
      'preCacheSize': preCacheSize,
      'cacheKey': dataSource.cacheKey,
      'videoExtension': dataSource.videoExtension,
    };
    return _channel.invokeMethod<void>(
      'preCache',
      <String, dynamic>{
        'dataSource': dataSourceDescription,
      },
    );
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) {
    return _channel.invokeMethod<void>(
      'stopPreCache',
      <String, dynamic>{'url': url, 'cacheKey': cacheKey},
    );
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      late Map<dynamic, dynamic> map;
      if (event is Map) {
        map = event;
      }
      final String? eventType = map["event"] as String?;
      final String? key = map["key"] as String?;
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
            BetterPlayerUtils.log(exception.toString());
          }

          final Size size = Size(width, height);

          return VideoEvent(
            eventType: VideoEventType.initialized,
            key: key,
            duration: Duration(milliseconds: map['duration'] as int),
            size: size,
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
            key: key,
          );
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List;

          return VideoEvent(
            eventType: VideoEventType.bufferingUpdate,
            key: key,
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
          );
        case 'bufferingStart':
          return VideoEvent(
            eventType: VideoEventType.bufferingStart,
            key: key,
          );
        case 'bufferingEnd':
          return VideoEvent(
            eventType: VideoEventType.bufferingEnd,
            key: key,
          );

        case 'play':
          return VideoEvent(
            eventType: VideoEventType.play,
            key: key,
          );

        case 'pause':
          return VideoEvent(
            eventType: VideoEventType.pause,
            key: key,
          );

        case 'seek':
          return VideoEvent(
            eventType: VideoEventType.seek,
            key: key,
            position: Duration(milliseconds: map['position'] as int),
          );

        case 'pipStart':
          return VideoEvent(
            eventType: VideoEventType.pipStart,
            key: key,
          );

        case 'pipStop':
          return VideoEvent(
            eventType: VideoEventType.pipStop,
            key: key,
          );

        default:
          return VideoEvent(
            eventType: VideoEventType.unknown,
            key: key,
          );
      }
    });
  }

  @override
  Widget buildView(int? textureId) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.jhomlala/better_player',
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: {'textureId': textureId!},
      );
    } else {
      return Texture(textureId: textureId!);
    }
  }

  EventChannel _eventChannelFor(int? textureId) {
    return EventChannel('better_player_channel/videoEvents$textureId');
  }

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }
}
