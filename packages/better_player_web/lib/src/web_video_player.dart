import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/shaka_player.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

class BetterPlayerWebPlayer {
  BetterPlayerWebPlayer({
    required this.viewId,
    required this.onLog,
    @visibleForTesting ShakaPlayer? shakaPlayer,
  }) : _shakaPlayer = shakaPlayer;

  final void Function(String) onLog;

  final String viewId;
  late web.HTMLVideoElement videoElement;
  ShakaPlayer? _shakaPlayer;
  late StreamController<VideoEvent> _eventController;
  String? _currentKey;
  bool _disposed = false;
  DateTime _lastBufferingUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  @visibleForTesting
  Duration? overriddenDuration;

  Stream<VideoEvent> get events => _eventController.stream;

  void initialize() {
    onLog('Initializing BetterPlayerWebPlayer: $viewId');
    _eventController = StreamController<VideoEvent>.broadcast();

    videoElement = web.HTMLVideoElement();
    videoElement.style.width = '100%';
    videoElement.style.height = '100%';
    videoElement.setAttribute('playsinline', '');
    videoElement.setAttribute('webkit-playsinline', '');

    onLog('Installing Shaka polyfills');
    shaka.polyfill.installAll();

    onLog('Creating Shaka player');
    _shakaPlayer ??= ShakaPlayer(videoElement);

    onLog('Attaching listeners');
    _attachListeners();
    onLog('Initialization complete');
  }

