// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Dart imports:
import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

final BetterPlayerPlatform _betterPlayerPlatform =
    BetterPlayerPlatform.instance;

/// Controls a platform video player, and provides updates when the state is
/// changing.
///
/// Instances must be initialized with initialize.
///
/// The video is displayed in a Flutter app by creating a [VideoPlayer] widget.
///
/// To reclaim the resources used by the player call [dispose].
///
/// After [dispose] all further calls are ignored.
class PlayerEngineController extends ValueNotifier<VideoPlayerValue> {
  /// Constructs a [VideoPlayerController] and creates video controller on platform side.
  PlayerEngineController({
    this.bufferingConfiguration = const BufferingConfiguration(),
    bool autoCreate = true,
  }) : super(VideoPlayerValue(duration: null)) {
    if (autoCreate) {
      _create();
    }
  }
  final BufferingConfiguration bufferingConfiguration;

  final StreamController<VideoEvent> videoEventStreamController =
      StreamController.broadcast();
  final Completer<void> _creatingCompleter = Completer<void>();
  int? _textureId;

  Timer? _timer;
  bool _isDisposed = false;
  StreamSubscription<dynamic>? _eventSubscription;

  bool get _created => _creatingCompleter.isCompleted;
  Duration? _seekPosition;

  /// The id of a texture that hasn't been initialized is null.
  int? get textureId => _textureId;

  /// Attempts to open the given [dataSource] and load metadata about the video.
  Future<void> _create() async {
    _textureId = await _betterPlayerPlatform.create(
      bufferingConfiguration: bufferingConfiguration,
    );
    _creatingCompleter.complete(null);

    unawaited(_applyLooping());
    unawaited(_applyVolume());

    void eventListener(VideoEvent event) {
      if (_isDisposed) {
        return;
      }
      PlayerLogger.debug(
        message: 'VideoPlayerController: Event received: ${event.eventType}',
      );
      videoEventStreamController.add(event);
      switch (event.eventType) {
        case VideoEventType.initialized:
          value = value.copyWith(duration: event.duration, size: event.size);
          _applyPlayPause();
        case VideoEventType.completed:
          value = value.copyWith(isPlaying: false, position: value.duration);
          _timer?.cancel();
        case VideoEventType.bufferingUpdate:
          value = value.copyWith(buffered: event.buffered);
        case VideoEventType.bufferingStart:
          value = value.copyWith(isBuffering: true);
        case VideoEventType.bufferingEnd:
          if (value.isBuffering) {
            value = value.copyWith(isBuffering: false);
          }

        case VideoEventType.play:
          play();
        case VideoEventType.pause:
          pause();
        case VideoEventType.seek:
          seekTo(event.position);
        case VideoEventType.pipStart:
          value = value.copyWith(isPip: true);
        case VideoEventType.pipStop:
          value = value.copyWith(isPip: false);
        case VideoEventType.changedSize:
          if (event.size != null &&
              event.size!.width > 0 &&
              event.size!.height > 0) {
            value = value.copyWith(size: event.size);
          }
        case VideoEventType.unknown:
          break;
      }
    }

    void errorListener(Object object) {
      if (object is PlatformException) {
        final e = object;
        value = value.copyWith(errorDescription: e.message);
      } else {
        value = value.copyWith(errorDescription: object.toString());
      }
      _timer?.cancel();
      videoEventStreamController.addError(object);
    }

    _eventSubscription = _betterPlayerPlatform
        .videoEventsFor(_textureId)
        .listen(eventListener, onError: errorListener);
  }

