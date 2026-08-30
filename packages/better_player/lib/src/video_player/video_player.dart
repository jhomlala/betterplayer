// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Dart imports:
import 'dart:async';
import 'dart:io';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

export 'package:better_player_platform_interface/better_player_platform_interface.dart'
    show VideoPlayerValue;

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
class VideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  /// Constructs a [VideoPlayerController] and creates video controller on platform side.
  VideoPlayerController({
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

  /// This is just exposed for testing. It shouldn't be used by anyone depending
  /// on the plugin.
  @visibleForTesting
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
      BetterPlayerUtils.log(
        'VideoPlayerController: Event received: ${event.eventType}',
      );
      videoEventStreamController.add(event);
      switch (event.eventType) {
        case VideoEventType.initialized:
          value = value.copyWith(
            duration: event.duration,
            size: event.size,
          );
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
        drmConfiguration: DrmConfiguration(
          clearKey: clearKey,
        ),
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
      BetterPlayerUtils.log(
        'VideoPlayerController: setDataSource platform call starting',
      );
      await BetterPlayerPlatform.instance.setDataSource(
        _textureId,
        dataSourceDescription,
      );
      BetterPlayerUtils.log(
        'VideoPlayerController: setDataSource platform call finished, waiting for init event',
      );
      await completer.future;
      BetterPlayerUtils.log(
        'VideoPlayerController: setDataSource init event received',
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
      _timer = Timer.periodic(
        const Duration(milliseconds: 300),
        (timer) async {
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
        },
      );
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

/// Widget that displays the video controlled by [controller].
class VideoPlayer extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  const VideoPlayer(this.controller, {super.key});

  /// The [VideoPlayerController] responsible for the video being rendered in
  /// this widget.
  final VideoPlayerController? controller;

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final newTextureId = widget.controller!.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  late VoidCallback _listener;
  int? _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller!.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller!.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller!.removeListener(_listener);
    _textureId = widget.controller!.textureId;
    widget.controller!.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller!.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null
        ? Container()
        : _betterPlayerPlatform.buildView(_textureId);
  }
}

/// Used to configure the [VideoProgressIndicator] widget's colors for how it
/// describes the video's status.
///
/// The widget uses default colors that are customizeable through this class.
class VideoProgressColors {
  /// Any property can be set to any color. They each have defaults.
  ///
  /// [playedColor] defaults to red at 70% opacity. This fills up a portion of
  /// the [VideoProgressIndicator] to represent how much of the video has played
  /// so far.
  ///
  /// [bufferedColor] defaults to blue at 20% opacity. This fills up a portion
  /// of [VideoProgressIndicator] to represent how much of the video has
  /// buffered so far.
  ///
  /// [backgroundColor] defaults to gray at 50% opacity. This is the background
  /// color behind both [playedColor] and [bufferedColor] to denote the total
  /// size of the video compared to either of those values.
  VideoProgressColors({
    this.playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    this.bufferedColor = const Color.fromRGBO(50, 50, 200, 0.2),
    this.backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
  });

  /// [playedColor] defaults to red at 70% opacity. This fills up a portion of
  /// the [VideoProgressIndicator] to represent how much of the video has played
  /// so far.
  final Color playedColor;

  /// [bufferedColor] defaults to blue at 20% opacity. This fills up a portion
  /// of [VideoProgressIndicator] to represent how much of the video has
  /// buffered so far.
  final Color bufferedColor;

  /// [backgroundColor] defaults to gray at 50% opacity. This is the background
  /// color behind both [playedColor] and [bufferedColor] to denote the total
  /// size of the video compared to either of those values.
  final Color backgroundColor;
}

class _VideoScrubber extends StatefulWidget {
  const _VideoScrubber({
    required this.child,
    required this.controller,
  });

  final Widget child;
  final VideoPlayerController controller;

  @override
  _VideoScrubberState createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<_VideoScrubber> {
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final renderObject = context.findRenderObject();
      if (renderObject != null) {
        final box = renderObject as RenderBox;
        final tapPos = box.globalToLocal(globalPosition);
        final relative = tapPos.dx / box.size.width;
        final position = controller.value.duration! * relative;
        controller.seekTo(position);
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        if (!controller.value.initialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }
      },
      onHorizontalDragUpdate: (details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      onHorizontalDragEnd: (details) {
        if (_controllerWasPlaying) {
          controller.play();
        }
      },
      onTapDown: (details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      child: widget.child,
    );
  }
}

/// Displays the play/buffering status of the video controlled by [controller].
///
/// If [allowScrubbing] is true, this widget will detect taps and drags and
/// seek the video accordingly.
///
/// [padding] allows to specify some extra padding around the progress indicator
/// that will also detect the gestures.
class VideoProgressIndicator extends StatefulWidget {
  /// Construct an instance that displays the play/buffering status of the video
  /// controlled by [controller].
  ///
  /// Defaults will be used for everything except [controller] if they're not
  /// provided. [allowScrubbing] defaults to false, and [padding] will default
  /// to `top: 5.0`.
  VideoProgressIndicator(
    this.controller, {
    VideoProgressColors? colors,
    this.allowScrubbing,
    this.padding = const EdgeInsets.only(top: 5),
    super.key,
  }) : colors = colors ?? VideoProgressColors();

  /// The [VideoPlayerController] that actually associates a video with this
  /// widget.
  final VideoPlayerController controller;

  /// The default colors used throughout the indicator.
  ///
  /// See [VideoProgressColors] for default values.
  final VideoProgressColors colors;

  /// When true, the widget will detect touch input and try to seek the video
  /// accordingly. The widget ignores such input when false.
  ///
  /// Defaults to false.
  final bool? allowScrubbing;

  /// This allows for visual padding around the progress indicator that can
  /// still detect gestures via [allowScrubbing].
  ///
  /// Defaults to `top: 5.0`.
  final EdgeInsets padding;

  @override
  _VideoProgressIndicatorState createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  _VideoProgressIndicatorState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  late VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  VideoProgressColors get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Widget progressIndicator;
    if (controller.value.initialized) {
      final duration = controller.value.duration!.inMilliseconds;
      final position = controller.value.position.inMilliseconds;

      var maxBuffering = 0;
      for (final range in controller.value.buffered) {
        final end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          LinearProgressIndicator(
            value: maxBuffering / duration,
            valueColor: AlwaysStoppedAnimation<Color>(colors.bufferedColor),
            backgroundColor: colors.backgroundColor,
          ),
          LinearProgressIndicator(
            value: position / duration,
            valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
    } else {
      progressIndicator = LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
        backgroundColor: colors.backgroundColor,
      );
    }
    final Widget paddedProgressIndicator = Padding(
      padding: widget.padding,
      child: progressIndicator,
    );
    if (widget.allowScrubbing!) {
      return _VideoScrubber(
        controller: controller,
        child: paddedProgressIndicator,
      );
    } else {
      return paddedProgressIndicator;
    }
  }
}

/// Widget for displaying closed captions on top of a video.
///
/// If [text] is null, this widget will not display anything.
///
/// If [textStyle] is supplied, it will be used to style the text in the closed
/// caption.
///
/// Note: in order to have closed captions, you need to specify a
/// [VideoPlayerController.closedCaptionFile].
///
/// Usage:
///
/// ```dart
/// Stack(children: <Widget>[
///   VideoPlayer(_controller),
///   ClosedCaption(text: _controller.value.caption.text),
/// ]),
/// ```
class ClosedCaption extends StatelessWidget {
  /// Creates a a new closed caption, designed to be used with
  /// [VideoPlayerValue.caption].
  ///
  /// If [text] is null, nothing will be displayed.
  const ClosedCaption({super.key, this.text, this.textStyle});

  /// The text that will be shown in the closed caption, or null if no caption
  /// should be shown.
  final String? text;

  /// Specifies how the text in the closed caption should look.
  ///
  /// If null, defaults to [DefaultTextStyle.of(context).style] with size 36
  /// font colored white.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ??
        DefaultTextStyle.of(context).style.copyWith(
          fontSize: 36,
          color: Colors.white,
        );

    if (text == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB8000000),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(text!, style: effectiveTextStyle),
          ),
        ),
      ),
    );
  }
}
