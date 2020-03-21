import 'dart:async';

import 'package:better_player/src/better_player_controller.dart';
import 'package:better_player/src/better_player_progress_colors.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_settings.dart';
import 'package:better_player/src/controls/material_progress_bar.dart';
import 'package:better_player/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  final Function(bool visbility) onControlsVisibilityChanged;
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const MaterialControls(
      {Key key, this.onControlsVisibilityChanged, this.controlsConfiguration})
      : assert(controlsConfiguration != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  double _progressValue = 0;

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  BetterPlayerController betterPlayerController;

  BetterPlayerControlsConfiguration get controlsConfiguration =>
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
            children: <Widget>[
              _latestValue != null &&
                          !_latestValue.isPlaying &&
                          _latestValue.duration == null ||
                      _latestValue.isBuffering
                  ? const Expanded(
                      child: const Center(
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : _buildHitArea(),
              _buildBottomBar(context),
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
    print("Dispose material controls $hashCode");
    controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = betterPlayerController;
    betterPlayerController = BetterPlayerController.of(context);
    controller = betterPlayerController.videoPlayerController;

    if (_oldController != betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildErrorWidget() {
    if (betterPlayerController.errorBuilder != null) {
      return betterPlayerController.errorBuilder(
        context,
        betterPlayerController.videoPlayerController.value.errorDescription,
      );
    } else {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          Icons.warning,
          color: controlsConfiguration.iconsColor,
          size: 42,
        ),
        Text(
          "Video can't be played",
          style: TextStyle(color: controlsConfiguration.textColor),
        ),
      ]));
    }
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        height: barHeight,
        color: controlsConfiguration.controlBarColor,
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            betterPlayerController.isLive
                ? Expanded(child: const Text('LIVE'))
                : controlsConfiguration.enableProgressText
                    ? _buildPosition(iconColor)
                    : const SizedBox(),
            betterPlayerController.isLive
                ? const SizedBox()
                : controlsConfiguration.enableProgressBar
                    ? _buildProgressBar()
                    : const SizedBox(),
            controlsConfiguration.enableMute
                ? _buildMuteButton(controller)
                : const SizedBox(),
            controlsConfiguration.enableFullscreen
                ? _buildExpandButton()
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return BetterPlayerClickableWidget(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: controlsConfiguration.controlsHideTime,
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              betterPlayerController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }

  bool _isPlaylistChangingToNextVideo() =>
      betterPlayerController.betterPlayerPlaylistSettings != null &&
      betterPlayerController.isDisposing;

  Widget _buildHitArea() {
    if (_isPlaylistChangingToNextVideo()) {
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(
                controlsConfiguration.controlBarColor),
          ),
          Text(
            "Loading next video",
            style: TextStyle(color: controlsConfiguration.textColor),
          )
        ]),
      );
    }
    bool isFinished = _latestValue.position >= _latestValue.duration;
    IconData _hitAreaIconData = isFinished ? Icons.replay : Icons.play_arrow;

    return Expanded(
      child: BetterPlayerClickableWidget(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _playPause();

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
              duration: controlsConfiguration.controlsHideTime,
              child: GestureDetector(
                child: Stack(children: [
                  Align(
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: controlsConfiguration.controlBarColor,
                          borderRadius: BorderRadius.circular(48.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Stack(children: [
                            Icon(
                              _hitAreaIconData,
                              size: 32.0,
                              color: controlsConfiguration.iconsColor,
                            )
                          ]),
                        ),
                      )),
                  isFinished
                      ? Align(
                          alignment: Alignment.center,
                          child: Container(
                              height: 60,
                              width: 60,
                              child: CircularProgressIndicator(
                                value: _progressValue,
                              )))
                      : const SizedBox(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return BetterPlayerClickableWidget(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          betterPlayerController.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          betterPlayerController.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: controlsConfiguration.controlsHideTime,
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? controlsConfiguration.muteIcon
                    : controlsConfiguration.unMuteIcon,
                color: controlsConfiguration.iconsColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller) {
    return BetterPlayerClickableWidget(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          controller.value.isPlaying
              ? controlsConfiguration.pauseIcon
              : controlsConfiguration.playIcon,
          color: controlsConfiguration.iconsColor,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14.0,
          color: controlsConfiguration.textColor,
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
    print("Initalize in: $hashCode");
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        betterPlayerController.autoPlay) {
      _startHideTimer();
    }

    if (betterPlayerController.showControlsOnInitialize) {
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

      betterPlayerController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(controlsConfiguration.controlsHideTime, () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        betterPlayerController.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            betterPlayerController.play();
          });
        } else {
          if (isFinished) {
            betterPlayerController.seekTo(Duration(seconds: 0));
          }
          betterPlayerController.play();
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
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: MaterialVideoProgressBar(
          controller,
          betterPlayerController,
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
          colors: betterPlayerController.materialProgressColors ??
              BetterPlayerProgressColors(
                  playedColor: controlsConfiguration.progressBarPlayedColor,
                  handleColor: controlsConfiguration.progressBarHandleColor,
                  bufferedColor: controlsConfiguration.progressBarBufferedColor,
                  backgroundColor:
                      controlsConfiguration.progressBarBackgroundColor),
        ),
      ),
    );
  }

  void _onPlayerHide() {
    print("Player hide $_hideStuff");
    widget.onControlsVisibilityChanged(!_hideStuff);
  }
}
