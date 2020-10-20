import 'dart:async';

import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

import 'better_player_clickable_widget.dart';

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
    extends BetterPlayerControlsState<BetterPlayerMaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
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
        onTap: _cancelAndRestartTimer,
        onDoubleTap: () {
          _cancelAndRestartTimer();
          _onPlayPause();
        },
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: [
              _buildTopBar(),
              isLoading(_latestValue)
                  ? Expanded(child: Center(child: _buildLoadingWidget()))
                  : _buildHitArea(),
              _buildBottomBar(),
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
              _betterPlayerController.translations.generalDefaultError,
              style: TextStyle(color: _controlsConfiguration.textColor),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTopBar() {
    return _controlsConfiguration.enableOverflowMenu
        ? AnimatedOpacity(
            opacity: _hideStuff ? 0.0 : 1.0,
            duration: _controlsConfiguration.controlsHideTime,
            onEnd: _onPlayerHide,
            child: Container(
              height: _controlsConfiguration.controlBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildMoreButton(),
                ],
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildMoreButton() {
    return BetterPlayerMaterialClickableWidget(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          _controlsConfiguration.overflowMenuIcon,
          color: _controlsConfiguration.iconsColor,
        ),
      ),
      onTap: () {
        onShowMoreClicked();
      },
    );
  }

  AnimatedOpacity _buildBottomBar() {
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
        _betterPlayerController.translations.controlsLive,
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
    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity:
                _latestValue != null && !_latestValue.isPlaying && !_dragging
                    ? 1.0
                    : 0.0,
            duration: _controlsConfiguration.controlsHideTime,
            child: Stack(
              children: [
                _buildPlayReplayButton(),
                _buildNextVideoWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayReplayButton() {
    bool isFinished = _latestValue?.position != null &&
        _latestValue?.duration != null &&
        _latestValue.position >= _latestValue.duration;
    IconData _hitAreaIconData = isFinished ? Icons.replay : Icons.play_arrow;
    return BetterPlayerMaterialClickableWidget(
      child: Align(
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
                  size: 32,
                  color: _controlsConfiguration.iconsColor,
                )
              ],
            ),
          ),
        ),
      ),
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
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int>(
      stream: _betterPlayerController.nextVideoTimeStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return BetterPlayerMaterialClickableWidget(
            onTap: () {
              _betterPlayerController.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 4),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "${_betterPlayerController.translations.controlsNextVideoIn} ${snapshot.data} ...",
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
        '${BetterPlayerUtils.formatDuration(position)} / ${BetterPlayerUtils.formatDuration(duration)}',
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

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (this.mounted) {
      setState(() {
        _latestValue = _controller.value;
      });
    }
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
        ),
      ),
    );
  }

  void _onPlayerHide() {
    _betterPlayerController.toggleControlsVisibility(!_hideStuff);
    widget.onControlsVisibilityChanged(!_hideStuff);
  }

  Widget _buildLoadingWidget() {
    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.controlBarColor),
    );
  }

  @override
  BetterPlayerController getBetterPlayerController() => _betterPlayerController;
}
