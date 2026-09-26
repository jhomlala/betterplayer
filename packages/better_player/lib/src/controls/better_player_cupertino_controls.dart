import 'dart:async';

import 'package:better_player/src/configuration/player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_cupertino_bottom_bar.dart';
import 'package:better_player/src/controls/better_player_cupertino_error_widget.dart';
import 'package:better_player/src/controls/better_player_cupertino_hit_area.dart';
import 'package:better_player/src/controls/better_player_cupertino_loading_widget.dart';
import 'package:better_player/src/controls/better_player_cupertino_localizations_delegate.dart';
import 'package:better_player/src/controls/better_player_cupertino_middle_row.dart';
import 'package:better_player/src/controls/better_player_cupertino_next_video_widget.dart';
import 'package:better_player/src/controls/better_player_cupertino_top_bar.dart';
import 'package:better_player/src/controls/better_player_material_localizations_delegate.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player/src/controls/better_player_video_area_semantics.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/cupertino.dart';
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
    PlayerLogger.debug(message: "E2E_LOG: BetterPlayerCupertinoControlsState.build start",
    );
    final translations = BetterPlayerController.of(context).translations;
    return Localizations.override(
      context: context,
      delegates: [
        BetterPlayerMaterialLocalizationsDelegate(translations),
        BetterPlayerCupertinoLocalizationsDelegate(translations),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
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

            final iconColor = _controlsConfiguration.iconsColor;
            final orientation = MediaQuery.of(context).orientation;
            final barHeight = orientation == Orientation.portrait
                ? _controlsConfiguration.controlBarHeight
                : _controlsConfiguration.controlBarHeight + 10;
            const buttonPadding = 10.0;

            _wasLoading = isLoading(_latestValue);
            final controlsColumn = CupertinoTheme(
              data: const CupertinoThemeData(brightness: Brightness.dark),
              child: Column(
                children: <Widget>[
                  AnimatedSlide(
                    offset: controlsNotVisible
                        ? const Offset(0, -0.2)
                        : Offset.zero,
                    duration: _controlsConfiguration.controlsTransitionTime,
                    child: AnimatedOpacity(
                      opacity: controlsNotVisible ? 0.0 : 1.0,
                      duration: _controlsConfiguration.controlsTransitionTime,
                      child: BetterPlayerCupertinoTopBar(
                        controlsConfiguration: _controlsConfiguration,
                        controlsNotVisible: false, // handeled by wrapper now
                        barHeight: 32,
                        iconSize: 18,
                        buttonPadding: buttonPadding,
                        iconColor: iconColor,
                        onExpandCollapse: _onExpandCollapse,
                        onShowMoreClicked: onShowMoreClicked,
                        onMute: _onMute,
                        latestValue: _latestValue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: BetterPlayerCupertinoHitArea(
                            latestValue: _latestValue,
                            controlsNotVisible: controlsNotVisible,
                            onCancelAndRestartTimer: cancelAndRestartTimer,
                            onHideTimerCancel: () => _hideTimer?.cancel(),
                            onChangePlayerControlsNotVisible:
                                changePlayerControlsNotVisible,
                          ),
                        ),
                        if (_wasLoading)
                          BetterPlayerCupertinoLoadingWidget(
                            controlsConfiguration: _controlsConfiguration,
                          )
                        else
                          AnimatedOpacity(
                            opacity: controlsNotVisible ? 0.0 : 1.0,
                            duration:
                                _controlsConfiguration.controlsTransitionTime,
                            child: BetterPlayerCupertinoMiddleRow(
                              controlsConfiguration: _controlsConfiguration,
                              onSkipBack: skipBack,
                              onSkipForward: skipForward,
                              onPlayPause: _onPlayPause,
                              latestValue: _latestValue,
                              iconColor: iconColor,
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: BetterPlayerCupertinoNextVideoWidget(
                            controlsConfiguration: _controlsConfiguration,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSlide(
                    offset: controlsNotVisible
                        ? const Offset(0, 0.2)
                        : Offset.zero,
                    duration: _controlsConfiguration.controlsTransitionTime,
                    child: AnimatedOpacity(
                      opacity: controlsNotVisible ? 0.0 : 1.0,
                      duration: _controlsConfiguration.controlsTransitionTime,
                      onEnd: _onPlayerHide,
                      child: BetterPlayerCupertinoBottomBar(
                        controlsConfiguration: _controlsConfiguration,
                        barHeight: barHeight,
                        iconColor: iconColor,
                        onProgressBarDragStart: () => _hideTimer?.cancel(),
                        onProgressBarDragEnd: _startHideTimer,
                        onProgressBarTapDown: cancelAndRestartTimer,
                        latestValue: _latestValue,
                        onPlayPause: _onPlayPause,
                      ),
                    ),
                  ),
                ],
              ),
            );

            final isFullScreenSafe =
                _betterPlayerController?.isFullScreen == true;
            return BetterPlayerVideoAreaSemantics(
              semanticsIdentifier: 'better_player_cupertino_video_area',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (BetterPlayerMultipleGestureDetector.of(context) != null) {
                    BetterPlayerMultipleGestureDetector.of(
                      context,
                    )!.onTap?.call();
                  }
                  controlsNotVisible
                      ? cancelAndRestartTimer()
                      : changePlayerControlsNotVisible(true);
                },
                onDoubleTap:
                    BetterPlayerMultipleGestureDetector.of(context) != null
                    ? () {
                        BetterPlayerMultipleGestureDetector.of(
                          context,
                        )!.onDoubleTap?.call();
                        cancelAndRestartTimer();
                        _onPlayPause();
                      }
                    : null,
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
          },
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

    if (_latestValue?.volume == 0) {
      _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
    } else {
      _latestVolume = _betterPlayerController!.videoPlayerValue?.volume;
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

    if ((_betterPlayerController!.videoPlayerValue?.isPlaying ?? false) ||
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
    _expandCollapseTimer = Timer(
      _controlsConfiguration.controlsTransitionTime,
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

    if (_betterPlayerController!.videoPlayerValue?.isPlaying ?? false) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else {
      cancelAndRestartTimer();

      if (!(_betterPlayerController!.videoPlayerValue?.initialized ?? false)) {
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
    _hideTimer = Timer(_controlsConfiguration.controlsHideTime, () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    if (mounted) {
      final isFinished = isVideoFinished(
        _betterPlayerController!.videoPlayerValue,
      );
      final isBuff =
          _betterPlayerController!.videoPlayerValue?.isBuffering ?? false;
      final isPlay =
          _betterPlayerController!.videoPlayerValue?.isPlaying ?? false;
      final isLoad = isLoading(_betterPlayerController!.videoPlayerValue);
      final hasDur =
          _betterPlayerController!.videoPlayerValue?.duration != null;

      if (!controlsNotVisible || isFinished || _wasLoading || isLoad) {
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
