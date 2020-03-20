import 'dart:async';
import 'dart:ui';

import 'package:better_player/src/better_player_controller.dart';
import 'package:better_player/src/cupertino_controls.dart';
import 'package:better_player/src/material_controls.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  final BetterPlayerSubtitlesConfiguration subtitlesConfiguration;
  final List<BetterPlayerSubtitle> subtitles;
  final StreamController<bool> playerVisibilityStreamController = StreamController();

  PlayerWithControls({Key key, this.subtitlesConfiguration, this.subtitles})
      : super(key: key) {
    playerVisibilityStreamController.add(true);
  }
  

  @override
  Widget build(BuildContext context) {
    print("Build player with controls!");
    final BetterPlayerController betterPlayerController =
        BetterPlayerController.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio:
              betterPlayerController.aspectRatio ?? _calculateAspectRatio(context),
          child: _buildPlayerWithControls(betterPlayerController, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      BetterPlayerController betterPlayerController, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          betterPlayerController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: betterPlayerController.aspectRatio ??
                  _calculateAspectRatio(context),
              child: VideoPlayer(betterPlayerController.videoPlayerController),
            ),
          ),
          betterPlayerController.overlay ?? Container(),
          subtitles != null
              ? BetterPlayerSubtitlesDrawer(
                  betterPlayerController: betterPlayerController,
                  betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
                  subtitles: subtitles,
                  playerVisibilityStream:
                      playerVisibilityStreamController.stream,
                )
              : const SizedBox(),
          _buildControls(context, betterPlayerController),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    BetterPlayerController betterPlayerController,
  ) {
    return betterPlayerController.showControls
        ? betterPlayerController.customControls != null
            ? betterPlayerController.customControls
            : Theme.of(context).platform == TargetPlatform.android
                ? MaterialControls(
                    onControlsVisibilityChanged: onControlsVisibilityChanged)
                : CupertinoControls(
                    backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
                    iconColor: Color.fromARGB(255, 200, 200, 200),
                  )
        : Container();
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}