  void _attachListeners() {
    onLog('Attaching listener: loadedmetadata');
    videoElement.addEventListener(
      'loadedmetadata',
      ((web.Event _) {
        onLog('Event: loadedmetadata');
        final raw = videoElement.duration;
        final duration =
            overriddenDuration ??
            ((raw.isNaN || raw.isInfinite)
                ? Duration.zero
                : Duration(milliseconds: (raw * 1000).toInt()));

        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            key: _currentKey,
            duration: duration,
            size: Size(
              videoElement.videoWidth.toDouble(),
              videoElement.videoHeight.toDouble(),
            ),
          ),
        );
      }).toJS,
    );

    videoElement.addEventListener(
      'ended',
      ((web.Event _) {
        onLog('Event: ended');
        _eventController.add(
          VideoEvent(eventType: VideoEventType.completed, key: _currentKey),
        );
      }).toJS,
    );

    Timer? bufferingTimer;
    var isBuffering = false;

    videoElement.addEventListener(
      'waiting',
      ((web.Event _) {
        onLog('Event: WAITING (Buffering started)');
        bufferingTimer?.cancel();
        bufferingTimer = Timer(const Duration(milliseconds: 200), () {
          if (_disposed) return;
          isBuffering = true;
          _eventController.add(
            VideoEvent(
              eventType: VideoEventType.bufferingStart,
              key: _currentKey,
            ),
          );
        });
      }).toJS,
    );

    videoElement.addEventListener(
      'playing',
      ((web.Event _) {
        onLog('Event: PLAYING (Buffering ended)');
        bufferingTimer?.cancel();
        if (isBuffering) {
          isBuffering = false;
          _eventController.add(
            VideoEvent(
              eventType: VideoEventType.bufferingEnd,
              key: _currentKey,
            ),
          );
        }
        emitBufferingUpdate();
      }).toJS,
    );

    videoElement.addEventListener(
      'progress',
      ((web.Event _) {
        emitBufferingUpdate();
      }).toJS,
    );

    videoElement.addEventListener(
      'error',
      ((web.Event _) {
        onLog('Event: ERROR on VideoElement');
      }).toJS,
    );

    videoElement.addEventListener(
      'stalled',
      ((web.Event _) {
        onLog('Event: STALLED');
      }).toJS,
    );

    videoElement.addEventListener(
      'play',
      ((web.Event _) {
        onLog('Event: PLAY');
        _eventController.add(
          VideoEvent(eventType: VideoEventType.play, key: _currentKey),
        );
      }).toJS,
    );

    videoElement.addEventListener(
      'pause',
      ((web.Event _) {
        onLog('Event: PAUSE');
        _eventController.add(
          VideoEvent(eventType: VideoEventType.pause, key: _currentKey),
        );
      }).toJS,
    );

    var lastSeekUpdate = DateTime.now();

    videoElement.addEventListener(
      'seeked',
      ((web.Event _) {
        onLog('Event: SEEKED');
        final now = DateTime.now();
        if (now.difference(lastSeekUpdate).inMilliseconds > 200) {
          lastSeekUpdate = now;
          _eventController.add(
            VideoEvent(
              eventType: VideoEventType.seek,
              key: _currentKey,
              position: Duration(
                milliseconds: (videoElement.currentTime * 1000).toInt(),
              ),
            ),
          );
        }
      }).toJS,
    );

    videoElement.addEventListener(
      'resize',
      ((web.Event _) {
        onLog('Event: resize');
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.changedSize,
            key: _currentKey,
            size: Size(
              videoElement.videoWidth.toDouble(),
              videoElement.videoHeight.toDouble(),
            ),
          ),
        );
      }).toJS,
    );

    videoElement.addEventListener(
      'enterpictureinpicture',
      ((web.Event _) {
        _eventController.add(
          VideoEvent(eventType: VideoEventType.pipStart, key: _currentKey),
        );
      }).toJS,
    );

    videoElement.addEventListener(
      'leavepictureinpicture',
      ((web.Event _) {
        _eventController.add(
          VideoEvent(eventType: VideoEventType.pipStop, key: _currentKey),
        );
      }).toJS,
    );
  }

  @visibleForTesting
  void emitBufferingUpdate() {
    final now = DateTime.now();
    if (now.difference(_lastBufferingUpdate).inMilliseconds < 500) {
      return;
    }
    _lastBufferingUpdate = now;

    final buffered = <DurationRange>[];
    final timeRanges = videoElement.buffered;
    for (var i = 0; i < timeRanges.length; i++) {
      buffered.add(
        DurationRange(
          Duration(milliseconds: (timeRanges.start(i) * 1000).toInt()),
          Duration(milliseconds: (timeRanges.end(i) * 1000).toInt()),
        ),
      );
    }
    _eventController.add(
      VideoEvent(
        eventType: VideoEventType.bufferingUpdate,
        key: _currentKey,
        buffered: buffered,
      ),
    );
  }

  Future<void> setDataSource(DataSource dataSource) async {
    onLog('Setting data source: ${dataSource.uri}');
    _currentKey = dataSource.key;
    overriddenDuration = dataSource.overriddenDuration;

    onLog('Building Shaka config');
    final config = buildShakaConfig(dataSource);
    if (config != null) {
      onLog('Configuring Shaka player');
      _shakaPlayer!.configure(config);
    }

    if (dataSource.headers != null && dataSource.headers!.isNotEmpty) {
      onLog('Attaching request filter for headers');
      _attachRequestFilter(dataSource.headers!);
    }

    // Convert data to URI if memory data source is handled outside by better_player_controller
    // The controller layer sets uri for memory data sources, so uri! should be present.
    onLog('Loading URI: ${dataSource.uri}');
    await _shakaPlayer!.load(dataSource.uri!.toJS).toDart;
    onLog('URI loaded successfully');
  }

  @visibleForTesting
  JSObject? buildShakaConfig(DataSource dataSource) {
    final drm = dataSource.drmConfiguration;
    if (drm == null) return null;
// ... (rest of the code)

    final servers = <String, String>{};
    final advanced = <String, Object>{};

    switch (drm.drmType) {
      case DrmType.widevine:
        if (drm.licenseUrl != null) {
          servers['com.widevine.alpha'] = drm.licenseUrl!;
        }
        if (drm.headers != null && drm.headers!.isNotEmpty) {
          advanced['com.widevine.alpha'] = {
            'licenseRequestHeaders': drm.headers!,
          };
        }
      case DrmType.fairplay:
        if (drm.licenseUrl != null) {
          servers['com.apple.fps'] = drm.licenseUrl!;
        }
        if (drm.certificateUrl != null) {
          advanced['com.apple.fps'] = {
            'serverCertificateUri': drm.certificateUrl!,
          };
        }
      case DrmType.clearKey:
      // ClearKey support could be added here parsing drm.clearKey JSON string
      case DrmType.token:
        if (drm.licenseUrl != null) {
          servers['com.widevine.alpha'] = drm.licenseUrl!;
        }
        if (drm.token != null) {
          advanced['com.widevine.alpha'] = {
            'licenseRequestHeaders': {'Authorization': 'Bearer ${drm.token}'},
          };
        }
      case null:
    }

    return {
          'drm': {
            'servers': servers,
            'advanced': advanced,
          },
        }.jsify()!
        as JSObject;
  }

  void _attachRequestFilter(Map<String, String?> headers) {
    _shakaPlayer!.getNetworkingEngine().registerRequestFilter(
      ((JSNumber type, JSObject request) {
        final requestHeaders = request['headers']! as JSObject;
        for (final entry in headers.entries) {
          if (entry.value != null) {
            requestHeaders[entry.key] = entry.value!.toJS;
          }
        }
      }).toJS,
    );
  }

  void play() => videoElement.play();
  void pause() => videoElement.pause();
  void setVolume(double volume) => videoElement.volume = volume;
  void setSpeed(double speed) => videoElement.playbackRate = speed;
  void setLooping(bool looping) => videoElement.loop = looping;

  void seekTo(Duration position) {
    onLog('Flutter is calling seekTo: $position');
    videoElement.currentTime = position.inMilliseconds / 1000.0;
  }

  Duration getPosition() {
    return Duration(milliseconds: (videoElement.currentTime * 1000).toInt());
  }

  DateTime? getAbsolutePosition() {
    if (!_shakaPlayer!.isLive().toDart) return null;
    final dateObj = _shakaPlayer!.getPlayheadTimeAsDate();
    if (dateObj == null) return null;
    try {
      final jsNum =
          (dateObj as JSObject).callMethod('getTime'.toJS) as JSNumber?;
      if (jsNum == null) return null;
      final ms = jsNum.toDartInt;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  void setTrackParameters({int? width, int? height, int? bitrate}) {
    onLog(
      'setTrackParameters(width: $width, height: $height, bitrate: $bitrate)',
    );
    if ((width == null || width == 0) &&
        (height == null || height == 0) &&
        (bitrate == null || bitrate == 0)) {
      onLog('Default track detected, configuring ABR: true');
      _shakaPlayer!.configure(
        {
              'abr': {'enabled': true},
            }.jsify()!
            as JSObject,
      );
      return;
    }

    final tracks = _shakaPlayer!.getVariantTracks().toDart;

    JSObject? best;
    int? bestScore;

    // Iterate over all available variant tracks to find the best match based on width, height, and bitrate (max score 3)
    for (final track in tracks) {
      final trackWidth = (track['width'] as JSNumber?)?.toDartInt;
      final trackHeight = (track['height'] as JSNumber?)?.toDartInt;
      final trackBw = (track['bandwidth'] as JSNumber?)?.toDartInt;

      var score = 0;
      if (width != null && trackWidth == width) score++;
      if (height != null && trackHeight == height) score++;
      if (bitrate != null && trackBw == bitrate) score++;

      if (bestScore == null || score > bestScore) {
        best = track;
        bestScore = score;
      }
    }

    if (best != null) {
      onLog('Forcing variant track and disabling ABR');
      _shakaPlayer!.configure(
        {
              'abr': {'enabled': false},
            }.jsify()!
            as JSObject,
      );
      _shakaPlayer!.selectVariantTrack(best, true.toJS);
    }
  }

  void setAudioTrack({String? language, int? index}) {
    onLog('setAudioTrack(language: $language, index: $index)');
    if (language != null) {
      _shakaPlayer!.selectAudioLanguage(language.toJS);
    }
  }

  List<JSObject> getTextTracks() => _shakaPlayer!.getTextTracks().toDart;

  void selectTextTrack(JSObject track) => _shakaPlayer!.selectTextTrack(track);

  Future<void> enablePictureInPicture() async {
    if (!web.document.pictureInPictureEnabled) return;
    await videoElement.requestPictureInPicture().toDart;
  }

  Future<void> disablePictureInPicture() async {
    if (web.document.pictureInPictureElement == null) return;
    await web.document.exitPictureInPicture().toDart;
  }

  bool isPictureInPictureSupported() {
    return web.document.pictureInPictureEnabled;
  }

  Future<void> dispose() async {
    onLog('Disposing BetterPlayerWebPlayer: $viewId');
    if (_disposed) {
      onLog('Already disposed');
      return;
    }
    _disposed = true;
    if (_shakaPlayer != null) {
      onLog('Destroying Shaka player');
      await _shakaPlayer!.destroy().toDart;
      onLog('Shaka player destroyed');
    }
    onLog('Closing event controller');
    await _eventController.close();
    onLog('Dispose complete');
  }
}
