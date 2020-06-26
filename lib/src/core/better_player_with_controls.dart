import 'dart:async';

import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

class BetterPlayerWithControls extends StatefulWidget {
  final BetterPlayerController controller;

  BetterPlayerWithControls({Key key, this.controller}) : super(key: key);

  @override
  _BetterPlayerWithControlsState createState() =>
      _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  BetterPlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.controller.betterPlayerConfiguration.subtitlesConfiguration;

  BetterPlayerControlsConfiguration get controlsConfiguration =>
      widget.controller.betterPlayerConfiguration.controlsConfiguration;

  final StreamController<bool> playerVisibilityStreamController =
      StreamController();

  @override
  void initState() {
    playerVisibilityStreamController.add(true);

    super.initState();
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BetterPlayerController betterPlayerController =
        BetterPlayerController.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: betterPlayerController.aspectRatio ??
              _calculateAspectRatio(context),
          child: _buildPlayerWithControls(betterPlayerController, context),
        ),
      ),
    );
  }

  Widget _buildOverlay(
    BuildContext context,
    BetterPlayerController betterPlayerController,
  ) {
    if (betterPlayerController.overlay == null) {
      return Container();
    }

    return betterPlayerController.overlay;
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
          betterPlayerController.betterPlayerDataSource.subtitles != null
              ? BetterPlayerSubtitlesDrawer(
                  betterPlayerController: betterPlayerController,
                  betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
                  subtitles: betterPlayerController.subtitles,
                  playerVisibilityStream:
                      playerVisibilityStreamController.stream,
                )
              : const SizedBox(),
          _buildControls(context, betterPlayerController),
          _buildOverlay(context, betterPlayerController),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    BetterPlayerController betterPlayerController,
  ) {
    return controlsConfiguration.showControls
        ? controlsConfiguration.customControls != null
            ? controlsConfiguration.customControls
            : Theme.of(context).platform == TargetPlatform.android
                ? BetterPlayerMaterialControls(
                    onControlsVisibilityChanged: onControlsVisibilityChanged,
                    controlsConfiguration: controlsConfiguration,
                  )
                : BetterPlayerCupertinoControls(
                    onControlsVisibilityChanged: onControlsVisibilityChanged,
                    controlsConfiguration: controlsConfiguration,
                  )
        : const SizedBox();
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
