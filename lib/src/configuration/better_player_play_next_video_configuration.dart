import 'package:flutter/material.dart';

class BetterPlayerPlayNextVideoConfiguration {
  final int showBeforeEndMillis;
  final Widget Function(double progress) playNextBuilder;

  BetterPlayerPlayNextVideoConfiguration({
    required this.playNextBuilder,
    required this.showBeforeEndMillis,
  });
}
