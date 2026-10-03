import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_windows/src/mpv/mpv_ffi.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

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
}

class MpvPlayer implements BetterPlayerWindowsPlayer {
  MpvPlayer({
    required this.textureId,
    required this.handle,
    MpvBindings? bindings,
    this.onLog,
  }) : _bindings = bindings ?? MpvBindings.instance! {
    _initEventStream();
  }

  @override
  final int textureId;
  final ffi.Pointer<MpvHandle> handle;
  final MpvBindings _bindings;
  final void Function({required String message, required int levelIndex})?
  onLog;

  void _log(String message, {int levelIndex = 1}) {
    onLog?.call(message: message, levelIndex: levelIndex);
  }

  final StreamController<VideoEvent> _eventController =
      StreamController<VideoEvent>.broadcast();
  bool _isDisposed = false;
  bool _completedEmitted = false;
  Timer? _pollingTimer;

  Duration _duration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  double _width = 0;
  double _height = 0;
  String? _currentKey;

  @override
  Stream<VideoEvent> get events => _eventController.stream;

  void _initEventStream() {
    // Observe core playback properties
    _observeProperty('pause', MpvFormat.flag);
    _observeProperty('time-pos', MpvFormat.doubleFormat);
    _observeProperty('duration', MpvFormat.doubleFormat);
    _observeProperty('eof-reached', MpvFormat.flag);
    _observeProperty('seeking', MpvFormat.flag);
    _observeProperty('paused-for-cache', MpvFormat.flag);
    _observeProperty('width', MpvFormat.int64);
    _observeProperty('height', MpvFormat.int64);

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

  void _observeProperty(String name, int format) {
    final namePtr = name.toNativeUtf8();
    try {
      _bindings.mpvObserveProperty(handle, 0, namePtr, format);
    } finally {
      calloc.free(namePtr);
    }
  }

  void _pollEvents() {
    if (_isDisposed) return;

    while (true) {
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
            _log('[$prefix] $text', levelIndex: levelIndex);
          }
        }
      case MpvEventId.fileLoaded:
        _onFileLoaded();
      case MpvEventId.propertyChange:
        _onPropertyChange(event.ref.data.cast<MpvEventProperty>());
      case MpvEventId.seek:
      case MpvEventId.playbackRestart:
        _completedEmitted = false;
        final posMs = _getPositionMs();
        if (posMs > 0) {
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
          _log('PlaybackState: ENDED');
          _eventController.add(
            VideoEvent(eventType: VideoEventType.completed, key: _currentKey),
          );
        }
    }
  }

  void _onFileLoaded() {
    _duration = Duration(milliseconds: _getDurationMs());
    _width = _getIntProperty('width').toDouble();
    _height = _getIntProperty('height').toDouble();

    _log(
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
            isBuffering ? 'PlaybackState: BUFFERING' : 'PlaybackState: READY',
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
      case 'eof-reached':
        if (prop.ref.data != ffi.nullptr) {
          final isEof = prop.ref.data.cast<ffi.Int32>().value != 0;
          if (isEof && !_completedEmitted) {
            _completedEmitted = true;
            _log('PlaybackState: ENDED');
            _eventController.add(
              VideoEvent(
                eventType: VideoEventType.completed,
                key: _currentKey,
              ),
            );
          }
        }
      case 'width':
        if (prop.ref.data != ffi.nullptr) {
          final newWidth = prop.ref.data.cast<ffi.Int64>().value.toDouble();
          if (newWidth > 0 && newWidth != _width) {
            _width = newWidth;
            _notifyDimensionUpdate();
          }
        }
      case 'height':
        if (prop.ref.data != ffi.nullptr) {
          final newHeight = prop.ref.data.cast<ffi.Int64>().value.toDouble();
          if (newHeight > 0 && newHeight != _height) {
            _height = newHeight;
            _notifyDimensionUpdate();
          }
        }
      case 'duration':
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

  @override
  Future<void> dispose() async {
    _log('dispose()');
    _isDisposed = true;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _eventController.close();
  }

  @override
  Future<void> setDataSource(DataSource dataSource) async {
    _currentPosition = Duration.zero;
    _currentKey = dataSource.key;
    _completedEmitted = false;
    _duration = Duration.zero;
    _width = 0;
    _height = 0;

    // Configure headers: always set to avoid leaking previous headers
    if (dataSource.headers != null && dataSource.headers!.isNotEmpty) {
      final headerStrings = dataSource.headers!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(',');
      _setPropertyString('http-header-fields', headerStrings);
    } else {
      _setPropertyString('http-header-fields', '');
    }

    // Configure caching parameters: reset to default if caching is not enabled
    if (dataSource.cacheConfiguration?.useCache == true) {
      final maxBytes = dataSource.cacheConfiguration?.maxCacheSize ?? 0;
      if (maxBytes > 0) {
        _setPropertyString('demuxer-max-bytes', maxBytes.toString());
      }
    } else {
      _setPropertyString('demuxer-max-bytes', '150MiB');
    }

    final url = dataSource.uri ?? dataSource.asset ?? '';
    _log('setDataSource: $url');
    final code = _command(['loadfile', url]);
    if (code < 0) {
      final errorStr = _bindings.errorString(code);
      _log(
        'Failed to execute loadfile: $errorStr (code: $code)',
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
    _log('play()');
    _setPropertyFlag('pause', false);
  }

  @override
  Future<void> pause() async {
    _log('pause()');
    _setPropertyFlag('pause', true);
  }

  @override
  Future<void> setVolume(double volume) async {
    _log('setVolume: $volume', levelIndex: 0);
    _setPropertyDouble('volume', (volume * 100.0).clamp(0.0, 100.0));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _log('setSpeed: $speed', levelIndex: 0);
    _setPropertyDouble('speed', speed.clamp(0.01, 4.0));
  }

  @override
  Future<void> seekTo(Duration position) async {
    _log('seekTo: ${position.inMilliseconds}');
    _currentPosition = position;
    _completedEmitted = false;
    final seconds = position.inMilliseconds / 1000.0;
    final code = _command(['seek', seconds.toString(), 'absolute+exact']);
    if (code < 0) {
      final errorStr = _bindings.errorString(code);
      _log('Failed to execute seek: $errorStr (code: $code)', levelIndex: 2);
      throw PlatformException(
        code: 'MPV_ERROR',
        message: 'Failed to seek: $errorStr (code: $code)',
      );
    }
  }

  @override
  Future<Duration> getPosition() async {
    final ms = _getPositionMs();
    if (ms > 0) {
      _currentPosition = Duration(milliseconds: ms);
    }
    return _currentPosition;
  }

  @override
  Future<void> setLooping({required bool looping}) async {
    _log('setLooping: $looping');
    _setPropertyString('loop-file', looping ? 'inf' : 'no');
  }

  @override
  Future<void> setTrackParameters({
    required int width,
    required int height,
    required int bitrate,
  }) async {
    _log(
      'setTrackParameters: width=$width, height=$height, bitrate=$bitrate '
      '(track selection not supported on Windows yet)',
      levelIndex: 0,
    );
  }

  @override
  Future<void> setAudioTrack({required String name, required int index}) async {
    _log('setAudioTrack: name=$name, index=$index', levelIndex: 0);
    _setPropertyString('aid', '$index');
  }

  int _command(List<String> args) {
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

  void _setPropertyString(String name, String value) {
    final namePtr = name.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    try {
      final res = _bindings.mpvSetPropertyString(handle, namePtr, valuePtr);
      if (res < 0) {
        _log(
          'Failed to set property string "$name": ${_bindings.errorString(res)} (code: $res)',
          levelIndex: 2,
        );
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(valuePtr);
    }
  }

  void _setPropertyFlag(String name, bool value) {
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
          'Failed to set property flag "$name": ${_bindings.errorString(res)} (code: $res)',
          levelIndex: 2,
        );
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(flagPtr);
    }
  }

  void _setPropertyDouble(String name, double value) {
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
