import 'package:flutter/material.dart';

class BetterPlayerPlayNextVideoConfiguration {
  final int showBeforeEndMillis;
  final int autoSwitchToNextMillis;
  final Widget Function(double progress) playNextBuilder;

  BetterPlayerPlayNextVideoConfiguration({
    required this.playNextBuilder,
    required this.autoSwitchToNextMillis,
    required this.showBeforeEndMillis,
  });
}
