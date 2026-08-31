import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerWithControls extends StatefulWidget {
  const BetterPlayerWithControls({super.key, this.controller});
  final BetterPlayerController? controller;

  @override
  _BetterPlayerWithControlsState createState() =>
      _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  PlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.controller!.betterPlayerConfiguration.subtitlesConfiguration;

  PlayerControlsConfiguration get controlsConfiguration =>
      widget.controller!.betterPlayerControlsConfiguration;

  final StreamController<bool> playerVisibilityStreamController =
      StreamController();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _setupControllerEventSubscription();
    _setupVideoPlayerControllerListener();
    super.initState();
  }

  @override
  void didUpdateWidget(BetterPlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _setupControllerEventSubscription();
      _setupVideoPlayerControllerListener();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setupControllerEventSubscription() {
    _controllerEventSubscription?.cancel();
    _controllerEventSubscription = widget.controller!.controllerEventStream
        .listen(_onControllerChanged);
  }

  /// Sets up a listener for the [VideoPlayerController].
  /// This is required to react to resolution changes (HLS ABR) and update
  /// the aspect ratio of the player (Issue #768).
  void _setupVideoPlayerControllerListener() {
    if (_videoPlayerController != widget.controller!.videoPlayerController) {
      _videoPlayerController?.removeListener(_onVideoPlayerChanged);
      _videoPlayerController = widget.controller!.videoPlayerController;
      _videoPlayerController?.addListener(_onVideoPlayerChanged);
    }
  }

  void _onVideoPlayerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    _videoPlayerController?.removeListener(_onVideoPlayerChanged);
    super.dispose();
  }

  void _onControllerChanged(PlayerControllerEvent event) {
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
      if (event == PlayerControllerEvent.setupDataSource) {
        _setupVideoPlayerControllerListener();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final betterPlayerController = BetterPlayerController.of(context);

    double? aspectRatio;
    if (betterPlayerController.isFullScreen) {
      final config = betterPlayerController.betterPlayerConfiguration;
      if (config.autoDetectFullscreenDeviceOrientation ||
          config.autoDetectFullscreenAspectRatio) {
        aspectRatio =
            betterPlayerController.videoPlayerController?.value.aspectRatio ??
            1.0;
      } else {
        aspectRatio =
            config.fullScreenAspectRatio ??
            BetterPlayerUiUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = betterPlayerController.getAspectRatio();
    }

    aspectRatio ??= 16 / 9;
    final innerContainer = Container(
      width: double.infinity,
      color: betterPlayerController
          .betterPlayerConfiguration
          .controlsConfiguration
          .backgroundColor,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _buildPlayerWithControls(betterPlayerController, context),
      ),
    );

    if (betterPlayerController.betterPlayerConfiguration.expandToFill) {
      return Center(child: innerContainer);
    } else {
      return innerContainer;
    }
  }

  Container _buildPlayerWithControls(
    BetterPlayerController betterPlayerController,
    BuildContext context,
  ) {
    final configuration = betterPlayerController.betterPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      PlayerLogger.warning('Invalid rotation provided. Using rotation = 0');
      rotation = 0;
    }
    if (betterPlayerController.betterPlayerDataSource == null) {
      return Container();
    }
    _initialized = true;

    final placeholderOnTop =
        betterPlayerController.betterPlayerConfiguration.placeholderOnTop;
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (placeholderOnTop)
            BetterPlayerPlaceholder(controller: betterPlayerController),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _BetterPlayerVideoFitWidget(
              betterPlayerController,
              betterPlayerController.getFit(),
            ),
          ),
          betterPlayerController.betterPlayerConfiguration.overlay ??
              const SizedBox(),
          PlayerSubtitlesDrawer(
            betterPlayerController: betterPlayerController,
            betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
            subtitles: betterPlayerController.subtitlesLines,
            playerVisibilityStream: playerVisibilityStreamController.stream,
          ),
          if (!placeholderOnTop)
            BetterPlayerPlaceholder(controller: betterPlayerController),
          BetterPlayerControlsSelectionWidget(
            controller: betterPlayerController,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
          ),
        ],
      ),
    );
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}

