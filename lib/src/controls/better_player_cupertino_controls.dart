import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

class BetterPlayerCupertinoControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerCupertinoControls({
    this.onControlsVisibilityChanged,
    this.controlsConfiguration,
  })  : assert(onControlsVisibilityChanged != null),
        assert(controlsConfiguration != null);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerCupertinoControlsState();
  }
}

class _BetterPlayerCupertinoControlsState
    extends State<BetterPlayerCupertinoControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  final marginSize = 5.0;
  Timer _expandCollapseTimer;
  Timer _initTimer;

  VideoPlayerController _controller;
  BetterPlayerController _betterPlayerController;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    _betterPlayerController = BetterPlayerController.of(context);

    if (_latestValue.hasError) {
      return _buildErrorWidget();
    }

    final backgroundColor = _controlsConfiguration.controlBarColor;
    final iconColor = _controlsConfiguration.iconsColor;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait
        ? _controlsConfiguration.controlBarHeight
        : _controlsConfiguration.controlBarHeight + 17;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () {
          _cancelAndRestartTimer();
        },
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              _buildTopBar(
                  backgroundColor, iconColor, barHeight, buttonPadding),
              _isLoading()
                  ? Expanded(child: Center(child: _buildLoadingWidget()))
                  : _buildHitArea(),
              _buildNextVideoWidget(),
              _buildBottomBar(backgroundColor, iconColor, barHeight),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLoading() {
    if (_latestValue != null) {
      if (!_latestValue.isPlaying &&
          _latestValue.duration == null &&
          !_betterPlayerController.betterPlayerDataSource.liveStream) {
        return true;
      }
      if (_latestValue.isPlaying && _latestValue.isBuffering) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController.videoPlayerController;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
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
              child: _betterPlayerController.isLiveStream()
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const SizedBox(width: 8),
                        _controlsConfiguration.enablePlayPause
                            ? _buildPlayPause(_controller, iconColor, barHeight)
                            : const SizedBox(),
                        const SizedBox(width: 8),
                        _buildLiveWidget(),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        _controlsConfiguration.enablePlayPause
                            ? _buildSkipBack(iconColor, barHeight)
                            : const SizedBox(),
                        _controlsConfiguration.enablePlayPause
                            ? _buildPlayPause(_controller, iconColor, barHeight)
                            : const SizedBox(),
                        _controlsConfiguration.enablePlayPause
                            ? _buildSkipForward(iconColor, barHeight)
                            : const SizedBox(),
                        _controlsConfiguration.enableProgressText
                            ? _buildPosition()
                            : const SizedBox(),
                        _controlsConfiguration.enableProgressBar
                            ? _buildProgressBar()
                            : const SizedBox(),
                        _controlsConfiguration.enableProgressText
                            ? _buildRemaining()
                            : const SizedBox()
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
        _controlsConfiguration.liveText,
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
                  _betterPlayerController.isFullScreen
                      ? _controlsConfiguration.fullscreenDisableIcon
                      : _controlsConfiguration.fullscreenEnableIcon,
                  color: iconColor,
                  size: 12.0,
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
        onTap: _latestValue != null && _latestValue.isPlaying
            ? () {
              if (_hideStuff == true) {
                _cancelAndRestartTimer();
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

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
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
                  (_latestValue != null && _latestValue.volume > 0)
                      ? _controlsConfiguration.muteIcon
                      : _controlsConfiguration.unMuteIcon,
                  color: iconColor,
                  size: 16.0,
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
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          controller.value.isPlaying
              ? _controlsConfiguration.pauseIcon
              : _controlsConfiguration.playIcon,
          color: iconColor,
          size: 16.0,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue.position : Duration(seconds: 0);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        formatDuration(position),
        style: TextStyle(
          color: _controlsConfiguration.textColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining() {
    final position = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration - _latestValue.position
        : Duration(seconds: 0);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '-${formatDuration(position)}',
        style:
            TextStyle(color: _controlsConfiguration.textColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewY(0.0)
            ..rotateX(math.pi)
            ..rotateZ(math.pi),
          child: Icon(
            _controlsConfiguration.skipBackIcon,
            color: iconColor,
            size: 12.0,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        margin: const EdgeInsets.only(right: 8.0),
        child: Icon(
          _controlsConfiguration.skipForwardIcon,
          color: iconColor,
          size: 12.0,
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
    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          _controlsConfiguration.enableFullscreen
              ? _buildExpandButton(
                  backgroundColor, iconColor, barHeight, buttonPadding)
              : Container(),
          Expanded(child: Container()),
          _controlsConfiguration.enableMute
              ? _buildMuteButton(_controller, backgroundColor, iconColor,
                  barHeight, buttonPadding)
              : Container(),
        ],
      ),
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int>(
      stream: _betterPlayerController.nextVideoTimeStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return InkWell(
            onTap: () {
              _betterPlayerController.playNextVideo();
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
                    "Next video in ${snapshot.data} ...",
                    style: TextStyle(color: Colors.white),
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

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      _hideStuff = false;

      _startHideTimer();
    });
  }

  Future<Null> _initialize() async {
    _controller.addListener(_updateState);

    _updateState();

    if ((_controller.value != null && _controller.value.isPlaying) ||
        _betterPlayerController.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      _betterPlayerController.toggleFullScreen();
      _expandCollapseTimer = Timer(_controlsConfiguration.controlsHideTime, () {
        setState(() {
          _cancelAndRestartTimer();
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

  void _playPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue.position >= _latestValue.duration;
    }

    setState(() {
      if (_controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        _betterPlayerController.pause();
      } else {
        _cancelAndRestartTimer();

        if (!_controller.value.initialized) {
          if (_betterPlayerController.betterPlayerDataSource.liveStream) {
            _betterPlayerController.play();
            _betterPlayerController.cancelNextVideoTimer();
          }
        } else {
          if (isFinished) {
            _betterPlayerController.seekTo(Duration(seconds: 0));
          }
          _betterPlayerController.play();
          _betterPlayerController.cancelNextVideoTimer();
        }
      }
    });
  }

  void _skipBack() {
    _cancelAndRestartTimer();
    final beginning = Duration(seconds: 0).inMilliseconds;
    final skip = (_latestValue.position - Duration(seconds: 15)).inMilliseconds;
    _controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestValue.duration.inMilliseconds;
    final skip = (_latestValue.position + Duration(seconds: 15)).inMilliseconds;
    _controller.seekTo(Duration(milliseconds: math.min(skip, end)));
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _latestValue = _controller.value;
      });
    }
  }

  void _onPlayerHide() {
    _betterPlayerController.toggleControlsVisibility(!_hideStuff);
    widget.onControlsVisibilityChanged(!_hideStuff);
  }

  Widget _buildErrorWidget() {
    if (_betterPlayerController.errorBuilder != null) {
      return _betterPlayerController.errorBuilder(context,
          _betterPlayerController.videoPlayerController.value.errorDescription);
    } else {
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
              _controlsConfiguration.defaultErrorText,
              style: TextStyle(color: _controlsConfiguration.textColor),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingWidget() {
    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.controlBarColor),
    );
  }
}
