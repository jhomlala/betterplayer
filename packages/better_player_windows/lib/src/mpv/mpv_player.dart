import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_windows/src/mpv/mpv_ffi.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

abstract class BetterPlayerWindowsPlayer {
  int get textureId;
  Stream<VideoEvent> get events;
  Future<void> dispose();
  Future<void> setDataSource(DataSource dataSource);
  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> seekTo(Duration position);
  Future<Duration> getPosition();
  Future<void> setLooping({required bool looping});
  Future<void> setTrackParameters({
    required int width,
    required int height,
    required int bitrate,
  });
  Future<void> setAudioTrack({required String name, required int index});
  Future<void> setTextTrack({required String name, required int index});
}

class MpvPlayer implements BetterPlayerWindowsPlayer {
  MpvPlayer({
    required this.textureId,
    required this.handle,
    this.bufferingConfiguration,
    MpvBindings? bindings,
    this.onLog,
  }) : _bindings = bindings ?? MpvBindings.instance! {
    _initEventStream();
    _applyBufferingConfiguration();
  }

  @override
  final int textureId;
  final ffi.Pointer<MpvHandle> handle;
  final BufferingConfiguration? bufferingConfiguration;
  final MpvBindings _bindings;
  final void Function({required String message, required int levelIndex})?
  onLog;

  void _log({required String message, int levelIndex = 1}) {
    onLog?.call(message: message, levelIndex: levelIndex);
  }

  final StreamController<VideoEvent> _eventController =
      StreamController<VideoEvent>.broadcast();
  bool _isDisposed = false;
  bool _completedEmitted = false;
  Timer? _pollingTimer;

  Duration _duration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration? _overriddenDuration;
  double _width = 0;
  double _height = 0;
  String? _currentKey;

  void _applyBufferingConfiguration() {
    final config = bufferingConfiguration;
    if (config == null) return;

    if (config.maxBufferMs > 0) {
      final bufferSecs = (config.maxBufferMs / 1000.0).clamp(1.0, 120.0);
      _setPropertyDouble(name: 'demuxer-readahead-secs', value: bufferSecs);
    }
    if (config.minBufferMs > 0) {
      final minSecs = (config.minBufferMs / 1000.0).clamp(0.1, 60.0);
      _setPropertyDouble(name: 'demuxer-cache-wait', value: minSecs);
    }
  }

  @override
  Stream<VideoEvent> get events => _eventController.stream;

