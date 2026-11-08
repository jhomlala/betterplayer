import 'dart:async';
import 'package:flutter/widgets.dart';

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
  })  : _channel = channel ?? const MethodChannel('better_player_tizen'),
        _eventChannel = eventChannel ??
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
    if (_isDisposed || rawEvent is! Map<dynamic, dynamic>) {
      return;
    }

    final map = rawEvent.cast<String, dynamic>();
    final eventTypeString = map['event'] as String?;

    switch (eventTypeString) {
      case 'initialized':
        final durationMs = map['duration'] as int? ?? 0;
        final width = (map['width'] as num?)?.toDouble() ?? 0.0;
        final height = (map['height'] as num?)?.toDouble() ?? 0.0;
        _eventController.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: durationMs),
            size: Size(width, height),
          ),
        );
      case 'completed':
        _eventController.add(
          VideoEvent(eventType: VideoEventType.completed),
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
            buffered: buffered,
          ),
        );
      case 'isPlayingStateUpdate':
        final isPlaying = map['isPlaying'] as bool? ?? false;
        _eventController.add(
          VideoEvent(
            eventType:
                isPlaying ? VideoEventType.play : VideoEventType.pause,
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
    final uri = dataSource.url;
    await _channel.invokeMethod<void>('setDataSource', <String, dynamic>{
      'textureId': textureId,
      'uri': uri,
      'headers': dataSource.headers,
    });
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod<void>('play', <String, dynamic>{
      'textureId': textureId,
    });
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod<void>('pause', <String, dynamic>{
      'textureId': textureId,
    });
  }

  @override
  Future<void> setVolume(double volume) async {
    await _channel.invokeMethod<void>('setVolume', <String, dynamic>{
      'textureId': textureId,
      'volume': volume.clamp(0.0, 1.0),
    });
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _channel.invokeMethod<void>('setSpeed', <String, dynamic>{
      'textureId': textureId,
      'speed': speed,
    });
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _channel.invokeMethod<void>('seekTo', <String, dynamic>{
      'textureId': textureId,
      'position': position.inMilliseconds,
    });
  }

  @override
  Future<Duration> getPosition() async {
    final positionMs = await _channel.invokeMethod<int>(
      'getPosition',
      <String, dynamic>{'textureId': textureId},
    );
    return Duration(milliseconds: positionMs ?? 0);
  }

  @override
  Future<void> setLooping({required bool looping}) async {
    await _channel.invokeMethod<void>('setLooping', <String, dynamic>{
      'textureId': textureId,
      'looping': looping,
    });
  }

  @override
  Future<void> setTrackParameters({
    required int width,
    required int height,
    required int bitrate,
  }) async {
    await _channel.invokeMethod<void>('setTrackParameters', <String, dynamic>{
      'textureId': textureId,
      'width': width,
      'height': height,
      'bitrate': bitrate,
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
