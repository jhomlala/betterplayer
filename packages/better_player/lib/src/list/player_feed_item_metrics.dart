import 'package:flutter/foundation.dart';

/// Metrics captured for a feed item during viewport presentation and playback.
@immutable
class PlayerFeedItemMetrics {
  /// Creates a metrics snapshot for a feed item.
  const PlayerFeedItemMetrics({
    required this.itemId,
    required this.index,
    required this.wasPreloaded,
    this.timeToFirstFrame,
    this.rebufferCount = 0,
    this.rebufferDuration = Duration.zero,
    this.errorMessage,
  });

  /// Unique identifier of the feed item.
  final String itemId;

  /// Index of the item in the feed when metrics were recorded.
  final int index;

  /// Whether the item was already bound and preloaded in the pool.
  final bool wasPreloaded;

  /// Duration elapsed from focusing the item until the first frame rendered.
  final Duration? timeToFirstFrame;

  /// Number of rebuffering stalls experienced during playback.
  final int rebufferCount;

  /// Total duration spent waiting for rebuffering stalls.
  final Duration rebufferDuration;

  /// Error message if playback failed.
  final String? errorMessage;

  @override
  String toString() {
    return 'PlayerFeedItemMetrics('
        'itemId: $itemId, '
        'index: $index, '
        'wasPreloaded: $wasPreloaded, '
        'timeToFirstFrame: $timeToFirstFrame, '
        'rebufferCount: $rebufferCount, '
        'rebufferDuration: $rebufferDuration, '
        'errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerFeedItemMetrics &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          index == other.index &&
          wasPreloaded == other.wasPreloaded &&
          timeToFirstFrame == other.timeToFirstFrame &&
          rebufferCount == other.rebufferCount &&
          rebufferDuration == other.rebufferDuration &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
    itemId,
    index,
    wasPreloaded,
    timeToFirstFrame,
    rebufferCount,
    rebufferDuration,
    errorMessage,
  );
}