  /// Set data source for playing a video from an asset.
  ///
  /// The name of the asset is given by the [dataSource] argument and must not be
  /// null. The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  Future<void> setAssetDataSource(
    String dataSource, {
    String? package,
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    String? activityName,
  }) {
    return _setDataSource(
      DataSource(
        sourceType: DataSourceType.asset,
        asset: dataSource,
        package: package,
        notificationConfiguration: NotificationConfiguration(
          showNotification: showNotification,
          title: title,
          author: author,
          imageUrl: imageUrl,
          notificationChannelName: notificationChannelName,
          activityName: activityName,
        ),
        overriddenDuration: overriddenDuration,
      ),
    );
  }

  /// Set data source for playing a video from obtained from
  /// the network.
  ///
  /// The URI for the video is given by the [dataSource] argument and must not be
  /// null.
  /// **Android only**: The [formatHint] option allows the caller to override
  /// the video format detection code.
  /// ClearKey DRM only supported on Android.
  Future<void> setNetworkDataSource(
    String dataSource, {
    VideoFormat? formatHint,
    Map<String, String?>? headers,
    bool useCache = false,
    int? maxCacheSize,
    int? maxCacheFileSize,
    String? cacheKey,
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    String? licenseUrl,
    String? certificateUrl,
    Map<String, String>? drmHeaders,
    String? activityName,
    String? clearKey,
    String? videoExtension,
  }) {
    return _setDataSource(
      DataSource(
        sourceType: DataSourceType.network,
        uri: dataSource,
        formatHint: formatHint,
        headers: headers,
        cacheConfiguration: CacheConfiguration(
          useCache: useCache,
          maxCacheSize: maxCacheSize ?? 0,
          maxCacheFileSize: maxCacheFileSize ?? 0,
          key: cacheKey,
        ),
        notificationConfiguration: NotificationConfiguration(
          showNotification: showNotification,
          title: title,
          author: author,
          imageUrl: imageUrl,
          notificationChannelName: notificationChannelName,
          activityName: activityName,
        ),
        overriddenDuration: overriddenDuration,
        drmConfiguration: DrmConfiguration(
          licenseUrl: licenseUrl,
          certificateUrl: certificateUrl,
          headers: drmHeaders,
          clearKey: clearKey,
        ),
        videoExtension: videoExtension,
      ),
    );
  }

  /// Set data source for playing a video from a file.
  ///
  /// This will load the file from the file-URI given by:
  /// `'file://${file.path}'`.
  Future<void> setFileDataSource(
    File file, {
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    String? activityName,
    String? clearKey,
  }) {
    return _setDataSource(
      DataSource(
        sourceType: DataSourceType.file,
        uri: 'file://${file.path}',
        notificationConfiguration: NotificationConfiguration(
          showNotification: showNotification,
          title: title,
          author: author,
          imageUrl: imageUrl,
          notificationChannelName: notificationChannelName,
          activityName: activityName,
        ),
        overriddenDuration: overriddenDuration,
        drmConfiguration: DrmConfiguration(clearKey: clearKey),
      ),
    );
  }

  Future<void> _setDataSource(DataSource dataSourceDescription) async {
    if (_isDisposed) {
      return;
    }

    value = VideoPlayerValue(
      duration: null,
      isLooping: value.isLooping,
      volume: value.volume,
    );

    if (!_creatingCompleter.isCompleted) await _creatingCompleter.future;

    final completer = Completer<void>();
    final subscription = videoEventStreamController.stream.listen(
      (event) {
        if (event.eventType == VideoEventType.initialized) {
          completer.complete();
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Stream closed'));
        }
      },
      cancelOnError: true,
    );

    try {
      PlayerLogger.debug(
        message: 'VideoPlayerController: setDataSource platform call starting',
      );
      await BetterPlayerPlatform.instance.setDataSource(
        _textureId,
        dataSourceDescription,
      );
      PlayerLogger.debug(
        message:
            'VideoPlayerController: setDataSource platform call finished, waiting for init event',
      );
      await completer.future;
      PlayerLogger.debug(
        message: 'VideoPlayerController: setDataSource init event received',
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> dispose() async {
    await _creatingCompleter.future;
    if (!_isDisposed) {
      _isDisposed = true;
      value = VideoPlayerValue.uninitialized();
      _timer?.cancel();
      await _eventSubscription?.cancel();
      await _betterPlayerPlatform.dispose(_textureId);
      videoEventStreamController.close();
    }
    _isDisposed = true;
    super.dispose();
  }

  /// Starts playing the video.
  ///
  /// This method returns a future that completes as soon as the "play" command
  /// has been sent to the platform, not when playback itself is totally
  /// finished.
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  /// Sets whether or not the video should loop after playing once. See also
  /// [VideoPlayerValue.isLooping].
  Future<void> setLooping(bool looping) async {
    value = value.copyWith(isLooping: looping);
    await _applyLooping();
  }

  /// Pauses the video.
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  Future<void> _applyLooping() async {
    if (!_created || _isDisposed) {
      return;
    }
    await _betterPlayerPlatform.setLooping(_textureId, value.isLooping);
  }

  Future<void> _applyPlayPause() async {
    if (!_created || _isDisposed) {
      return;
    }
    _timer?.cancel();
    if (value.isPlaying) {
      await _betterPlayerPlatform.play(_textureId);
      _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
        if (_isDisposed) {
          return;
        }
        final newPosition = await position;
        final newAbsolutePosition = await absolutePosition;
        // ignore: invariant_booleans
        if (_isDisposed) {
          return;
        }
        _updatePosition(newPosition, absolutePosition: newAbsolutePosition);
        if (_seekPosition != null && newPosition != null) {
          final difference =
              newPosition.inMilliseconds - _seekPosition!.inMilliseconds;
          if (difference > 0) {
            _seekPosition = null;
          }
        }
      });
    } else {
      await _betterPlayerPlatform.pause(_textureId);
    }
  }

  Future<void> _applyVolume() async {
    if (!_created || _isDisposed) {
      return;
    }
    await _betterPlayerPlatform.setVolume(_textureId, value.volume);
  }

  Future<void> _applySpeed() async {
    if (!_created || _isDisposed) {
      return;
    }
    await _betterPlayerPlatform.setSpeed(_textureId, value.speed);
  }

  /// The position in the current video.
  Future<Duration?> get position async {
    if (!value.initialized && _isDisposed) {
      return null;
    }
    return _betterPlayerPlatform.getPosition(_textureId);
  }

  /// The absolute position in the current video stream
  /// (i.e. EXT-X-PROGRAM-DATE-TIME in HLS).
  Future<DateTime?> get absolutePosition async {
    if (!value.initialized && _isDisposed) {
      return null;
    }
    return _betterPlayerPlatform.getAbsolutePosition(_textureId);
  }

  /// Sets the video's current timestamp to be at [moment]. The next
  /// time the video is played it will resume from the given [moment].
  ///
  /// If [moment] is outside of the video's full range it will be automatically
  /// and silently clamped.
  Future<void> seekTo(Duration? position) async {
    _timer?.cancel();
    var isPlaying = value.isPlaying;
    final positionInMs = value.position.inMilliseconds;
    final durationInMs = value.duration?.inMilliseconds ?? 0;

    if (positionInMs >= durationInMs && position?.inMilliseconds == 0) {
      isPlaying = true;
    }
    if (_isDisposed) {
      return;
    }

    var positionToSeek = position;
    if (value.duration != null && position != null) {
      if (position > value.duration!) {
        positionToSeek = value.duration;
      }
    }
    if (position != null && position < const Duration()) {
      positionToSeek = const Duration();
    }
    _seekPosition = positionToSeek;

    await _betterPlayerPlatform.seekTo(_textureId, positionToSeek);
    _updatePosition(position);

    if (isPlaying) {
      play();
    } else {
      pause();
    }
  }

  /// Sets the audio volume of [this].
  ///
  /// [volume] indicates a value between 0.0 (silent) and 1.0 (full volume) on a
  /// linear scale.
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume.clamp(0.0, 1.0));
    await _applyVolume();
  }

  /// Sets the speed of [this].
  ///
  /// [speed] indicates a value between 0.0 and 2.0 on a linear scale.
  Future<void> setSpeed(double speed) async {
    final previousSpeed = value.speed;
    try {
      value = value.copyWith(speed: speed);
      await _applySpeed();
    } catch (exception) {
      value = value.copyWith(speed: previousSpeed);
      rethrow;
    }
  }

  /// Sets the video track parameters of [this]
  ///
  /// [width] specifies width of the selected track
  /// [height] specifies height of the selected track
  /// [bitrate] specifies bitrate of the selected track
  Future<void> setTrackParameters(int? width, int? height, int? bitrate) async {
    await _betterPlayerPlatform.setTrackParameters(
      _textureId,
      width,
      height,
      bitrate,
    );
  }

  Future<void> enablePictureInPicture({
    double? top,
    double? left,
    double? width,
    double? height,
  }) async {
    await _betterPlayerPlatform.enablePictureInPicture(
      textureId,
      top,
      left,
      width,
      height,
    );
  }

  Future<void> disablePictureInPicture() async {
    await _betterPlayerPlatform.disablePictureInPicture(textureId);
  }

  void _updatePosition(Duration? position, {DateTime? absolutePosition}) {
    value = value.copyWith(position: _seekPosition ?? position);
    if (_seekPosition == null) {
      value = value.copyWith(absolutePosition: absolutePosition);
    }
  }

  Future<bool?> isPictureInPictureSupported() async {
    if (_textureId == null) {
      return false;
    }
    return _betterPlayerPlatform.isPictureInPictureSupported(_textureId);
  }

  void refresh() {
    value = value.copyWith();
  }

  void setAudioTrack(String? name, int? index) {
    _betterPlayerPlatform.setAudioTrack(_textureId, name, index);
  }

  void setMixWithOthers(bool mixWithOthers) {
    _betterPlayerPlatform.setMixWithOthers(_textureId, mixWithOthers);
  }

  static Future clearCache() async {
    return _betterPlayerPlatform.clearCache();
  }

  static Future preCache(DataSource dataSource, int preCacheSize) async {
    return _betterPlayerPlatform.preCache(dataSource, preCacheSize);
  }

  static Future stopPreCache(String url, String? cacheKey) async {
    return _betterPlayerPlatform.stopPreCache(url, cacheKey);
  }
}
