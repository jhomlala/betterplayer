import 'dart:ui';

import 'package:flutter/material.dart';

class BetterPlayerOverlayControlsConfiguration {
  ///Flag used to enable/disable play/pause button in overlay control
  final bool enablePlayPause;

  ///Flag used to enable/disable fast forward on double tap
  final bool enableSkipForwardOnDoubleTap;

  ///Flag used to enable/disable fast rewind on double tap
  final bool enableSkipBackOnDoubleTap;

  /// Fast forward area width
  final double skipForwardAreaWidth;

  /// Fast rewind area width
  final double skipBackAreaWidth;

  ///Time duration for fast forward and rewind
  final Duration skipTime;

  ///Icon for play in overlay control
  final IconData playIcon;

  ///Icon for pause in overlay control
  final IconData pauseIcon;

  ///Icon for replay in overlay control
  final IconData replayIcon;

  /// Background color of play, pause and replay action buttons
  final Color actionButtonBgColor;

  /// Border radius of action button background color
  final double actionButtonRadius;

  /// Padding of action button background color
  final double actionButtonPadding;

  /// Size of action buttons
  final double actionButtonIconSize;

  const BetterPlayerOverlayControlsConfiguration({
    this.enablePlayPause = true,
    this.enableSkipForwardOnDoubleTap = true,
    this.enableSkipBackOnDoubleTap = true,
    this.skipTime = const Duration(seconds: 10),
    this.playIcon = Icons.play_arrow,
    this.pauseIcon = Icons.pause,
    this.replayIcon = Icons.replay,
    this.skipForwardAreaWidth = 70,
    this.skipBackAreaWidth = 70,
    this.actionButtonBgColor = const Color.fromRGBO(0, 0, 0, 0.10),
    this.actionButtonRadius = 48,
    this.actionButtonPadding = 12,
    this.actionButtonIconSize = 32,
  });
}
