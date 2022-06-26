// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:better_player_platform_interface/messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'better_player_platform_interface.dart';

const MethodChannel _channel = MethodChannel('better_player_channel');

/// An implementation of [BetterPlayerPlatform] that uses method channels.
class MethodChannelBetterPlayer extends BetterPlayerPlatform {
  final BetterPlayerApi _api = BetterPlayerApi();

  @override
  Future<void> init() {
    return _api.initialize();
  }

  @override
  Future<void> dispose(int? textureId) {
    return _api.dispose(TextureMessage()..textureId = textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    CreateMessage createMessage = CreateMessage();
    if (bufferingConfiguration != null) {
      createMessage.minBufferMs = bufferingConfiguration.minBufferMs;
      createMessage.maxBufferMs = bufferingConfiguration.maxBufferMs;
      createMessage.bufferForPlaybackMs =
          bufferingConfiguration.bufferForPlaybackMs;
      createMessage.bufferForPlaybackAfterRebufferMs =
          bufferingConfiguration.bufferForPlaybackAfterRebufferMs;
    }

    final TextureMessage textureMessage = await _api.create(createMessage);
    return textureMessage.textureId;
  }

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    final DataSourceMessage dataSourceMessage = DataSourceMessage();
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        dataSourceMessage
          ..asset = dataSource.asset
          ..package = dataSource.package
          ..useCache = false
          ..maxCacheSize = 0
          ..maxCacheFileSize = 0;
        break;
      case DataSourceType.network:
        dataSourceMessage
          ..uri = dataSource.uri
          ..formatHint = dataSource.rawFormalHint
          ..headers = dataSource.headers
          ..useCache = dataSource.useCache
          ..maxCacheSize = dataSource.maxCacheSize
          ..maxCacheFileSize = dataSource.maxCacheFileSize
          ..cacheKey = dataSource.cacheKey
          ..licenseUrl = dataSource.licenseUrl
          ..certificateUrl = dataSource.certificateUrl
          ..drmHeaders = dataSource.drmHeaders
          ..clearKey = dataSource.clearKey
          ..videoExtension = dataSource.videoExtension;

        break;
      case DataSourceType.file:
        dataSourceMessage
          ..uri = dataSource.uri
          ..useCache = dataSource.useCache
          ..maxCacheSize = dataSource.maxCacheSize
          ..maxCacheFileSize = dataSource.maxCacheFileSize
          ..clearKey = dataSource.clearKey;

        break;
    }
    dataSourceMessage
      ..textureId = textureId
      ..key = dataSource.key
      ..showNotification = dataSource.showNotification
      ..title = dataSource.title
      ..author = dataSource.author
      ..imageUrl = dataSource.imageUrl
      ..notificationChannelName = dataSource.notificationChannelName
      ..overriddenDuration = dataSource.overriddenDuration?.inMilliseconds
      ..activityName = dataSource.activityName;

    await _api.setDataSource(dataSourceMessage);
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) {
    SetLoopingMessage setLoopingMessage = SetLoopingMessage()
      ..textureId = textureId
      ..looping = looping;
    return _api.setLooping(setLoopingMessage);
  }

  @override
  Future<void> play(int? textureId) {
    TextureMessage textureMessage = TextureMessage()..textureId = textureId;
    return _api.play(textureMessage);
  }

  @override
  Future<void> pause(int? textureId) {
    TextureMessage textureMessage = TextureMessage()..textureId = textureId;
    return _api.pause(textureMessage);
  }

  @override
  Future<void> setVolume(int? textureId, double volume) {
    VolumeMessage volumeMessage = VolumeMessage()
      ..textureId = textureId
      ..volume = volume;

    return _api.setVolume(volumeMessage);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) {
    SetSpeedMessage setSpeedMessage = SetSpeedMessage()
      ..textureId = textureId
      ..speed = speed;
    return _api.setSpeed(setSpeedMessage);
  }

  @override
  Future<void> setTrackParameters(
      int? textureId, int? width, int? height, int? bitrate) {
    SetTrackParametersMessage setTrackParametersMessage =
        SetTrackParametersMessage()
          ..textureId = textureId
          ..width = width
          ..height = height
          ..bitrate = bitrate;

    return _api.setTrackParameters(setTrackParametersMessage);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) {
    SeekToMessage seekToMessage = SeekToMessage()
      ..textureId = textureId
      ..position = position?.inMilliseconds;
    return _api.seekTo(seekToMessage);
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    TextureMessage textureMessage = TextureMessage();
    PositionMessage positionMessage = await _api.position(textureMessage);
    var positionInMs = positionMessage.position ?? 0;
    return Duration(milliseconds: positionInMs);
  }

  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async {
    TextureMessage textureMessage = TextureMessage();
    final PositionMessage positionMessage =
        await _api.absolutePosition(textureMessage);
    if (positionMessage.position != null) {
      return DateTime.fromMillisecondsSinceEpoch(positionMessage.position!);
    } else {
      return null;
    }
  }

  @override
  Future<void> enablePictureInPicture(int? textureId, double? top, double? left,
      double? width, double? height) async {
    EnablePictureInPictureMessage enablePictureInPictureMessage =
        EnablePictureInPictureMessage()
          ..textureId = textureId
          ..top = top
          ..left = left
          ..width = width
          ..height = height;

    _api.enablePictureInPicture(enablePictureInPictureMessage);
  }

  @override
  Future<bool?> isPictureInPictureEnabled(int? textureId) {
    TextureMessage textureMessage = TextureMessage()..textureId = textureId;
    return _api.isPictureInPictureEnabled(textureMessage);
  }

  @override
  Future<void> disablePictureInPicture(int? textureId) {
    TextureMessage textureMessage = TextureMessage()..textureId = textureId;
    return _api.disablePictureInPicture(textureMessage);
  }

  @override
  Future<void> setAudioTrack(int? textureId, String? name, int? index) {
    SetAudioTrack setAudioTrack = SetAudioTrack()
      ..textureId = textureId
      ..name = name
      ..index = index;
    return _api.setAudioTrack(setAudioTrack);
  }

  @override
  Future<void> setMixWithOthers(int? textureId, bool mixWithOthers) {
    SetMixWithOthersMessage setMixWithOthersMessage = SetMixWithOthersMessage()
      ..textureId = textureId
      ..mixWithOthers = mixWithOthers;
    return _api.setMixWithOthers(setMixWithOthersMessage);
  }

  @override
  Future<void> clearCache() {
    return _api.clearCache();
  }

  @override
  Future<void> preCache(DataSource dataSource, int preCacheSize) {
    PreCacheMessage preCacheMessage = PreCacheMessage();
    preCacheMessage.dataSource = InnerPreCacheMessage()
      ..key = dataSource.key
      ..uri = dataSource.uri
      ..certificateUrl = dataSource.certificateUrl
      ..headers = dataSource.headers
      ..maxCacheSize = dataSource.maxCacheSize
      ..maxCacheFileSize = dataSource.maxCacheFileSize
      ..preCacheSize = preCacheSize
      ..cacheKey = dataSource.cacheKey
      ..videoExtension = dataSource.videoExtension;

    return _api.preCache(preCacheMessage);
  }

  @override
  Future<void> stopPreCache(String url, String? cacheKey) {
    StopPreCacheMessage stopPreCacheMessage = StopPreCacheMessage()
    ..url = url
    ..cacheKey = cacheKey;
    return _api.stopPreCache(stopPreCacheMessage);
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
          } catch (exception) {}

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
