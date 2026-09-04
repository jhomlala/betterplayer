
import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';

/// Tracks the low-level playback and lifecycle state of the media player.
@immutable
class PlayerPlaybackState {
  /// Flag indicating whether the current data source has begun playback at least once.
  final bool hasCurrentDataSourceStarted;

  /// Flag indicating whether the internal engine has successfully initialized the current data source.
  final bool hasCurrentDataSourceInitialized;

  /// Stores the most recent global app lifecycle state (e.g., resumed, paused)
  /// for handling background playback behavior.
  final AppLifecycleState appLifecycleState;

  /// Tracks if the video was actively playing immediately prior to an automatic pause
  /// (e.g., when the app went to the background). Used to resume playback automatically.
  final bool wasPlayingBeforePause;

  /// Snapshots the engine state at the exact moment a playback error occurred.
  /// Useful for analytics or presenting error context to the user.
  final VideoPlayerValue? videoPlayerValueOnError;

  /// Caches the system timestamp of the last time a 'progress' event was fired.
  /// Used for throttling UI updates.
  final int lastPositionSelection;

  const PlayerPlaybackState({
    this.hasCurrentDataSourceStarted = false,
    this.hasCurrentDataSourceInitialized = false,
    this.appLifecycleState = AppLifecycleState.resumed,
    this.wasPlayingBeforePause = false,
    this.videoPlayerValueOnError,
    this.lastPositionSelection = 0,
  });

  PlayerPlaybackState copyWith({
    bool? hasCurrentDataSourceStarted,
    bool? hasCurrentDataSourceInitialized,
    AppLifecycleState? appLifecycleState,
    bool? wasPlayingBeforePause,
    VideoPlayerValue? videoPlayerValueOnError,
    int? lastPositionSelection,
    bool clearVideoPlayerValueOnError = false,
  }) {
    return PlayerPlaybackState(
      hasCurrentDataSourceStarted:
          hasCurrentDataSourceStarted ?? this.hasCurrentDataSourceStarted,
      hasCurrentDataSourceInitialized:
          hasCurrentDataSourceInitialized ??
          this.hasCurrentDataSourceInitialized,
      appLifecycleState: appLifecycleState ?? this.appLifecycleState,
      wasPlayingBeforePause:
          wasPlayingBeforePause ?? this.wasPlayingBeforePause,
      videoPlayerValueOnError: clearVideoPlayerValueOnError
          ? null
          : (videoPlayerValueOnError ?? this.videoPlayerValueOnError),
      lastPositionSelection:
          lastPositionSelection ?? this.lastPositionSelection,
    );
  }
}
