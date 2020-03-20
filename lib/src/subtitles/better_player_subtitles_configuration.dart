import 'package:flutter/material.dart';

class BetterPlayerSubtitlesConfiguration {
  final double fontSize;
  final Color fontColor;
  final bool outlineEnabled;
  final Color outlineColor;
  final double outlineSize;
  final String fontFamily;
  final double leftPadding;
  final double rightPadding;
  final double bottomPadding;

  BetterPlayerSubtitlesConfiguration({
    this.fontSize = 14,
    this.fontColor = Colors.white,
    this.outlineEnabled = true,
    this.outlineColor = Colors.black,
    this.outlineSize = 2.0,
    this.fontFamily = "Roboto",
    this.leftPadding = 8.0,
    this.rightPadding = 8.0,
    this.bottomPadding = 20.0,
  });
}
