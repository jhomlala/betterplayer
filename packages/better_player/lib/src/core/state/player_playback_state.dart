import 'dart:ui';

import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';

/// Tracks the low-level playback and lifecycle state of the media player.
class PlayerPlaybackState {
  /// Flag indicating whether the current data source has begun playback at least once.
  bool hasCurrentDataSourceStarted = false;

  /// Flag indicating whether the internal engine has successfully initialized the current data source.
  bool hasCurrentDataSourceInitialized = false;

  /// Tracks the lifecycle state of the Flutter application to handle backgrounding.
  AppLifecycleState appLifecycleState = AppLifecycleState.resumed;

  /// Tracks the play/pause state right before a systemic pause occurred (e.g. PIP, backgrounding).
  bool? wasPlayingBeforePause;

  /// Stores the last valid video player state exactly when a critical error occurred.
  VideoPlayerValue? videoPlayerValueOnError;

  /// Epoch timestamp of the last time a progress event was emitted.
  int lastPositionSelection = 0;
}
