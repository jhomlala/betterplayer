import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:better_player/src/engine/player_engine_controller.dart';
import 'package:better_player/src/engine/player_engine_view.dart';
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


  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _setupControllerEventSubscription();
    _setupVideoPlayerControllerListener();
    super.initState();
  }

@override
void didUpdateWidget(BetterPlayerWithControls oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.controller != widget.controller) {
    _setupEngineControllerListener();
  }
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
        betterPlayerController.playerValue?.aspectRatio ?? 1.0;
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

        betterPlayerController.playerValue?.aspectRatio ?? 1.0;
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

class _BetterPlayerVideoFitWidgetState extends State<_BetterPlayerVideoFitWidget> {
  PlayerEngineController? _engineController;

  @override
  void initState() {
    super.initState();
    _setupEngineControllerListener();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController != widget.betterPlayerController) {
      _setupEngineControllerListener();
    }
  }

  void _setupEngineControllerListener() {
    final newController = widget.betterPlayerController.engineController;
    if (_engineController != newController) {
      _engineController?.removeListener(_onEngineChanged);
      _engineController = newController;
      _engineController?.addListener(_onEngineChanged);
    }
  }

  void _onEngineChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _engineController?.value.initialized ?? false;
    if (initialized) {
      return Center(
        child: ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: widget.boxFit,
              child: SizedBox(
                width: _engineController?.value.size?.width ?? 0,
                height: _engineController?.value.size?.height ?? 0,
                child: VideoPlayer(_engineController!),
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
    _engineController?.removeListener(_onEngineChanged);
    super.dispose();
  }
}