  void _initEventStream() {
    // Observe core playback properties
    _observeProperty(name: 'pause', format: MpvFormat.flag);
    _observeProperty(name: 'time-pos', format: MpvFormat.doubleFormat);
    _observeProperty(name: 'duration', format: MpvFormat.doubleFormat);
    _observeProperty(name: 'eof-reached', format: MpvFormat.flag);
    _observeProperty(name: 'seeking', format: MpvFormat.flag);
    _observeProperty(name: 'paused-for-cache', format: MpvFormat.flag);
    _observeProperty(name: 'width', format: MpvFormat.int64);
    _observeProperty(name: 'height', format: MpvFormat.int64);
    _observeProperty(name: 'dwidth', format: MpvFormat.int64);
    _observeProperty(name: 'dheight', format: MpvFormat.int64);
    _observeProperty(
      name: 'demuxer-cache-time',
      format: MpvFormat.doubleFormat,
    );
    _observeProperty(name: 'sub-text', format: MpvFormat.string);

    // Suppress mpv native OSD subtitles so PlayerSubtitlesDrawer renders them in Flutter.
    _setPropertyString(name: 'sub-visibility', value: 'no');

    // Request mpv warnings and errors for logging
    final warnStr = 'warn'.toNativeUtf8();
    try {
      _bindings.mpvRequestLogMessages(handle, warnStr);
    } catch (_) {
      // mpvRequestLogMessages might not be implemented in mock bindings
    } finally {
      calloc.free(warnStr);
    }

    // Event polling timer
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _pollEvents();
    });
  }

  void _observeProperty({required String name, required int format}) {
    final namePtr = name.toNativeUtf8();
    try {
      _bindings.mpvObserveProperty(handle, 0, namePtr, format);
    } finally {
      calloc.free(namePtr);
    }
  }

  void _pollEvents() {
    if (_isDisposed) return;

    while (!_isDisposed) {
      final event = _bindings.mpvWaitEvent(handle, 0);
      if (event.ref.eventId == MpvEventId.none) {
        break;
      }
      _handleEvent(event);
    }
  }

  void _handleEvent(ffi.Pointer<MpvEvent> event) {
    switch (event.ref.eventId) {
      case MpvEventId.logMessage:
        final logData = event.ref.data.cast<MpvEventLogMessage>();
        if (logData != ffi.nullptr) {
          final prefix = logData.ref.prefix != ffi.nullptr
              ? logData.ref.prefix.toDartString()
              : 'mpv';
          final text = logData.ref.text != ffi.nullptr
              ? logData.ref.text.toDartString().trim()
              : '';
          if (text.isNotEmpty) {
            final level = logData.ref.logLevel;
            final levelIndex = level <= MpvLogLevel.error ? 3 : 2;
            _log(message: '[$prefix] $text', levelIndex: levelIndex);
          }
        }
      case MpvEventId.fileLoaded:
        _onFileLoaded();
      case MpvEventId.propertyChange:
        _onPropertyChange(event.ref.data.cast<MpvEventProperty>());
      case MpvEventId.seek:
        _completedEmitted = false;
        final posMs = _getPositionMs();
        if (posMs >= 0) {
          _currentPosition = Duration(milliseconds: posMs);
        }
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.seek,
            key: _currentKey,
            position: _currentPosition,
          ),
        );
      case MpvEventId.playbackRestart:
        _completedEmitted = false;
        final posMs = _getPositionMs();
        if (posMs >= 0) {
          _currentPosition = Duration(milliseconds: posMs);
        }
      case MpvEventId.endFile:
        final endFileData = event.ref.data.cast<MpvEventEndFile>();
        final errorCode =
            endFileData != ffi.nullptr && endFileData.ref.error < 0
            ? endFileData.ref.error
            : event.ref.error;
        final reason = endFileData != ffi.nullptr ? endFileData.ref.reason : -1;
        // Ignore audio initialization failures (-14: MPV_ERROR_AO_INIT_FAILED) on headless environments
        final isError =
            (event.ref.error < 0 ||
                (endFileData != ffi.nullptr &&
                    (endFileData.ref.reason == MpvEndFileReason.error ||
                        endFileData.ref.error < 0))) &&
            errorCode != -14;
        if (isError) {
          final errorStr = _bindings.errorString(errorCode);
          _log(
            message:
                'PlayerError: $errorStr (reason: $reason, code: $errorCode)',
            levelIndex: 3,
          );
          _eventController.addError(
            PlatformException(
              code: 'MPV_ERROR',
              message:
                  'Failed to load video: $errorStr (reason: $reason, code: $errorCode)',
            ),
          );
        } else if (!_completedEmitted) {
          _completedEmitted = true;
          _log(message: 'PlaybackState: ENDED');
          _eventController.add(
            VideoEvent(eventType: VideoEventType.completed, key: _currentKey),
          );
        }
    }
  }

  void _onFileLoaded() {
    final rawDuration = Duration(milliseconds: _getDurationMs());
    _duration = _overriddenDuration ?? rawDuration;
    final dWidth = _getIntProperty('dwidth').toDouble();
    final dHeight = _getIntProperty('dheight').toDouble();
    _width = dWidth > 0 ? dWidth : _getIntProperty('width').toDouble();
    _height = dHeight > 0 ? dHeight : _getIntProperty('height').toDouble();

    _log(
      message:
          'onInitialized: dur=${_duration.inMilliseconds}ms, size=${_width.toInt()}x${_height.toInt()}',
    );

    _eventController.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        key: _currentKey,
        duration: _duration,
        size: Size(_width, _height),
      ),
    );
  }

  void _onPropertyChange(ffi.Pointer<MpvEventProperty> prop) {
    if (prop == ffi.nullptr || prop.ref.name == ffi.nullptr) return;
    final name = prop.ref.name.toDartString();

    switch (name) {
      case 'pause':
        if (prop.ref.data != ffi.nullptr) {
          final isPaused = prop.ref.data.cast<ffi.Int32>().value != 0;
          _eventController.add(
            VideoEvent(
              eventType: isPaused ? VideoEventType.pause : VideoEventType.play,
              key: _currentKey,
            ),
          );
        }
      case 'paused-for-cache':
        if (prop.ref.data != ffi.nullptr) {
          final isBuffering = prop.ref.data.cast<ffi.Int32>().value != 0;
          _log(
            message: isBuffering
                ? 'PlaybackState: BUFFERING'
                : 'PlaybackState: READY',
          );
          _eventController.add(
            VideoEvent(
              eventType: isBuffering
                  ? VideoEventType.bufferingStart
                  : VideoEventType.bufferingEnd,
              key: _currentKey,
            ),
          );
        }
      case 'seeking':
        if (prop.ref.data != ffi.nullptr) {
          final isSeeking = prop.ref.data.cast<ffi.Int32>().value != 0;
          _log(
            message: isSeeking ? 'SeekingState: SEEKING' : 'SeekingState: IDLE',
            levelIndex: 0,
          );
        }
      case 'eof-reached':
        if (prop.ref.data != ffi.nullptr) {
          final isEof = prop.ref.data.cast<ffi.Int32>().value != 0;
          if (isEof && !_completedEmitted) {
            _completedEmitted = true;
            _log(message: 'PlaybackState: ENDED');
            _eventController.add(
              VideoEvent(
                eventType: VideoEventType.completed,
                key: _currentKey,
              ),
            );
          }
        }
      case 'width':
      case 'dwidth':
        if (prop.ref.data != ffi.nullptr) {
          final newWidth = prop.ref.data.cast<ffi.Int64>().value.toDouble();
          if (newWidth > 0 && newWidth != _width) {
            _width = newWidth;
            _notifyDimensionUpdate();
          }
        }
      case 'height':
      case 'dheight':
        if (prop.ref.data != ffi.nullptr) {
          final newHeight = prop.ref.data.cast<ffi.Int64>().value.toDouble();
          if (newHeight > 0 && newHeight != _height) {
            _height = newHeight;
            _notifyDimensionUpdate();
          }
        }
      case 'demuxer-cache-time':
        if (prop.ref.data != ffi.nullptr) {
          final cacheSecs = prop.ref.data.cast<ffi.Double>().value;
          if (cacheSecs >= 0) {
            final bufferedEnd =
                _currentPosition +
                Duration(milliseconds: (cacheSecs * 1000).toInt());
            _eventController.add(
              VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                key: _currentKey,
                buffered: <DurationRange>[
                  DurationRange(Duration.zero, bufferedEnd),
                ],
              ),
            );
          }
        }
      case 'duration':
        if (_overriddenDuration != null) {
          _duration = _overriddenDuration!;
          break;
        }
        if (prop.ref.data != ffi.nullptr) {
          final durSecs = prop.ref.data.cast<ffi.Double>().value;
          if (durSecs > 0) {
            _duration = Duration(milliseconds: (durSecs * 1000).toInt());
          }
        }
      case 'time-pos':
        if (prop.ref.data != ffi.nullptr) {
          final posSecs = prop.ref.data.cast<ffi.Double>().value;
          if (posSecs >= 0) {
            _currentPosition = Duration(milliseconds: (posSecs * 1000).toInt());
          }
        }
      case 'sub-text':
        final List<String> captions;
        if (prop.ref.data != ffi.nullptr) {
          final strPtr = prop.ref.data.cast<ffi.Pointer<Utf8>>().value;
          final text = strPtr != ffi.nullptr ? strPtr.toDartString() : '';
          final trimmed = text.trim();
          captions = trimmed.isNotEmpty
              ? trimmed.split('\n').map((s) => s.trim()).toList()
              : const <String>[];
        } else {
          captions = const <String>[];
        }
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.captionUpdate,
            captions: captions,
            key: _currentKey,
          ),
        );
    }
  }

  void _notifyDimensionUpdate() {
    if (_width > 0 && _height > 0) {
      _eventController.add(
        VideoEvent(
          eventType: VideoEventType.changedSize,
          key: _currentKey,
          duration: _duration,
          size: Size(_width, _height),
        ),
      );
    }
  }

  int _getDurationMs() {
    if (_isDisposed) return 0;
    final ptr = calloc<ffi.Double>();
    final namePtr = 'duration'.toNativeUtf8();
    try {
      final res = _bindings.mpvGetProperty(
        handle,
        namePtr,
        MpvFormat.doubleFormat,
        ptr.cast(),
      );
      if (res >= 0) {
        return (ptr.value * 1000).toInt();
      }
      return 0;
    } finally {
      calloc.free(ptr);
      calloc.free(namePtr);
    }
  }

  int _getPositionMs() {
    if (_isDisposed) return 0;
    final ptr = calloc<ffi.Double>();
    final namePtr = 'time-pos'.toNativeUtf8();
    try {
      final res = _bindings.mpvGetProperty(
        handle,
        namePtr,
        MpvFormat.doubleFormat,
        ptr.cast(),
      );
      if (res >= 0) {
        return (ptr.value * 1000).toInt();
      }
      return 0;
    } finally {
      calloc.free(ptr);
      calloc.free(namePtr);
    }
  }

  int _getIntProperty(String name) {
    if (_isDisposed) return 0;
    final ptr = calloc<ffi.Int64>();
    final namePtr = name.toNativeUtf8();
    try {
      final res = _bindings.mpvGetProperty(
        handle,
        namePtr,
        MpvFormat.int64,
        ptr.cast(),
      );
      if (res >= 0) {
        return ptr.value;
      }
      return 0;
    } finally {
      calloc.free(ptr);
      calloc.free(namePtr);
    }
  }

  String? _getStringProperty(String name) {
    if (_isDisposed) return null;
    final namePtr = name.toNativeUtf8();
    try {
      final resPtr = _bindings.mpvGetPropertyString(handle, namePtr);
      if (resPtr != ffi.nullptr) {
        final str = resPtr.toDartString();
        _bindings.mpvFree(resPtr.cast());
        return str;
      }
      return null;
    } finally {
      calloc.free(namePtr);
    }
  }

  static String? _resolveFlutterAssetPath(String asset) {
    try {
      final exeDir = path.dirname(Platform.resolvedExecutable);
      final assetPath = path.join(exeDir, 'data', 'flutter_assets', asset);
      if (File(assetPath).existsSync()) {
        return assetPath;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _log(message: 'dispose()');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _eventController.close();
  }

  @override
  Future<void> setDataSource(DataSource dataSource) async {
    if (_isDisposed) return;
    _currentPosition = Duration.zero;
    _currentKey = dataSource.key;
    _completedEmitted = false;
    _duration = Duration.zero;
    _overriddenDuration = dataSource.overriddenDuration;
    _width = 0;
    _height = 0;

    // Configure headers: always set to avoid leaking previous headers.
    // Quote any values containing commas so mpv does not split them into multiple headers.
    if (dataSource.headers != null && dataSource.headers!.isNotEmpty) {
      final headerStrings = dataSource.headers!.entries
          .map((e) {
            var v = e.value ?? '';
            if (v.contains(',')) {
              v = '"$v"';
            }
            return '${e.key}: $v';
          })
          .join(',');
      _setPropertyString(name: 'http-header-fields', value: headerStrings);
    } else {
      _setPropertyString(name: 'http-header-fields', value: '');
    }

    final clearKey = dataSource.drmConfiguration?.clearKey;
    if (clearKey != null && clearKey.isNotEmpty) {
      _log(message: 'Configuring ClearKey DRM for stream');
      _setPropertyString(
        name: 'demuxer-lavf-o',
        value: 'decryption_key=$clearKey',
      );
    } else {
      _setPropertyString(name: 'demuxer-lavf-o', value: '');
      if (dataSource.drmConfiguration != null) {
        _log(
          message: 'DRM configuration is not supported on Windows (mpv)',
          levelIndex: 2,
        );
      }
    }

    // Configure caching parameters: reset to default if caching is not enabled
    if (dataSource.cacheConfiguration?.useCache == true) {
      final maxBytes = dataSource.cacheConfiguration?.maxCacheSize ?? 0;
      if (maxBytes > 0) {
        _setPropertyString(
          name: 'demuxer-max-bytes',
          value: maxBytes.toString(),
        );
      }
    } else {
      _setPropertyString(name: 'demuxer-max-bytes', value: '150MiB');
    }

    var url = dataSource.uri ?? dataSource.asset ?? '';
    if (dataSource.sourceType == DataSourceType.asset ||
        dataSource.asset != null) {
      final resolved = _resolveFlutterAssetPath(url);
      if (resolved != null) {
        url = resolved;
      }
    }
    if (url.startsWith('file://')) {
      final stripped = url.substring(7);
      if (stripped.length >= 3 && stripped[0] == '/' && stripped[2] == ':') {
        url = stripped.substring(1);
      } else {
        url = stripped;
      }
    }
    _log(message: 'setDataSource: $url');
    final code = _command(['loadfile', url]);
    if (code < 0) {
      final errorStr = _bindings.errorString(code);
      _log(
        message: 'Failed to execute loadfile: $errorStr (code: $code)',
        levelIndex: 3,
      );
      throw PlatformException(
        code: 'MPV_ERROR',
        message: 'Failed to load video: $errorStr (code: $code)',
      );
    }
  }

  @override
  Future<void> play() async {
    if (_isDisposed) return;
    _log(message: 'play()');
    _setPropertyFlag(name: 'pause', value: false);
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) return;
    _log(message: 'pause()');
    _setPropertyFlag(name: 'pause', value: true);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    _log(message: 'setVolume: $volume', levelIndex: 0);
    _setPropertyDouble(
      name: 'volume',
      value: (volume * 100.0).clamp(0.0, 100.0),
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    _log(message: 'setSpeed: $speed', levelIndex: 0);
    _setPropertyDouble(name: 'speed', value: speed.clamp(0.01, 4.0));
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;
    _log(message: 'seekTo: ${position.inMilliseconds}');
    _currentPosition = position;
    _completedEmitted = false;
    final seconds = position.inMilliseconds / 1000.0;
    final code = _command(['seek', seconds.toString(), 'absolute+exact']);
    if (code < 0) {
      final errorStr = _bindings.errorString(code);
      _log(
        message: 'Failed to execute seek: $errorStr (code: $code)',
        levelIndex: 2,
      );
      throw PlatformException(
        code: 'MPV_ERROR',
        message: 'Failed to seek: $errorStr (code: $code)',
      );
    }
  }

  @override
  Future<Duration> getPosition() async {
    if (_isDisposed) return _currentPosition;
    final ms = _getPositionMs();
    if (ms > 0) {
      _currentPosition = Duration(milliseconds: ms);
    }
    return _currentPosition;
  }

  @override
  Future<void> setLooping({required bool looping}) async {
    if (_isDisposed) return;
    _log(message: 'setLooping: $looping');
    _setPropertyString(name: 'loop-file', value: looping ? 'inf' : 'no');
  }

  @override
  Future<void> setTrackParameters({
    required int width,
    required int height,
    required int bitrate,
  }) async {
    if (_isDisposed) return;
    _log(
      message:
          'setTrackParameters: width=$width, height=$height, bitrate=$bitrate',
      levelIndex: 0,
    );
    if (width == 0 && height == 0 && bitrate == 0) {
      _setPropertyString(name: 'vid', value: 'auto');
      _setPropertyString(name: 'hls-bitrate', value: 'max');
      return;
    }

    if (bitrate > 0) {
      _setPropertyString(name: 'hls-bitrate', value: '$bitrate');
    }

    final count = _getIntProperty('track-list/count');
    int? matchedTrackId;
    for (var i = 0; i < count; i++) {
      final type = _getStringProperty('track-list/$i/type');
      if (type == 'video') {
        final trackWidth = _getIntProperty('track-list/$i/demux-w');
        final trackHeight = _getIntProperty('track-list/$i/demux-h');
        final trackBitrate = _getIntProperty('track-list/$i/demux-bitrate');
        final id = _getIntProperty('track-list/$i/id');

        final matchesSize =
            width > 0 &&
            height > 0 &&
            trackWidth == width &&
            trackHeight == height;
        final matchesBitrate =
            bitrate > 0 &&
            (trackBitrate == bitrate || (trackBitrate - bitrate).abs() < 50000);

        if (matchesSize || matchesBitrate) {
          matchedTrackId = id;
          break;
        }
      }
    }

    if (matchedTrackId != null && matchedTrackId > 0) {
      _setPropertyString(name: 'vid', value: '$matchedTrackId');
    }
  }

  int? _resolveTrackId({
    required String trackType,
    required String name,
    required int index,
  }) {
    final count = _getIntProperty('track-list/count');
    var typeIndex = 0;
    for (var i = 0; i < count; i++) {
      final type = _getStringProperty('track-list/$i/type');
      if (type == trackType) {
        final id = _getIntProperty('track-list/$i/id');
        final title = _getStringProperty('track-list/$i/title') ?? '';
        final lang = _getStringProperty('track-list/$i/lang') ?? '';
        final matchesIndex = typeIndex == index;
        final matchesName = name.isNotEmpty && (title == name || lang == name);

        if (matchesIndex || matchesName) {
          return id > 0 ? id : null;
        }
        typeIndex++;
      }
    }
    return null;
  }

  @override
  Future<void> setAudioTrack({required String name, required int index}) async {
    if (_isDisposed) return;
    _log(message: 'setAudioTrack: name=$name, index=$index', levelIndex: 0);
    final disable = index < 0 || name.isEmpty;
    if (disable) {
      _setPropertyString(name: 'aid', value: 'no');
      return;
    }
    final matchedId = _resolveTrackId(
      trackType: 'audio',
      name: name,
      index: index,
    );
    _setPropertyString(
      name: 'aid',
      value: matchedId != null ? '$matchedId' : '${index + 1}',
    );
  }

  @override
  Future<void> setTextTrack({required String name, required int index}) async {
    if (_isDisposed) return;
    _log(message: 'setTextTrack: name=$name, index=$index', levelIndex: 0);
    final disable = index < 0 || name.isEmpty;
    if (disable) {
      _setPropertyString(name: 'sid', value: 'no');
      _eventController.add(
        VideoEvent(
          eventType: VideoEventType.captionUpdate,
          captions: const <String>[],
          key: _currentKey,
        ),
      );
      return;
    }
    final matchedId = _resolveTrackId(
      trackType: 'sub',
      name: name,
      index: index,
    );
    _setPropertyString(
      name: 'sid',
      value: matchedId != null ? '$matchedId' : '${index + 1}',
    );
  }

  int _command(List<String> args) {
    if (_isDisposed) return -1;
    final pointers = calloc<ffi.Pointer<Utf8>>(args.length + 1);
    for (var i = 0; i < args.length; i++) {
      pointers[i] = args[i].toNativeUtf8();
    }
    pointers[args.length] = ffi.nullptr;

    try {
      return _bindings.mpvCommand(handle, pointers);
    } finally {
      for (var i = 0; i < args.length; i++) {
        calloc.free(pointers[i]);
      }
      calloc.free(pointers);
    }
  }

  void _setPropertyString({required String name, required String value}) {
    if (_isDisposed) return;
    final namePtr = name.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    try {
      final res = _bindings.mpvSetPropertyString(handle, namePtr, valuePtr);
      if (res < 0) {
        _log(
          message:
              'Failed to set property string "$name": ${_bindings.errorString(res)} (code: $res)',
          levelIndex: 2,
        );
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(valuePtr);
    }
  }

  void _setPropertyFlag({required String name, required bool value}) {
    if (_isDisposed) return;
    final namePtr = name.toNativeUtf8();
    final flagPtr = calloc<ffi.Int32>()..value = value ? 1 : 0;
    try {
      final res = _bindings.mpvSetProperty(
        handle,
        namePtr,
        MpvFormat.flag,
        flagPtr.cast(),
      );
      if (res < 0) {
        _log(
          message:
              'Failed to set property flag "$name": ${_bindings.errorString(res)} (code: $res)',
          levelIndex: 2,
        );
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(flagPtr);
    }
  }

  void _setPropertyDouble({required String name, required double value}) {
    if (_isDisposed) return;
    final namePtr = name.toNativeUtf8();
    final doublePtr = calloc<ffi.Double>()..value = value;
    try {
      final res = _bindings.mpvSetProperty(
        handle,
        namePtr,
        MpvFormat.doubleFormat,
        doublePtr.cast(),
      );
      if (res < 0) {
        _log(
          message:
              'Failed to set property double "$name": ${_bindings.errorString(res)} (code: $res)',
          levelIndex: 2,
        );
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(doublePtr);
    }
  }
}
