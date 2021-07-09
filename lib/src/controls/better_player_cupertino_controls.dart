// Dart imports:
import 'dart:async';
import 'dart:ui' as ui;

// Flutter imports:
import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/video_player/video_player.dart';

class BetterPlayerCupertinoControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerCupertinoControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
    Key? key,
  }) : super(key: key);

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
  bool _hideStuff = true;
  Timer? _hideTimer;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;
  bool _wasLoading = false;

  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  StreamSubscription? _controlsVisibilityStreamSubscription;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    _betterPlayerController = BetterPlayerController.of(context);

    if (_latestValue?.hasError == true) {
      return Container(
        color: Colors.black,
        child: _buildErrorWidget(),
      );
    }

    final backgroundColor = _controlsConfiguration.controlBarColor;
    final iconColor = _controlsConfiguration.iconsColor;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait
        ? _controlsConfiguration.controlBarHeight
        : _controlsConfiguration.controlBarHeight + 17;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;
    _wasLoading = isLoading(_latestValue);
    return GestureDetector(
      onTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
        }
        _hideStuff
            ? cancelAndRestartTimer()
            : setState(() {
                _hideStuff = true;
              });
      },
      onDoubleTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onDoubleTap?.call();
        }
        cancelAndRestartTimer();
        _onPlayPause();
      },
      onLongPress: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onLongPress?.call();
        }
      },
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            _buildTopBar(backgroundColor, iconColor, barHeight, buttonPadding),
            if (_wasLoading)
              Expanded(child: Center(child: _buildLoadingWidget()))
            else
              _buildHitArea(),
            _buildNextVideoWidget(),
            _buildBottomBar(backgroundColor, iconColor, barHeight),
          ],
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
    _controller!.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(marginSize),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              height: barHeight,
              color: backgroundColor,
              child: _betterPlayerController!.isLiveStream()
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const SizedBox(width: 8),
                        if (_controlsConfiguration.enablePlayPause)
                          _buildPlayPause(_controller!, iconColor, barHeight)
                        else
                          const SizedBox(),
                        const SizedBox(width: 8),
                        _buildLiveWidget(),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        if (_controlsConfiguration.enableSkips)
                          _buildSkipBack(iconColor, barHeight)
                        else
                          const SizedBox(),
                        if (_controlsConfiguration.enablePlayPause)
                          _buildPlayPause(_controller!, iconColor, barHeight)
                        else
                          const SizedBox(),
                        if (_controlsConfiguration.enableSkips)
                          _buildSkipForward(iconColor, barHeight)
                        else
                          const SizedBox(),
                        if (_controlsConfiguration.enableProgressText)
                          _buildPosition()
                        else
                          const SizedBox(),
                        if (_controlsConfiguration.enableProgressBar)
                          _buildProgressBar()
                        else
                          const SizedBox(),
                        if (_controlsConfiguration.enableProgressText)
                          _buildRemaining()
                        else
                          const SizedBox()
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveWidget() {
    return Expanded(
      child: Text(
        _betterPlayerController!.translations.controlsLive,
        style: TextStyle(
            color: _controlsConfiguration.liveTextColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: buttonPadding,
                right: buttonPadding,
              ),
              color: backgroundColor,
              child: Center(
                child: Icon(
                  _betterPlayerController!.isFullScreen
                      ? _controlsConfiguration.fullscreenDisableIcon
                      : _controlsConfiguration.fullscreenEnableIcon,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: _latestValue != null && _latestValue!.isPlaying
            ? () {
                if (_hideStuff == true) {
                  cancelAndRestartTimer();
                } else {
                  _hideTimer?.cancel();

                  setState(() {
                    _hideStuff = true;
                  });
                }
              }
            : () {
                _hideTimer?.cancel();

                setState(() {
                  _hideStuff = false;
                });
              },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  GestureDetector _buildMoreButton(
    VideoPlayerController? controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        onShowMoreClicked();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                ),
                child: Icon(
                  _controlsConfiguration.overflowMenuIcon,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController? controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        cancelAndRestartTimer();

        if (_latestValue!.volume == 0) {
          controller!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller!.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                ),
                child: Icon(
                  (_latestValue != null && _latestValue!.volume > 0)
                      ? _controlsConfiguration.muteIcon
                      : _controlsConfiguration.unMuteIcon,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: _onPlayPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          controller.value.isPlaying
              ? _controlsConfiguration.pauseIcon
              : _controlsConfiguration.playIcon,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue!.position : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        BetterPlayerUtils.formatDuration(position),
        style: TextStyle(
          color: _controlsConfiguration.textColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining() {
    final position = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration! - _latestValue!.position
        : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '-${BetterPlayerUtils.formatDuration(position)}',
        style:
            TextStyle(color: _controlsConfiguration.textColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          _controlsConfiguration.skipBackIcon,
          color: iconColor,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        margin: const EdgeInsets.only(right: 8.0),
        child: Icon(
          _controlsConfiguration.skipForwardIcon,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }

    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          if (_controlsConfiguration.enableFullscreen)
            _buildExpandButton(
                backgroundColor, iconColor, barHeight, buttonPadding)
          else
            const SizedBox(),
          if (_controlsConfiguration.enablePip)
            _buildPipButton(
                backgroundColor, iconColor, barHeight, buttonPadding)
          else
            const SizedBox(),
          Expanded(child: Container()),
          if (_controlsConfiguration.enableMute)
            _buildMuteButton(_controller, backgroundColor, iconColor, barHeight,
                buttonPadding)
          else
            const SizedBox(),
          if (_controlsConfiguration.enableOverflowMenu)
            _buildMoreButton(
              _controller,
              backgroundColor,
              iconColor,
              barHeight,
              buttonPadding,
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int?>(
      stream: _betterPlayerController!.nextVideoTimeStreamController.stream,
      builder: (context, snapshot) {
        final time = snapshot.data;
        if (time != null && time > 0) {
          return InkWell(
            onTap: () {
              _betterPlayerController!.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 8),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "${_betterPlayerController!.translations.controlsNextVideoIn} $time ...",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    setState(() {
      _hideStuff = false;
      _startHideTimer();
    });
  }

  Future<void> _initialize() async {
    _controller!.addListener(_updateState);

    _updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      setState(() {
        _hideStuff = !state;
      });
      if (!_hideStuff) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      _betterPlayerController!.toggleFullScreen();
      _expandCollapseTimer = Timer(_controlsConfiguration.controlsHideTime, () {
        setState(() {
          cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: BetterPlayerCupertinoVideoProgressBar(
          _controller,
          _betterPlayerController,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor:
                  _controlsConfiguration.progressBarBackgroundColor),
        ),
      ),
    );
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }
    setState(() {
      if (_controller!.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        _betterPlayerController!.pause();
      } else {
        cancelAndRestartTimer();

        if (!_controller!.value.initialized) {
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
    });
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (mounted) {
      if (!_hideStuff ||
          isVideoFinished(_controller!.value) ||
          _wasLoading ||
          isLoading(_controller!.value)) {
        setState(() {
          _latestValue = _controller!.value;
          if (isVideoFinished(_latestValue)) {
            _hideStuff = false;
          }
        });
      }
    }
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!_hideStuff);
    widget.onControlsVisibilityChanged(!_hideStuff);
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context,
          _betterPlayerController!
              .videoPlayerController!.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return _controlsConfiguration.loadingWidget;
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }

  Widget _buildPipButton(Color backgroundColor, Color iconColor,
      double barHeight, double buttonPadding) {
    return FutureBuilder<bool>(
        future: _betterPlayerController!.isPictureInPictureSupported(),
        builder: (context, snapshot) {
          final isPipSupported = snapshot.data ?? false;
          if (isPipSupported &&
              _betterPlayerController!.betterPlayerGlobalKey != null) {
            return GestureDetector(
              onTap: () {
                betterPlayerController!.enablePictureInPicture(
                    betterPlayerController!.betterPlayerGlobalKey!);
              },
              child: AnimatedOpacity(
                opacity: _hideStuff ? 0.0 : 1.0,
                duration: _controlsConfiguration.controlsHideTime,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10),
                    child: Container(
                      height: barHeight,
                      padding: EdgeInsets.only(
                        left: buttonPadding,
                        right: buttonPadding,
                      ),
                      color: backgroundColor,
                      child: Center(
                        child: Icon(
                          _controlsConfiguration.pipMenuIcon,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox();
          }
        });
  }
}
