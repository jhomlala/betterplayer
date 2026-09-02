import 'package:better_player/src/core/better_player_controller_provider.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'dart:async';
import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_material_bottom_bar.dart';
import 'package:better_player/src/controls/better_player_material_error_widget.dart';
import 'package:better_player/src/controls/better_player_material_loading_widget.dart';
import 'package:better_player/src/controls/better_player_material_middle_row.dart';
import 'package:better_player/src/controls/better_player_material_next_video_widget.dart';
import 'package:better_player/src/controls/better_player_material_top_bar.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player/src/controls/better_player_video_area_semantics.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/engine/player_engine_controller.dart';

// Flutter imports:
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialControls extends StatefulWidget {
  const BetterPlayerMaterialControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
    super.key,
  });

  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final PlayerControlsConfiguration controlsConfiguration;

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerMaterialControlsState();
  }
}

class _BetterPlayerMaterialControlsState
    extends BetterPlayerControlsState<BetterPlayerMaterialControls> {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _displayTapped = false;
  bool _wasLoading = false;
  
  BetterPlayerController? _betterPlayerController;
  StreamSubscription? _controlsVisibilityStreamSubscription;

  PlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  PlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return buildLTRDirectionality(_buildMainWidget());
  }

  ///Builds main widget of the controls.
  Widget _buildMainWidget() {
    _wasLoading = isLoading(_latestValue);
    if (_latestValue?.hasError == true) {
      return BetterPlayerVideoAreaSemantics(
        semanticsIdentifier: 'better_player_material_video_area',
        child: ColoredBox(
          color: Colors.black,
          child: BetterPlayerMaterialErrorWidget(
                        controlsConfiguration: _controlsConfiguration,
          ),
        ),
      );
    }
    return BetterPlayerVideoAreaSemantics(
      semanticsIdentifier: 'better_player_material_video_area',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (BetterPlayerMultipleGestureDetector.of(context) != null) {
            BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
          }
          controlsNotVisible
              ? cancelAndRestartTimer()
              : changePlayerControlsNotVisible(true);
        },
        onDoubleTap: () {
          if (BetterPlayerMultipleGestureDetector.of(context) != null) {
            BetterPlayerMultipleGestureDetector.of(
              context,
            )!.onDoubleTap?.call();
          }
          cancelAndRestartTimer();
        },
        onLongPress: () {
          if (BetterPlayerMultipleGestureDetector.of(context) != null) {
            BetterPlayerMultipleGestureDetector.of(
              context,
            )!.onLongPress?.call();
          }
        },
        child: AbsorbPointer(
          absorbing: controlsNotVisible,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_wasLoading)
                Center(
                  child: BetterPlayerMaterialLoadingWidget(
                    controlsConfiguration: _controlsConfiguration,
                  ),
                )
              else
                BetterPlayerMaterialHitArea(
                                    controlsConfiguration: _controlsConfiguration,
                  controlsNotVisible: controlsNotVisible,
                  onSkipBack: skipBack,
                  onSkipForward: skipForward,
                  onReplay: _onReplay,
                  latestValue: _latestValue,
                  isVideoFinished: isVideoFinished(_latestValue),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BetterPlayerMaterialTopBar(
                  controller: _betterPlayerController!,
                                    controlsConfiguration: _controlsConfiguration,
                  controlsNotVisible: controlsNotVisible,
                  onPlayerHide: _onPlayerHide,
                  onShowMoreClicked: onShowMoreClicked,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: BetterPlayerMaterialBottomBar(
                                    controlsConfiguration: _controlsConfiguration,
                  controlsNotVisible: controlsNotVisible,
                  onPlayerHide: _onPlayerHide,
                  onPlayPause: _onPlayPause,
                  onMute: _onMute,
                  onExpandCollapse: _onExpandCollapse,
                  onProgressBarDragStart: () {
                    _hideTimer?.cancel();
                  },
                  onProgressBarDragEnd: _startHideTimer,
                  onProgressBarTapDown: cancelAndRestartTimer,
                  latestValue: _latestValue,
                ),
              ),
              BetterPlayerMaterialNextVideoWidget(
                controller: _betterPlayerController!,
                                controlsConfiguration: _controlsConfiguration,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _betterPlayerController?.removeVideoListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    
    _latestValue = _betterPlayerController!.videoPlayerValue;

    if (oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  void _onMute() {
    cancelAndRestartTimer();
    if (_latestValue == null) {
      return;
    }
    if (_latestValue!.volume == 0) {
      _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
    } else {
      _latestVolume = _betterPlayerController!.videoPlayerValue!.volume;
      _betterPlayerController!.setVolume(0);
    }
  }

  void _onReplay() {
    final isFinished = isVideoFinished(_latestValue);
    if (isFinished) {
      if (_latestValue != null && _latestValue!.isPlaying) {
        if (_displayTapped) {
          changePlayerControlsNotVisible(true);
        } else {
          cancelAndRestartTimer();
        }
      } else {
        _onPlayPause();
        changePlayerControlsNotVisible(true);
      }
    } else {
      _onPlayPause();
    }
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    changePlayerControlsNotVisible(false);
    _displayTapped = true;
  }

  Future<void> _initialize() async {
    controlsNotVisible = !_betterPlayerController!.controlsAlwaysVisible;
    _betterPlayerController!.addVideoListener(_updateState);

    _updateState();

    if ((_betterPlayerController!.videoPlayerValue!.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        changePlayerControlsNotVisible(false);
      });
    }

    _controlsVisibilityStreamSubscription = _betterPlayerController!
        .controlsVisibilityStream
        .listen((state) {
          changePlayerControlsNotVisible(!state);
          if (!controlsNotVisible) {
            cancelAndRestartTimer();
          }
        });
  }

  void _onExpandCollapse() {
    changePlayerControlsNotVisible(true);
    _betterPlayerController!.toggleFullScreen();
    _showAfterExpandCollapseTimer = Timer(
      _controlsConfiguration.controlsHideTime,
      () {
        setState(cancelAndRestartTimer);
      },
    );
  }

  void _onPlayPause() {
    var isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }

    if (_betterPlayerController!.videoPlayerValue!.isPlaying) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else {
      cancelAndRestartTimer();

      if (!_betterPlayerController!.videoPlayerValue!.initialized) {
      } else {
        if (isFinished) {
          _betterPlayerController!.seekTo(const Duration());
        }
        _betterPlayerController!.play();
        _betterPlayerController!.cancelNextVideoTimer();
      }
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 3000), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    if (mounted) {
      if (!controlsNotVisible ||
          isVideoFinished(_betterPlayerController!.videoPlayerValue) ||
          _wasLoading ||
          isLoading(_betterPlayerController!.videoPlayerValue)) {
        setState(() {
          _latestValue = _betterPlayerController!.videoPlayerValue;
          if (isVideoFinished(_latestValue) &&
              _betterPlayerController?.isLiveStream() == false) {
            changePlayerControlsNotVisible(false);
          }
        });
      }
    }
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged(!controlsNotVisible);
  }
}





