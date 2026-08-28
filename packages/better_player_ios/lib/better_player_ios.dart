import 'dart:async';
import 'dart:convert';

import 'package:better_player_ios/src/better_player_ios_ffi.g.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:objective_c/objective_c.dart' as objc;

class BetterPlayerIOS extends BetterPlayerPlatform {
  @visibleForTesting
  BetterPlayer? getPlayer(int textureId) =>
      BetterPlayerApi.getPlayer(textureId);

  @visibleForTesting
  CacheManager? createCacheManager() => BetterPlayerApi.createCacheManager();
  static void registerWith() {
    BetterPlayerPlatform.instance = BetterPlayerIOS();
  }

  final Map<int, StreamController<VideoEvent>> _eventControllers = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int? textureId) async {
    if (textureId == null) return;
    getPlayer(textureId)?.dispose();
    _eventControllers[textureId]?.close();
    _eventControllers.remove(textureId);
  }

  @override
  Future<int?> create({
    BufferingConfiguration? bufferingConfiguration,
  }) async {
    int? currentTextureId;

    final callback = BetterPlayerCallback$Builder.implement(
      onInitializedWithDurationMs_width_height_key_:
          (int durationMs, double width, double height, objc.NSString? key) {
            if (currentTextureId == null) return;
            _eventControllers[currentTextureId]?.add(
              VideoEvent(
                eventType: VideoEventType.initialized,
                key: key?.toString(),
                duration: Duration(milliseconds: durationMs),
                size: Size(width, height),
              ),
            );
          },
      onCompletedWithKey_: (objc.NSString? key) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(eventType: VideoEventType.completed, key: key?.toString()),
        );
      },
      onPlayWithKey_: (objc.NSString? key) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(eventType: VideoEventType.play, key: key?.toString()),
        );
      },
      onPauseWithKey_: (objc.NSString? key) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(eventType: VideoEventType.pause, key: key?.toString()),
        );
      },
      onSeekWithPositionMs_key_: (int positionMs, objc.NSString? key) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(
            eventType: VideoEventType.seek,
            key: key?.toString(),
            position: Duration(milliseconds: positionMs),
          ),
        );
      },
      onBufferingStartWithKey_: (objc.NSString? key) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(
            eventType: VideoEventType.bufferingStart,
            key: key?.toString(),
          ),
        );
      },
      onBufferingEndWithKey_: (objc.NSString? key) {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(
            eventType: VideoEventType.bufferingEnd,
            key: key?.toString(),
          ),
        );
      },
      onBufferingUpdateWithJsonRanges_key_:
          (objc.NSString jsonRanges, objc.NSString? key) {
            if (currentTextureId == null) return;
            final decoded = jsonDecode(jsonRanges.toString()) as List<dynamic>;
            final buffered = decoded.map<DurationRange>((dynamic value) {
              final range = value as List<dynamic>;
              return DurationRange(
                Duration(milliseconds: (range[0] as num).toInt()),
                Duration(milliseconds: (range[1] as num).toInt()),
              );
            }).toList();
            _eventControllers[currentTextureId]?.add(
              VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                key: key?.toString(),
                buffered: buffered,
              ),
            );
          },
      onPipStart: () {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(eventType: VideoEventType.pipStart, key: null),
        );
      },
      onPipStop: () {
        if (currentTextureId == null) return;
        _eventControllers[currentTextureId]?.add(
          VideoEvent(eventType: VideoEventType.pipStop, key: null),
        );
      },
      onError_errorMessage_errorDetails_:
          (
            objc.NSString errorCode,
            objc.NSString errorMessage,
            objc.NSString errorDetails,
          ) {
            if (currentTextureId == null) return;
            _eventControllers[currentTextureId]?.addError(
              PlatformException(
                code: errorCode.toString(),
                message: errorMessage.toString(),
                details: errorDetails.toString(),
              ),
            );
          },
    );

    currentTextureId = BetterPlayerApi.createPlayerWithCallback(callback);

    _eventControllers[currentTextureId] =
        StreamController<VideoEvent>.broadcast();
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

  @override
  Future<void> setDataSource(int? textureId, DataSource dataSource) async {
    if (textureId == null) return;
    final player = getPlayer(textureId);
    if (player == null) return;

    if (dataSource.uri?.contains('.mpd') == true ||
        dataSource.formatHint == VideoFormat.dash) {
      throw Exception(
        'DASH streams are not supported on iOS platform. Please use HLS instead.',
      );
    }

    final cacheManager = createCacheManager();
    final overriddenDuration =
        dataSource.overriddenDuration?.inMilliseconds ?? 0;
    final key = dataSource.key.toNSString();

    if (dataSource.sourceType == DataSourceType.asset) {
      player.setDataSourceAsset(
        (dataSource.asset ?? dataSource.uri!).toNSString(),
        key: key,
        cacheManager: cacheManager,
        overriddenDuration: overriddenDuration,
      );
    } else {
      player.setDataSourceURLString(
        dataSource.uri!.toNSString(),
        key: key,
        certificateUrl: dataSource.drmConfiguration?.certificateUrl
            ?.toNSString(),
        licenseUrl: dataSource.drmConfiguration?.licenseUrl?.toNSString(),
        useCache: dataSource.cacheConfiguration?.useCache ?? false,
        cacheKey: dataSource.cacheConfiguration?.key?.toNSString(),
        cacheManager: cacheManager,
        overriddenDuration: overriddenDuration,
        videoExtension: dataSource.videoExtension?.toNSString(),
      );
    }
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {
    if (textureId == null) return;
    getPlayer(textureId)?.setLooping(looping);
  }

  @override
  Future<void> play(int? textureId) async {
    if (textureId == null) return;
    getPlayer(textureId)?.play();
  }

  @override
  Future<void> pause(int? textureId) async {
    if (textureId == null) return;
    getPlayer(textureId)?.pause();
  }

  @override
  Future<void> setVolume(int? textureId, double volume) async {
    if (textureId == null) return;
    getPlayer(textureId)?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    if (textureId == null) return;
    getPlayer(textureId)?.setSpeed(speed);
  }

  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    if (textureId == null || position == null) return;
    getPlayer(textureId)?.seekTo(position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int? textureId) async {
    if (textureId == null) return Duration.zero;
    final pos = getPlayer(textureId)?.position();
    return Duration(milliseconds: pos ?? 0);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return _eventControllers[textureId]?.stream ?? const Stream.empty();
  }
}
