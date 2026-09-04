import 'package:flutter/widgets.dart';

/// Tracks the visual state and UI configurations of the Better Player.
class PlayerViewState {
  /// Flag indicating whether the player is currently taking up the entire screen.
  bool isFullScreen = false;

  /// Flag indicating whether the player surface is currently visible on the screen.
  bool isPlayerVisible = true;

  /// Flag indicating whether the controls overlay should remain persistently visible,
  /// ignoring standard auto-hide timers.
  bool controlsAlwaysVisible = false;

  /// Flag indicating whether the interactive UI controls (play/pause, timeline) are enabled.
  bool controlsEnabled = true;

  /// Flag indicating whether the player was recently placed into Picture-in-Picture mode.
  bool wasInPipMode = false;

  /// Stores the full screen state prior to entering Picture-in-Picture mode.
  bool wasInFullScreenBeforePiP = false;

  /// Stores the controls enablement state prior to entering Picture-in-Picture mode.
  bool wasControlsEnabledBeforePiP = false;

  /// A specific aspect ratio that overrides the configuration's aspect ratio.
  double? overriddenAspectRatio;

  /// A specific Box Fit mode that overrides the configuration's fit.
  BoxFit? overriddenFit;

  /// A globally unique key representing the BetterPlayer widget instance in the widget tree.
  GlobalKey? betterPlayerGlobalKey;
}
