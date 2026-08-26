import 'dart:ui';

import 'package:better_player_platform_interface/src/models/duration_range.dart';

/// The duration, current position, buffering state, error state and settings
/// of a video player controller.
class VideoPlayerValue {
  /// Constructs a video with the given values. Only [duration] is required. The
  /// rest will initialize with default values when unset.
  VideoPlayerValue({
    required this.duration,
    this.size,
    this.position = const Duration(),
    this.absolutePosition,
    this.buffered = const <DurationRange>[],
    this.isPlaying = false,
    this.isLooping = false,
    this.isBuffering = false,
    this.volume = 1.0,
    this.speed = 1.0,
    this.errorDescription,
    this.isPip = false,
  });

  /// Returns an instance with a `null` [Duration].
  VideoPlayerValue.uninitialized() : this(duration: null);

  /// Returns an instance with a `null` [Duration] and the given
  /// [errorDescription].
  VideoPlayerValue.erroneous(String errorDescription)
    : this(duration: null, errorDescription: errorDescription);

  /// The total duration of the video.
  ///
  /// Is null when [initialized] is false.
  final Duration? duration;

  /// The current playback position.
  final Duration position;

  /// The current absolute playback position.
  ///
  /// Is null when is not available.
  final DateTime? absolutePosition;

  /// The currently buffered ranges.
  final List<DurationRange> buffered;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  /// True if the video is looping.
  final bool isLooping;

  /// True if the video is currently buffering.
  final bool isBuffering;

  /// The current volume of the playback.
  final double volume;

  /// The current speed of the playback
  final double speed;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is [null].
  final String? errorDescription;

  /// The [size] of the currently loaded video.
  ///
  /// Is null when [initialized] is false.
  final Size? size;

  ///Is in Picture in Picture Mode
  final bool isPip;

  /// Indicates whether or not the video has been loaded and is ready to play.
  bool get initialized => duration != null;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => errorDescription != null;

  /// Returns [size.width] / [size.height] when size is non-null, or `1.0.` when
  /// size is null or the aspect ratio would be less than or equal to 0.0.
  double get aspectRatio {
    if (size == null) {
      return 1;
    }
    final aspectRatio = size!.width / size!.height;
    if (aspectRatio <= 0) {
      return 1;
    }
    return aspectRatio;
  }

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWith].
  VideoPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    DateTime? absolutePosition,
    List<DurationRange>? buffered,
    bool? isPlaying,
    bool? isLooping,
    bool? isBuffering,
    double? volume,
    String? errorDescription,
    double? speed,
    bool? isPip,
  }) {
    return VideoPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      absolutePosition: absolutePosition ?? this.absolutePosition,
      buffered: buffered ?? this.buffered,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      errorDescription: errorDescription ?? this.errorDescription,
      isPip: isPip ?? this.isPip,
    );
  }

  @override
  String toString() {
    // ignore: no_runtimetype_tostring
    return '$runtimeType('
        'duration: $duration, '
        'size: $size, '
        'position: $position, '
        'absolutePosition: $absolutePosition, '
        'buffered: [${buffered.join(', ')}], '
        'isPlaying: $isPlaying, '
        'isLooping: $isLooping, '
        'isBuffering: $isBuffering, '
        'volume: $volume, '
        'errorDescription: $errorDescription)';
  }
}
