import 'dart:async';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_tizen/src/player_tizen.dart';
import 'package:flutter/services.dart';

/// Implementation of [PlayerTizen] using method and event channels.
class PlayerTizenController implements PlayerTizen {
  /// Creates a controller for a Tizen media player instance.
  PlayerTizenController({
    required this.textureId,
    MethodChannel? channel,
    EventChannel? eventChannel,
    Stream<dynamic>? rawEventStream,
  }) : _channel = channel ?? const MethodChannel('better_player_tizen'),
       _eventChannel =
           eventChannel ??
           EventChannel('better_player_tizen/video_events_$textureId') {
    final stream = rawEventStream ?? _eventChannel.receiveBroadcastStream();
    _eventSubscription = stream.listen(_handleEvent, onError: _handleError);
  }

  @override
  final int textureId;

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  final StreamController<VideoEvent> _eventController =
      StreamController<VideoEvent>.broadcast();

  StreamSubscription<dynamic>? _eventSubscription;
  bool _isDisposed = false;

  @override
  Stream<VideoEvent> get events => _eventController.stream;

  void _handleEvent(dynamic rawEvent) {
    if (_isDisposed ||
        _eventController.isClosed ||
        rawEvent is! Map<dynamic, dynamic>) {
      return;
    }

    final map = rawEvent.cast<String, dynamic>();
    final eventType = map['event'] as String?;

    switch (eventType) {
      case 'initialized':
        final rawDurationMs = map['duration'] as int? ?? 0;
        final durationMs = rawDurationMs > 0 ? rawDurationMs : 0;
        final width = (map['width'] as num?)?.toDouble() ?? 0.0;
        final height = (map['height'] as num?)?.toDouble() ?? 0.0;
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            key: '$textureId',
            duration: Duration(milliseconds: durationMs),
            size: Size(width, height),
          ),
        );
      case 'completed':
        _eventController.add(
          VideoEvent(eventType: VideoEventType.completed, key: '$textureId'),
        );
      case 'bufferingStart':
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.bufferingStart,
            key: '$textureId',
          ),
        );
      case 'bufferingEnd':
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.bufferingEnd,
            key: '$textureId',
          ),
        );
      case 'bufferingUpdate':
        final rawBuffered = map['values'] as List<dynamic>? ?? <dynamic>[];
        final buffered = <DurationRange>[];
        for (final item in rawBuffered) {
          if (item is List && item.length >= 2) {
            final start = (item[0] as num).toInt();
            final end = (item[1] as num).toInt();
            buffered.add(
              DurationRange(
                Duration(milliseconds: start),
                Duration(milliseconds: end),
              ),
            );
          }
        }
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.bufferingUpdate,
            key: '$textureId',
            buffered: buffered,
          ),
        );
      case 'isPlayingStateUpdate':
        final isPlaying = map['isPlaying'] as bool? ?? false;
        _eventController.add(
          VideoEvent(
            eventType: isPlaying ? VideoEventType.play : VideoEventType.pause,
            key: '$textureId',
          ),
        );
      case 'changedSize':
        final width = (map['width'] as num?)?.toDouble() ?? 0.0;
        final height = (map['height'] as num?)?.toDouble() ?? 0.0;
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.changedSize,
            key: '$textureId',
            size: Size(width, height),
          ),
        );
      case 'seek':
        final positionMs = map['position'] as int? ?? 0;
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.seek,
            key: '$textureId',
            position: Duration(milliseconds: positionMs),
          ),
        );
      default:
        break;
    }
  }

  void _handleError(Object error) {
    if (!_isDisposed && !_eventController.isClosed) {
      _eventController.addError(error);
    }
  }

  @override
  Future<void> setDataSource(DataSource dataSource) async {
    if (_isDisposed) {
      return;
    }
    final rawUri = dataSource.uri ?? dataSource.asset;
    if (rawUri == null || rawUri.isEmpty) {
      throw PlatformException(
        code: 'INVALID_DATA_SOURCE',
        message:
            'DataSource URI or asset path cannot be null or empty on Tizen.',
      );
    }
    var effectiveUri = rawUri;
    if (dataSource.sourceType == DataSourceType.file &&
        rawUri.startsWith('file://')) {
      try {
        effectiveUri = Uri.parse(rawUri).toFilePath(windows: false);
      } on FormatException catch (_) {
        effectiveUri = rawUri.replaceFirst('file://', '');
      }
    }
    await _channel.invokeMethod<void>('setDataSource', <String, dynamic>{
      'textureId': textureId,
      'uri': effectiveUri,
      'headers': dataSource.headers,
    });
  }

  @override
  Future<void> play() async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod<void>('play', <String, dynamic>{
      'textureId': textureId,
    });
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod<void>('pause', <String, dynamic>{
      'textureId': textureId,
    });
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod<void>('setVolume', <String, dynamic>{
      'textureId': textureId,
      'volume': volume.clamp(0.0, 1.0),
    });
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod<void>('setSpeed', <String, dynamic>{
      'textureId': textureId,
      'speed': speed.clamp(0.25, 10.0),
    });
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod<void>('seekTo', <String, dynamic>{
      'textureId': textureId,
      'position': position.inMilliseconds,
    });
  }

  @override
  Future<Duration> getPosition() async {
    if (_isDisposed) {
      return Duration.zero;
    }
    final positionMs = await _channel.invokeMethod<int>(
      'getPosition',
      <String, dynamic>{'textureId': textureId},
    );
    return Duration(milliseconds: positionMs ?? 0);
  }

  @override
  Future<void> setLooping({required bool looping}) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod<void>('setLooping', <String, dynamic>{
      'textureId': textureId,
      'looping': looping,
    });
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _channel.invokeMethod<void>('dispose', <String, dynamic>{
      'textureId': textureId,
    });
    await _eventController.close();
  }
}
