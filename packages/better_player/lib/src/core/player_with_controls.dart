import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:better_player/src/controls/player_cupertino_controls.dart';
import 'package:better_player/src/controls/player_material_controls.dart';
import 'package:better_player/src/controls/player_web_controls.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/player_subtitles_drawer.dart';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class PlayerWithControls extends StatefulWidget {
  const PlayerWithControls({super.key, this.controller});
  final BetterPlayerController? controller;

  @override
  _PlayerWithControlsState createState() => _PlayerWithControlsState();
}

class _PlayerWithControlsState extends State<PlayerWithControls> {
  PlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.controller!.betterPlayerSubtitlesConfiguration;

  PlayerControlsConfiguration get controlsConfiguration =>
      widget.controller!.betterPlayerControlsConfiguration;

  final StreamController<bool> playerVisibilityStreamController =
      StreamController.broadcast();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _setupControllerEventSubscription();
    widget.controller!.addVideoListener(_onVideoPlayerChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(PlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller!.removeVideoListener(_onVideoPlayerChanged);
      widget.controller!.addVideoListener(_onVideoPlayerChanged);
      _setupControllerEventSubscription();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _setupControllerEventSubscription() {
    _controllerEventSubscription?.cancel();
    _controllerEventSubscription = widget.controller!.controllerEventStream
        .listen(_onControllerChanged);
  }

  void _onVideoPlayerChanged() {
    if (!mounted || (widget.controller?.isDisposed ?? false)) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller!.removeVideoListener(_onVideoPlayerChanged);
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    super.dispose();
  }

  void _onControllerChanged(PlayerControllerEvent event) {
    if (!mounted || (widget.controller?.isDisposed ?? false)) {
      return;
    }
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
      if (event == PlayerControllerEvent.setupDataSource) {}
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
            betterPlayerController.videoPlayerValue?.aspectRatio ?? 1.0;
      } else {
        aspectRatio =
            config.fullScreenAspectRatio ??
            PlayerUiUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = betterPlayerController.getAspectRatio();
    }

    if (aspectRatio == null || aspectRatio <= 0 || !aspectRatio.isFinite) {
      aspectRatio = 16 / 9;
    }
    final innerContainer = Container(
      width: double.infinity,
      color: betterPlayerController
          .betterPlayerControlsConfiguration
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
      PlayerLogger.warning(
        message: 'Invalid rotation provided. Using rotation = 0',
        textureId: betterPlayerController.textureId,
      );
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
            PlayerPlaceholder(controller: betterPlayerController),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _PlayerVideoFitWidget(
              betterPlayerController,
              betterPlayerController.getFit(),
            ),
          ),
          betterPlayerController.betterPlayerConfiguration.overlay ??
              const SizedBox(),
          if (!placeholderOnTop)
            PlayerPlaceholder(controller: betterPlayerController),
          PlayerControlsSelectionWidget(
            controller: betterPlayerController,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
          ),
          // IgnorePointer is required so that the subtitles layer (which expands to fill the screen)
          // doesn't block touch events from reaching the video controls below it.
          IgnorePointer(
            child: PlayerSubtitlesDrawer(
              betterPlayerController: betterPlayerController,
              betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
              subtitles: betterPlayerController.subtitlesLines,
              playerVisibilityStream: playerVisibilityStreamController.stream,
            ),
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
class PlayerPlaceholder extends StatelessWidget {
  const PlayerPlaceholder({
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
class PlayerControlsSelectionWidget extends StatelessWidget {
  const PlayerControlsSelectionWidget({
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
        if (controlsConfiguration.customControlsBuilder != null) {
          playerTheme = PlayerTheme.custom;
        } else if (kIsWeb) {
          playerTheme = PlayerTheme.web;
        } else if (defaultTargetPlatform == TargetPlatform.android) {
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
        return PlayerMaterialControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      } else if (playerTheme == PlayerTheme.cupertino) {
        return PlayerCupertinoControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      } else if (playerTheme == PlayerTheme.web) {
        return PlayerWebControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      }
    }

    return const SizedBox();
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _PlayerVideoFitWidget extends StatefulWidget {
  const _PlayerVideoFitWidget(this.betterPlayerController, this.boxFit);

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _PlayerVideoFitWidgetState createState() => _PlayerVideoFitWidgetState();
}

class _PlayerVideoFitWidgetState extends State<_PlayerVideoFitWidget> {
  bool _initialized = false;
  bool _started = false;
  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    _updateStartedFlag();
    _initialized =
        widget.betterPlayerController.videoPlayerValue?.initialized ?? false;
    _setupControllerEventSubscription();
    widget.betterPlayerController.addVideoListener(_onVideoPlayerChanged);
  }

  @override
  void didUpdateWidget(_PlayerVideoFitWidget oldWidget) {
    if (oldWidget.betterPlayerController != widget.betterPlayerController) {
      oldWidget.betterPlayerController.removeVideoListener(
        _onVideoPlayerChanged,
      );
      widget.betterPlayerController.addVideoListener(_onVideoPlayerChanged);
      _setupControllerEventSubscription();
    }

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
    if (!mounted || widget.betterPlayerController.isDisposed) {
      return;
    }
    switch (event) {
      case PlayerControllerEvent.play:
        if (!_started) {
          setState(_updateStartedFlag);
        }
      case PlayerControllerEvent.setupDataSource:
        setState(() {
          _updateStartedFlag();
          _initialized =
              widget.betterPlayerController.videoPlayerValue?.initialized ??
              false;
        });
      default:
        break;
    }
  }

  void _onVideoPlayerChanged() {
    if (!mounted || widget.betterPlayerController.isDisposed) {
      return;
    }
    final isInitialized =
        widget.betterPlayerController.videoPlayerValue?.initialized ?? false;
    setState(() {
      _initialized = isInitialized;
      _updateStartedFlag();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _started) {
      final size = widget.betterPlayerController.videoPlayerValue?.size;
      return Center(
        child: ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: widget.boxFit,
              child: SizedBox(
                width: size?.width ?? 0,
                height: size?.height ?? 0,
                child: widget.betterPlayerController.buildVideoPlayerView(),
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
    widget.betterPlayerController.removeVideoListener(_onVideoPlayerChanged);
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}