///Widget which renders placeholder on top of the video.
class BetterPlayerPlaceholder extends StatelessWidget {
  const BetterPlayerPlaceholder({
    required this.controller,
    super.key,
  });

  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return controller.betterPlayerDataSource?.placeholder ??
        controller.betterPlayerConfiguration.placeholder ??
        const SizedBox();
  }
}

///Widget which determines which controls should be used.
class BetterPlayerControlsSelectionWidget extends StatelessWidget {
  const BetterPlayerControlsSelectionWidget({
    required this.controller,
    required this.onControlsVisibilityChanged,
    super.key,
  });

  final BetterPlayerController controller;
  final Function(bool) onControlsVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final controlsConfiguration = controller.betterPlayerControlsConfiguration;
    if (controlsConfiguration.showControls) {
      var playerTheme = controlsConfiguration.playerTheme;
      if (playerTheme == null) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          playerTheme = PlayerTheme.material;
        } else {
          playerTheme = PlayerTheme.cupertino;
        }
      }

      if (controlsConfiguration.customControlsBuilder != null &&
          playerTheme == PlayerTheme.custom) {
        return controlsConfiguration.customControlsBuilder!(
          controller,
          onControlsVisibilityChanged,
        );
      } else if (playerTheme == PlayerTheme.material) {
        return BetterPlayerMaterialControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      } else if (playerTheme == PlayerTheme.cupertino) {
        return BetterPlayerCupertinoControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      }
    }

    return const SizedBox();
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _BetterPlayerVideoFitWidget extends StatefulWidget {
  const _BetterPlayerVideoFitWidget(this.betterPlayerController, this.boxFit);

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _BetterPlayerVideoFitWidgetState createState() =>
      _BetterPlayerVideoFitWidgetState();
}

class _BetterPlayerVideoFitWidgetState
    extends State<_BetterPlayerVideoFitWidget> {
  VideoPlayerController? get controller =>
      widget.betterPlayerController.videoPlayerController;

  bool _initialized = false;
  bool _started = false;
  StreamSubscription? _controllerEventSubscription;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _updateStartedFlag();
    _initialized = controller?.value.initialized ?? false;
    _setupControllerEventSubscription();
    _setupVideoPlayerControllerListener();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    if (oldWidget.betterPlayerController != widget.betterPlayerController) {
      _setupControllerEventSubscription();
    }
    _setupVideoPlayerControllerListener();
    super.didUpdateWidget(oldWidget);
  }

  void _updateStartedFlag() {
    final config = widget.betterPlayerController.betterPlayerConfiguration;
    if (!config.showPlaceholderUntilPlay) {
      _started = true;
    } else {
      _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
    }
  }

  void _setupControllerEventSubscription() {
    _controllerEventSubscription?.cancel();
    _controllerEventSubscription = widget
        .betterPlayerController
        .controllerEventStream
        .listen(_onControllerEvent);
  }

  void _onControllerEvent(PlayerControllerEvent event) {
    switch (event) {
      case PlayerControllerEvent.play:
        if (!_started) {
          setState(_updateStartedFlag);
        }
      case PlayerControllerEvent.setupDataSource:
        setState(() {
          _started = false;
          _initialized = false;
          _setupVideoPlayerControllerListener();
        });
      default:
        break;
    }
  }

  /// Sets up a listener for the [VideoPlayerController].
  /// This is required to react to resolution changes (HLS ABR) and update
  /// the video dimensions inside FittedBox (Issue #768).
  void _setupVideoPlayerControllerListener() {
    if (_videoPlayerController != controller) {
      _videoPlayerController?.removeListener(_onVideoPlayerChanged);
      _videoPlayerController = controller;
      _videoPlayerController?.addListener(_onVideoPlayerChanged);
    }
  }

  void _onVideoPlayerChanged() {
    if (!mounted) {
      return;
    }
    final isInitialized = controller?.value.initialized ?? false;
    if (isInitialized != _initialized) {
      setState(() {
        _initialized = isInitialized;
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _started) {
      return Center(
        child: ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: widget.boxFit,
              child: SizedBox(
                width: controller!.value.size?.width ?? 0,
                height: controller!.value.size?.height ?? 0,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_onVideoPlayerChanged);
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}
