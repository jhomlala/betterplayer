import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
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
    widget.controller.addListener(_onControllerChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(BetterPlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(_onControllerChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {}

  @override
  Widget build(BuildContext context) {
    final BetterPlayerController betterPlayerController =
        BetterPlayerController.of(context);

    var aspectRatio;
    if (betterPlayerController.isFullScreen) {
      aspectRatio = betterPlayerController
              .betterPlayerConfiguration.fullScreenAspectRatio ??
          BetterPlayerUtils.calculateAspectRatio(context);
    } else {
      aspectRatio =
          betterPlayerController.betterPlayerConfiguration.aspectRatio ??
              BetterPlayerUtils.calculateAspectRatio(context);
    }

    return Center(
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildPlayerWithControls(betterPlayerController, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      BetterPlayerController betterPlayerController, BuildContext context) {
    var configuration = betterPlayerController.betterPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      print("Invalid rotation provided. Using rotation = 0");
      rotation = 0;
    }
    return Container(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          betterPlayerController.placeholder ?? Container(),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _BetterPlayerVideoFitWidget(
              betterPlayerController,
              betterPlayerController.betterPlayerConfiguration.fit,
            ),
          ),
          betterPlayerController.overlay ?? Container(),
          BetterPlayerSubtitlesDrawer(
            betterPlayerController: betterPlayerController,
            betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
            subtitles: betterPlayerController.subtitlesLines,
            playerVisibilityStream: playerVisibilityStreamController.stream,
          ),
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
            : Platform.isAndroid
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

  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.betterPlayerController.betterPlayerConfiguration
        .showPlaceholderUntilPlay) {
      widget.betterPlayerController.addEventsListener((event) {
        if (!_started &&
            event.betterPlayerEventType == BetterPlayerEventType.PLAY) {
          setState(() {
            _started = true;
          });
        }
      });
    } else {
      _started = true;
    }
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
    if (_initialized && _started) {
      return Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: widget.boxFit ?? BoxFit.fill,
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

  @override
  void dispose() {
    widget.betterPlayerController.videoPlayerController
        .removeListener(_initializedListener);
    super.dispose();
  }
}
