import 'dart:async';

import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_cupertino_bottom_bar.dart';
import 'package:better_player/src/controls/better_player_cupertino_error_widget.dart';
import 'package:better_player/src/controls/better_player_cupertino_hit_area.dart';
import 'package:better_player/src/controls/better_player_cupertino_loading_widget.dart';
import 'package:better_player/src/controls/better_player_cupertino_next_video_widget.dart';
import 'package:better_player/src/controls/better_player_cupertino_top_bar.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player/src/controls/better_player_video_area_semantics.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoControls extends StatefulWidget {
  const BetterPlayerCupertinoControls({
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
    return _BetterPlayerCupertinoControlsState();
  }
}

class _BetterPlayerCupertinoControlsState
    extends BetterPlayerControlsState<BetterPlayerCupertinoControls> {
  final marginSize = 5.0;
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;
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
    _betterPlayerController = BetterPlayerController.of(context);

    if (_latestValue?.hasError == true) {
      return BetterPlayerVideoAreaSemantics(
        semanticsIdentifier: 'better_player_cupertino_video_area',
        child: ColoredBox(
          color: Colors.black,
          child: BetterPlayerCupertinoErrorWidget(
            controlsConfiguration: _controlsConfiguration,
          ),
        ),
      );
    }

    final backgroundColor = _controlsConfiguration.controlBarColor;
    final iconColor = _controlsConfiguration.iconsColor;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait
        ? _controlsConfiguration.controlBarHeight
        : _controlsConfiguration.controlBarHeight + 10;
    const buttonPadding = 10.0;

    _wasLoading = isLoading(_latestValue);
    final controlsColumn = Column(
      children: <Widget>[
        BetterPlayerCupertinoTopBar(
          controlsConfiguration: _controlsConfiguration,
          controlsNotVisible: controlsNotVisible,
          barHeight: barHeight * 0.8,
          iconSize: barHeight * 0.4,
          buttonPadding: buttonPadding,
          marginSize: marginSize,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          onExpandCollapse: _onExpandCollapse,
          onShowMoreClicked: onShowMoreClicked,
          onMute: _onMute,
          latestValue: _latestValue,
        ),
        if (_wasLoading)
          Expanded(
            child: Center(
              child: BetterPlayerCupertinoLoadingWidget(
                controlsConfiguration: _controlsConfiguration,
              ),
            ),
          )
        else
          BetterPlayerCupertinoHitArea(
            latestValue: _latestValue,
            controlsNotVisible: controlsNotVisible,
            onCancelAndRestartTimer: cancelAndRestartTimer,
            onHideTimerCancel: () => _hideTimer?.cancel(),
            onChangePlayerControlsNotVisible: changePlayerControlsNotVisible,
          ),
        BetterPlayerCupertinoNextVideoWidget(
          controlsConfiguration: _controlsConfiguration,
        ),
        BetterPlayerCupertinoBottomBar(
          controlsConfiguration: _controlsConfiguration,
          controlsNotVisible: controlsNotVisible,
          barHeight: barHeight,
          marginSize: marginSize,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          onPlayPause: _onPlayPause,
          onSkipBack: skipBack,
          onSkipForward: skipForward,
          onProgressBarDragStart: () => _hideTimer?.cancel(),
          onProgressBarDragEnd: _startHideTimer,
          onProgressBarTapDown: cancelAndRestartTimer,
          onPlayerHide: _onPlayerHide,
          latestValue: _latestValue,
        ),
      ],
    );

    final isFullScreenSafe = _betterPlayerController?.isFullScreen == true;
    return BetterPlayerVideoAreaSemantics(
      semanticsIdentifier: 'better_player_cupertino_video_area',
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
          _onPlayPause();
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
          child: isFullScreenSafe
              ? SafeArea(child: controlsColumn)
              : controlsColumn,
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
    _betterPlayerController!.removeVideoListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);

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

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged(!controlsNotVisible);
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    changePlayerControlsNotVisible(false);
    _startHideTimer();
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
    _expandCollapseTimer = Timer(_controlsConfiguration.controlsHideTime, () {
      setState(cancelAndRestartTimer);
    });
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
        if (_betterPlayerController!.betterPlayerDataSource?.liveStream ==
            true) {
          _betterPlayerController!.play();
          _betterPlayerController!.cancelNextVideoTimer();
        }
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
    _hideTimer = Timer(const Duration(seconds: 3), () {
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
          if (isVideoFinished(_latestValue)) {
            changePlayerControlsNotVisible(false);
          }
        });
      }
    }
  }
}
