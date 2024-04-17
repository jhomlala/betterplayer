import 'package:better_player/src/configuration/better_player_skip_intro_details.dart';
import 'package:flutter/material.dart';

class BetterPlayerSkipIntroConfiguration {
  final BetterPlayerSkipIntroDetails skipIntroDetails;
  final Widget Function() skipIntroBuilder;

  BetterPlayerSkipIntroConfiguration({
    required this.skipIntroDetails,
    required this.skipIntroBuilder,
  });
}
