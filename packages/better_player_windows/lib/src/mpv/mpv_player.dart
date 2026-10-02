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
  }) : _bindings = bindings ?? MpvBindings.instance! {
    _initEventStream();
  }

  @override
  final int textureId;
  final ffi.Pointer<MpvHandle> handle;
  final MpvBindings _bindings;

  final StreamController<VideoEvent> _eventController =
      StreamController<VideoEvent>.broadcast();
  bool _isDisposed = false;
  Timer? _pollingTimer;

  Duration _duration = Duration.zero;
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
      case MpvEventId.fileLoaded:
        _onFileLoaded();
      case MpvEventId.propertyChange:
        _onPropertyChange(event.ref.data.cast<MpvEventProperty>());
      case MpvEventId.seek:
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.seek,
            key: _currentKey,
            position: Duration(milliseconds: _getPositionMs()),
          ),
        );
      case MpvEventId.endFile:
        _eventController.add(
          VideoEvent(eventType: VideoEventType.completed, key: _currentKey),
        );
    }
  }

  void _onFileLoaded() {
    _duration = Duration(milliseconds: _getDurationMs());
    _width = _getIntProperty('width').toDouble();
    _height = _getIntProperty('height').toDouble();

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
          if (isEof) {
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
          _width = prop.ref.data.cast<ffi.Int64>().value.toDouble();
          _notifyDimensionUpdate();
        }
      case 'height':
        if (prop.ref.data != ffi.nullptr) {
          _height = prop.ref.data.cast<ffi.Int64>().value.toDouble();
          _notifyDimensionUpdate();
        }
      case 'duration':
        if (prop.ref.data != ffi.nullptr) {
          final durSecs = prop.ref.data.cast<ffi.Double>().value;
          if (durSecs > 0) {
            _duration = Duration(milliseconds: (durSecs * 1000).toInt());
          }
        }
    }
  }

  void _notifyDimensionUpdate() {
    if (_width > 0 && _height > 0) {
      _eventController.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
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
    _isDisposed = true;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _eventController.close();
  }

  @override
  Future<void> setDataSource(DataSource dataSource) async {
    _currentKey = dataSource.key;

    // Configure headers if present
    if (dataSource.headers != null && dataSource.headers!.isNotEmpty) {
      final headerStrings = dataSource.headers!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(',');
      _setPropertyString('http-header-fields', headerStrings);
    }

    // Configure caching parameters
    if (dataSource.cacheConfiguration?.useCache == true) {
      final maxBytes = dataSource.cacheConfiguration?.maxCacheSize ?? 0;
      if (maxBytes > 0) {
        _setPropertyString('demuxer-max-bytes', maxBytes.toString());
      }
    }

    final url = dataSource.uri ?? dataSource.asset ?? '';
    _command(['loadfile', url]);
  }

  @override
  Future<void> play() async {
    _setPropertyFlag('pause', false);
  }

  @override
  Future<void> pause() async {
    _setPropertyFlag('pause', true);
  }

  @override
  Future<void> setVolume(double volume) async {
    _setPropertyDouble('volume', (volume * 100.0).clamp(0.0, 100.0));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _setPropertyDouble('speed', speed.clamp(0.0, 4.0));
  }

  @override
  Future<void> seekTo(Duration position) async {
    final seconds = position.inMilliseconds / 1000.0;
    _command(['seek', seconds.toString(), 'absolute']);
  }

  @override
  Future<Duration> getPosition() async {
    return Duration(milliseconds: _getPositionMs());
  }

  @override
  Future<void> setLooping({required bool looping}) async {
    _setPropertyString('loop-file', looping ? 'inf' : 'no');
  }

  @override
  Future<void> setTrackParameters({
    required int width,
    required int height,
    required int bitrate,
  }) async {
    if (width > 0 && height > 0) {
      _setPropertyString('video-aspect-override', '${width / height}');
    }
  }

  @override
  Future<void> setAudioTrack({required String name, required int index}) async {
    _setPropertyString('aid', '$index');
  }

  void _command(List<String> args) {
    final pointers = calloc<ffi.Pointer<Utf8>>(args.length + 1);
    for (var i = 0; i < args.length; i++) {
      pointers[i] = args[i].toNativeUtf8();
    }
    pointers[args.length] = ffi.nullptr;

    try {
      _bindings.mpvCommand(handle, pointers);
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
      _bindings.mpvSetPropertyString(handle, namePtr, valuePtr);
    } finally {
      calloc.free(namePtr);
      calloc.free(valuePtr);
    }
  }

  void _setPropertyFlag(String name, bool value) {
    final namePtr = name.toNativeUtf8();
    final flagPtr = calloc<ffi.Int32>()..value = value ? 1 : 0;
    try {
      _bindings.mpvSetProperty(
        handle,
        namePtr,
        MpvFormat.flag,
        flagPtr.cast(),
      );
    } finally {
      calloc.free(namePtr);
      calloc.free(flagPtr);
    }
  }

  void _setPropertyDouble(String name, double value) {
    final namePtr = name.toNativeUtf8();
    final doublePtr = calloc<ffi.Double>()..value = value;
    try {
      _bindings.mpvSetProperty(
        handle,
        namePtr,
        MpvFormat.doubleFormat,
        doublePtr.cast(),
      );
    } finally {
      calloc.free(namePtr);
      calloc.free(doublePtr);
    }
  }
}
