import 'dart:async';

import 'package:better_player/src/better_player_controller.dart';
import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BetterPlayerWithControls extends StatefulWidget {
  final BetterPlayerSubtitlesConfiguration subtitlesConfiguration;
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final List<BetterPlayerSubtitle> subtitles;

  BetterPlayerWithControls(
      {Key key,
      this.subtitlesConfiguration,
      this.controlsConfiguration,
      this.subtitles})
      : super(key: key);

  @override
  _BetterPlayerWithControlsState createState() => _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  BetterPlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.subtitlesConfiguration;

  BetterPlayerControlsConfiguration get controlsConfiguration =>
      widget.controlsConfiguration;

  List<BetterPlayerSubtitle> get subtitles => widget.subtitles;
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
    print("Build player with controls!");
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
    return controlsConfiguration.showControls
        ? controlsConfiguration.customControls != null
            ? controlsConfiguration.customControls
            : Theme.of(context).platform == TargetPlatform.android
                ? BetterPlayerMaterialControls(
                    onControlsVisibilityChanged: onControlsVisibilityChanged,
                    controlsConfiguration: widget.controlsConfiguration,
                  )
                : BetterPlayerCupertinoControls(
                    onControlsVisibilityChanged: onControlsVisibilityChanged,
                    controlsConfiguration: widget.controlsConfiguration,
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
