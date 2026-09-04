import 'package:flutter/widgets.dart';

/// Tracks the visual state and UI configurations of the Better Player.
@immutable
class PlayerViewState {
  /// Flag indicating whether the player is currently taking up the entire screen.
  final bool isFullScreen;

  /// Flag indicating whether the player surface is currently visible on the screen.
  final bool isPlayerVisible;

  /// Flag indicating whether the controls overlay should remain persistently visible,
  /// ignoring standard auto-hide timers.
  final bool controlsAlwaysVisible;

  /// Flag indicating whether the interactive UI controls (play/pause, timeline) are enabled.
  final bool controlsEnabled;

  /// Flag indicating whether the player was recently placed into Picture-in-Picture mode.
  final bool wasInPipMode;

  /// Stores the full screen state prior to entering Picture-in-Picture mode.
  final bool wasInFullScreenBeforePiP;

  /// Stores the controls enablement state prior to entering Picture-in-Picture mode.
  final bool wasControlsEnabledBeforePiP;

  /// A specific aspect ratio that overrides the configuration's aspect ratio.
  final double? overriddenAspectRatio;

  /// A specific Box Fit mode that overrides the configuration's fit.
  final BoxFit? overriddenFit;

  /// A globally unique key representing the BetterPlayer widget instance in the widget tree.
  final GlobalKey? betterPlayerGlobalKey;

  const PlayerViewState({
    this.isFullScreen = false,
    this.isPlayerVisible = true,
    this.controlsAlwaysVisible = false,
    this.controlsEnabled = true,
    this.wasInPipMode = false,
    this.wasInFullScreenBeforePiP = false,
    this.wasControlsEnabledBeforePiP = false,
    this.overriddenAspectRatio,
    this.overriddenFit,
    this.betterPlayerGlobalKey,
  });

  PlayerViewState copyWith({
    bool? isFullScreen,
    bool? isPlayerVisible,
    bool? controlsAlwaysVisible,
    bool? controlsEnabled,
    bool? wasInPipMode,
    bool? wasInFullScreenBeforePiP,
    bool? wasControlsEnabledBeforePiP,
    double? overriddenAspectRatio,
    BoxFit? overriddenFit,
    GlobalKey? betterPlayerGlobalKey,
  }) {
    return PlayerViewState(
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isPlayerVisible: isPlayerVisible ?? this.isPlayerVisible,
      controlsAlwaysVisible:
          controlsAlwaysVisible ?? this.controlsAlwaysVisible,
      controlsEnabled: controlsEnabled ?? this.controlsEnabled,
      wasInPipMode: wasInPipMode ?? this.wasInPipMode,
      wasInFullScreenBeforePiP:
          wasInFullScreenBeforePiP ?? this.wasInFullScreenBeforePiP,
      wasControlsEnabledBeforePiP:
          wasControlsEnabledBeforePiP ?? this.wasControlsEnabledBeforePiP,
      overriddenAspectRatio:
          overriddenAspectRatio ?? this.overriddenAspectRatio,
      overriddenFit: overriddenFit ?? this.overriddenFit,
      betterPlayerGlobalKey:
          betterPlayerGlobalKey ?? this.betterPlayerGlobalKey,
    );
  }
}
