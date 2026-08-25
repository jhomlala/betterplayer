import 'dart:ui';
import 'package:better_player_platform_interface/src/models/duration_range.dart';
import 'package:better_player_platform_interface/src/models/video_event_type.dart';
import 'package:flutter/foundation.dart';

/// Event emitted from the platform implementation.
class VideoEvent {
  /// Creates an instance of [VideoEvent].
  ///
  /// The [eventType] argument is required.
  ///
  /// Depending on the [eventType], the [duration], [size] and [buffered]
  /// arguments can be null.
  VideoEvent({
    required this.eventType,
    required this.key,
    this.duration,
    this.size,
    this.buffered,
    this.position,
  });

  /// The type of the event.
  final VideoEventType eventType;

  /// Data source of the video.
  ///
  /// Used to determine which video the event belongs to.
  final String? key;

  /// Duration of the video.
  ///
  /// Only used if [eventType] is [VideoEventType.initialized].
  final Duration? duration;

  /// Size of the video.
  ///
  /// Only used if [eventType] is [VideoEventType.initialized].
  final Size? size;

  /// Buffered parts of the video.
  ///
  /// Only used if [eventType] is [VideoEventType.bufferingUpdate].
  final List<DurationRange>? buffered;

  ///Seek position
  final Duration? position;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VideoEvent &&
            runtimeType == other.runtimeType &&
            key == other.key &&
            eventType == other.eventType &&
            duration == other.duration &&
            size == other.size &&
            listEquals(buffered, other.buffered);
  }

  @override
  int get hashCode =>
      eventType.hashCode ^
      duration.hashCode ^
      size.hashCode ^
      buffered.hashCode;
}
