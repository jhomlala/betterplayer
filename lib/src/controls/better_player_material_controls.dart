import 'dart:async';

import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BetterPlayerMaterialControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  BetterPlayerMaterialControls(
      {Key key, this.onControlsVisibilityChanged, this.controlsConfiguration})
      : assert(onControlsVisibilityChanged != null),
        assert(controlsConfiguration != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerMaterialControlsState();
  }
}

class _BetterPlayerMaterialControlsState
    extends State<BetterPlayerMaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  double _progressValue = 0;
  VideoPlayerController _controller;
  BetterPlayerController _betterPlayerController;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return _buildErrorWidget();
    }
    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: [
              _isLoading()
                  ? Expanded(child: Center(child: _buildLoadingWidget()))
                  : _buildHitArea(),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLoading() {
    return _latestValue != null &&
            !_latestValue.isPlaying &&
            _latestValue.duration == null ||
        _latestValue.isBuffering;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
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

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        height: _controlsConfiguration.controlBarHeight,
        color: _controlsConfiguration.controlBarColor,
        child: Row(
          children: [
            _controlsConfiguration.enablePlayPause
                ? _buildPlayPause(_controller)
                : const SizedBox(),
            _betterPlayerController.isLiveStream()
                ? _buildLiveWidget()
                : _controlsConfiguration.enableProgressText
                    ? _buildPosition()
                    : const SizedBox(),
            _betterPlayerController.isLiveStream()
                ? const SizedBox()
                : _controlsConfiguration.enableProgressBar
                    ? _buildProgressBar()
                    : const SizedBox(),
            _controlsConfiguration.enableMute
                ? _buildMuteButton(_controller)
                : const SizedBox(),
            _controlsConfiguration.enableFullscreen
                ? _buildExpandButton()
                : const SizedBox(),
          ],
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

  Widget _buildExpandButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: Container(
          height: _controlsConfiguration.controlBarHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: Icon(
              _betterPlayerController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: _controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    if (_isPlaylistChangingToNextVideo()) {
      return _buildPlaylistChangingWidget();
    }

    bool isFinished = _latestValue.position >= _latestValue.duration;
    IconData _hitAreaIconData = isFinished ? Icons.replay : Icons.play_arrow;

    return Expanded(
      child: BetterPlayerMaterialClickableWidget(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _onPlayPause();

            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: _controlsConfiguration.controlsHideTime,
              child: GestureDetector(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _controlsConfiguration.controlBarColor,
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Stack(
                            children: [
                              Icon(
                                _hitAreaIconData,
                                size: 32.0,
                                color: _controlsConfiguration.iconsColor,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    isFinished
                        ? Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 60,
                              width: 60,
                              child: CircularProgressIndicator(
                                value: _progressValue,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isPlaylistChangingToNextVideo() =>
      _betterPlayerController.betterPlayerPlaylistSettings != null &&
      _betterPlayerController.isDisposing;

  Widget _buildPlaylistChangingWidget() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingWidget(),
          Text(
            _controlsConfiguration.loadingNextVideoText,
            style: TextStyle(color: _controlsConfiguration.textColor),
          )
        ],
      ),
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        _cancelAndRestartTimer();
        if (_latestValue.volume == 0) {
          _betterPlayerController.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          _betterPlayerController.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRect(
          child: Container(
            child: Container(
              height: _controlsConfiguration.controlBarHeight,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? _controlsConfiguration.muteIcon
                    : _controlsConfiguration.unMuteIcon,
                color: _controlsConfiguration.iconsColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller) {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onPlayPause,
      child: Container(
        height: _controlsConfiguration.controlBarHeight,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          controller.value.isPlaying
              ? _controlsConfiguration.pauseIcon
              : _controlsConfiguration.playIcon,
          color: _controlsConfiguration.iconsColor,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 24),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14,
          color: _controlsConfiguration.textColor,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
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
      _showAfterExpandCollapseTimer =
          Timer(_controlsConfiguration.controlsHideTime, () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _onPlayPause() {
    if (_isPlaylistChangingToNextVideo()) {
      return;
    }

    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (_controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        _betterPlayerController.pause();
      } else {
        _cancelAndRestartTimer();

        if (!_controller.value.initialized) {
          _controller.initialize().then((_) {
            _betterPlayerController.play();
          });
        } else {
          if (isFinished) {
            _betterPlayerController.seekTo(Duration(seconds: 0));
          }
          _betterPlayerController.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = _controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 20),
        child: BetterPlayerMaterialVideoProgressBar(
          _controller,
          _betterPlayerController,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });
            _startHideTimer();
          },
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor:
                  _controlsConfiguration.progressBarBackgroundColor),
          isChangeAllowed: () {
            return !_isPlaylistChangingToNextVideo();
          },
        ),
      ),
    );
  }

  void _onPlayerHide() {
    widget.onControlsVisibilityChanged(!_hideStuff);
  }

  Widget _buildLoadingWidget() {
    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.controlBarColor),
    );
  }
}
