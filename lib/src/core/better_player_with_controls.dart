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
        width: double.infinity,
        color: Colors.black,
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
          _BetterPlayerVideoFitWidget(
            betterPlayerController,
            betterPlayerController.betterPlayerConfiguration.fit,
          ),
          betterPlayerController.overlay ?? Container(),
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

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _BetterPlayerVideoFitWidget extends StatefulWidget {
  _BetterPlayerVideoFitWidget(
    this.betterPlayerController,
    this.boxFit,
  )   : assert(betterPlayerController != null,
            "BetterPlayerController can't be null"),
        assert(boxFit != null, "BoxFit can't be null");

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _BetterPlayerVideoFitWidgetState createState() =>
      _BetterPlayerVideoFitWidgetState();
}

class _BetterPlayerVideoFitWidgetState
    extends State<_BetterPlayerVideoFitWidget> {
  VideoPlayerController get controller =>
      widget.betterPlayerController.videoPlayerController;

  bool _initialized = false;

  VoidCallback _initializedListener;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController.videoPlayerController != controller) {
      oldWidget.betterPlayerController.videoPlayerController
          .removeListener(_initializedListener);
      _initialized = false;
      _initialize();
    }
  }

  void _initialize() {
    _initializedListener = () {
      if (!mounted) {
        return;
      }
      if (_initialized != controller.value.initialized) {
        _initialized = controller.value.initialized;
        setState(() {});
      }
    };
    controller.addListener(_initializedListener);
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: widget.boxFit,
            child: SizedBox(
              width: controller.value.size?.width ?? 0,
              height: controller.value.size?.height ?? 0,
              child: VideoPlayer(controller),
              //
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
