import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/shaka_player.dart';
import 'package:web/web.dart' as web;

class WebVideoPlayer {
  WebVideoPlayer({required this.viewId});

  final String viewId;
  late web.HTMLVideoElement videoElement;
  late ShakaPlayer _shakaPlayer;
  late StreamController<VideoEvent> _eventController;
  String? _currentKey;
  bool _disposed = false;
  Duration? overriddenDuration;

  Stream<VideoEvent> get events => _eventController.stream;

  void initialize() {
    _eventController = StreamController<VideoEvent>.broadcast();

    videoElement = web.HTMLVideoElement();
    videoElement.style.width = '100%';
    videoElement.style.height = '100%';
    videoElement.setAttribute('playsinline', '');
    videoElement.setAttribute('webkit-playsinline', '');

    shaka.polyfill.installAll();

    _shakaPlayer = ShakaPlayer(videoElement);

    _attachNativeListeners();
  }

  void _attachNativeListeners() {
    videoElement.addEventListener(
      'loadedmetadata',
      ((web.Event _) {
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
        _eventController.add(
          VideoEvent(eventType: VideoEventType.completed, key: _currentKey),
        );
      }).toJS,
    );

    Timer? _bufferingTimer;
    bool _isBuffering = false;

    videoElement.addEventListener(
      'waiting',
      ((web.Event _) {
        print('[WebVideoPlayer] Event: WAITING (Buffering started)');
        _bufferingTimer?.cancel();
        _bufferingTimer = Timer(const Duration(milliseconds: 200), () {
          if (_disposed) return;
          _isBuffering = true;
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
        print('[WebVideoPlayer] Event: PLAYING (Buffering ended)');
        _bufferingTimer?.cancel();
        if (_isBuffering) {
          _isBuffering = false;
          _eventController.add(
            VideoEvent(eventType: VideoEventType.bufferingEnd, key: _currentKey),
          );
        }
        _emitBufferingUpdate();
      }).toJS,
    );

    videoElement.addEventListener(
      'progress',
      ((web.Event _) {
        _emitBufferingUpdate();
      }).toJS,
    );

    videoElement.addEventListener(
      'error',
      ((web.Event _) {
        print('[WebVideoPlayer] Event: ERROR on VideoElement');
      }).toJS,
    );

    videoElement.addEventListener(
      'stalled',
      ((web.Event _) {
        print('[WebVideoPlayer] Event: STALLED');
      }).toJS,
    );

    videoElement.addEventListener(
      'play',
      ((web.Event _) {
        print('[WebVideoPlayer] Event: PLAY');
        _eventController.add(
          VideoEvent(eventType: VideoEventType.play, key: _currentKey),
        );
      }).toJS,
    );

    videoElement.addEventListener(
      'pause',
      ((web.Event _) {
        print('[WebVideoPlayer] Event: PAUSE');
        _eventController.add(
          VideoEvent(eventType: VideoEventType.pause, key: _currentKey),
        );
      }).toJS,
    );

    DateTime _lastSeekUpdate = DateTime.now();

    videoElement.addEventListener(
      'seeked',
      ((web.Event _) {
        print('[WebVideoPlayer] Event: SEEKED');
        final now = DateTime.now();
        if (now.difference(_lastSeekUpdate).inMilliseconds > 200) {
          _lastSeekUpdate = now;
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

  DateTime _lastBufferingUpdate = DateTime.now();

  void _emitBufferingUpdate() {
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
    _currentKey = dataSource.key;
    overriddenDuration = dataSource.overriddenDuration;

    final config = _buildShakaConfig(dataSource);
    if (config != null) {
      _shakaPlayer.configure(config);
    }

    if (dataSource.headers != null && dataSource.headers!.isNotEmpty) {
      _attachRequestFilter(dataSource.headers!);
    }

    // Convert data to URI if memory data source is handled outside by better_player_controller
    // The controller layer sets uri for memory data sources, so uri! should be present.
    await _shakaPlayer.load(dataSource.uri!.toJS).toDart;
  }

  JSObject? _buildShakaConfig(DataSource dataSource) {
    final drm = dataSource.drmConfiguration;
    if (drm == null) return null;

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
    _shakaPlayer.getNetworkingEngine().registerRequestFilter(
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
    print('[WebVideoPlayer] Flutter is calling seekTo: $position');
    videoElement.currentTime = position.inMilliseconds / 1000.0;
  }

  Duration getPosition() {
    return Duration(milliseconds: (videoElement.currentTime * 1000).toInt());
  }

  DateTime? getAbsolutePosition() {
    if (!_shakaPlayer.isLive().toDart) return null;
    final ms = _shakaPlayer.getPlayheadTimeAsDate().toDartDouble.toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void setTrackParameters(int? width, int? height, int? bitrate) {
    print('[WebVideoPlayer] setTrackParameters(width: $width, height: $height, bitrate: $bitrate)');
    if ((width == null || width == 0) &&
        (height == null || height == 0) &&
        (bitrate == null || bitrate == 0)) {
      print('[WebVideoPlayer] Default track detected, configuring ABR: true');
      _shakaPlayer.configure({'abr': {'enabled': true}}.jsify()! as JSObject);
      return;
    }

    final tracks = _shakaPlayer.getVariantTracks().toDart;

    JSObject? best;
    int? bestScore;

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
      print('[WebVideoPlayer] Forcing variant track and disabling ABR');
      _shakaPlayer.configure({'abr': {'enabled': false}}.jsify()! as JSObject);
      _shakaPlayer.selectVariantTrack(best, true.toJS);
    }
  }

  void setAudioTrack(String? language, int? index) {
    print('[WebVideoPlayer] setAudioTrack(language: $language, index: $index)');
    if (language != null) {
      _shakaPlayer.selectAudioLanguage(language.toJS);
    }
  }

  List<JSObject> getTextTracks() => _shakaPlayer.getTextTracks().toDart;

  void selectTextTrack(JSObject track) => _shakaPlayer.selectTextTrack(track);

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
    if (_disposed) return;
    _disposed = true;
    await _shakaPlayer.destroy().toDart;
    await _eventController.close();
  }
}
