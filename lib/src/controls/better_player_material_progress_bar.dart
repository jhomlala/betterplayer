import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';

import '../core/better_player_utils.dart';

class BetterPlayerMaterialVideoProgressBar extends StatefulWidget {
  final bool isContentLive;

  BetterPlayerMaterialVideoProgressBar(
    this.controller,
    this.betterPlayerController, {
    BetterPlayerProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    Key? key,
  })
      : colors = colors ?? BetterPlayerProgressColors(),
        isContentLive = betterPlayerController?.isLiveStream() ?? false,
        super(key: key);

  final VideoPlayerController? controller;
  final BetterPlayerController? betterPlayerController;
  final BetterPlayerProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final Function()? onTapDown;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<BetterPlayerMaterialVideoProgressBar> {
  _VideoProgressBarState() {
    listener = () {
      if (mounted) setState(() {});
    };
  }

  late VoidCallback listener;
  bool _controllerWasPlaying = false;

  VideoPlayerController? get controller => widget.controller;

  BetterPlayerController? get betterPlayerController => widget.betterPlayerController;

  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  @override
  void initState() {
    super.initState();
    controller!.addListener(listener);
  }

  @override
  void deactivate() {
    controller!.removeListener(listener);
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final bool enableProgressBarDrag =
        betterPlayerController!.betterPlayerConfiguration.controlsConfiguration.enableProgressBarDrag;

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller!.value.initialized || !enableProgressBarDrag) {
          return;
        }

        _controllerWasPlaying = controller!.value.isPlaying;
        if (_controllerWasPlaying) {
          controller!.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart!();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller!.value.initialized || !enableProgressBarDrag) {
          return;
        }

        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (!enableProgressBarDrag) {
          return;
        }

        if (_controllerWasPlaying) {
          betterPlayerController?.play();
          shouldPlayAfterDragEnd = true;
        }
        _setupUpdateBlockTimer();

        if (widget.onDragEnd != null) {
          widget.onDragEnd!();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller!.value.initialized || !enableProgressBarDrag) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
        _setupUpdateBlockTimer();
        if (widget.onTapDown != null) {
          widget.onTapDown!();
        }
      },
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              _getValue(),
              widget.colors,
              widget.isContentLive,
            ),
          ),
        ),
      ),
    );
  }

  void _setupUpdateBlockTimer() {
    _updateBlockTimer = Timer(const Duration(milliseconds: 1000), () {
      lastSeek = null;
      _cancelUpdateBlockTimer();
    });
  }

  void _cancelUpdateBlockTimer() {
    _updateBlockTimer?.cancel();
    _updateBlockTimer = null;
  }

  VideoPlayerValue _getValue() {
    if (lastSeek != null) {
      return controller!.value.copyWith(position: lastSeek);
    } else {
      return controller!.value;
    }
  }

  void seekToRelativePosition(Offset globalPosition) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      if (relative > 0) {
        final Duration position = controller!.value.duration! * relative;
        lastSeek = position;
        await betterPlayerController!.seekTo(position);
        onFinishedLastSeek();
        if (relative >= 1) {
          lastSeek = controller!.value.duration;
          await betterPlayerController!.seekTo(controller!.value.duration!);
          onFinishedLastSeek();
        }
      }
    }
  }

  void onFinishedLastSeek() {
    if (shouldPlayAfterDragEnd) {
      shouldPlayAfterDragEnd = false;
      betterPlayerController?.play();
    }
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double _indicatorScaleFactor;
  final double _progressBarHeightPx;
  final double _progressBarCurrentTimeIndicatorPx;
  final double _roundRadius;

  final VideoPlayerValue _value;
  final BetterPlayerProgressColors _colors;
  final bool _isContentLive;

  _ProgressBarPainter(
    this._value,
    this._colors,
    this._isContentLive, {
    double progressBarHeightPx = 2,
    double indicatorScaleFactor = 3,
    double roundRadius = 4,
  })  : _indicatorScaleFactor = indicatorScaleFactor,
        _progressBarHeightPx = progressBarHeightPx,
        _progressBarCurrentTimeIndicatorPx = progressBarHeightPx * indicatorScaleFactor,
        _roundRadius = roundRadius;

  @override
  bool shouldRepaint(CustomPainter painter) => _value.initialized;

  @override
  void paint(Canvas canvas, Size size) {
    _drawProgressBarBackground(canvas, size);

    if (_isContentLive) {
      _drawLiveContent(canvas, size);
    } else {
      _drawNonLiveContent(canvas, size);
    }
  }

  void _drawProgressBarBackground(Canvas canvas, Size size) {
    _drawLinearProgressBar(
      canvas,
      _colors.backgroundPaint,
      0.0,
      size.height / 2,
      size.width,
      size.height / 2 + _progressBarHeightPx,
    );
  }

  void _drawLiveContent(Canvas canvas, Size size) {
    final double liveProgress = _getLiveContentProgress();
    BetterPlayerUtils.log("drawLiveContent, liveProgress: $liveProgress");

    final double indicatorPosition = size.width * liveProgress;

    _drawLinearProgressBar(
      canvas,
      _colors.playedPaint,
      indicatorPosition,
      size.height / 2,
      size.width,
      size.height / 2 + _progressBarHeightPx,
    );

    _drawProgressIndicator(
      canvas,
      _colors.handlePaint,
      Offset(indicatorPosition, size.height / 2 + _progressBarHeightPx / 2),
      _progressBarHeightPx * _indicatorScaleFactor,
    );
  }

  void _drawNonLiveContent(Canvas canvas, Size size) {
    double playedPartPercent = _value.position.inMilliseconds / _value.duration!.inMilliseconds;
    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }
    final double playedPart = playedPartPercent > 1 ? size.width : playedPartPercent * size.width;

    for (final DurationRange range in _value.buffered) {
      double start = range.startFraction(_value.duration!) * size.width;
      if (start.isNaN) {
        start = 0;
      }
      double end = range.endFraction(_value.duration!) * size.width;
      if (end.isNaN) {
        end = 0;
      }
      drawBufferedProgressBar(canvas, size, start, end);
    }

    _drawPlayedProgressBar(canvas, size, playedPart);
    _drawCurrentTimeIndicator(canvas, size, playedPart);
  }

  void _drawLinearProgressBar(Canvas canvas, Paint paint, double startX, double startY, double endX, double endY) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(startX, startY),
          Offset(endX, endY),
        ),
        Radius.circular(_roundRadius),
      ),
      paint,
    );
  }

  void _drawProgressIndicator(Canvas canvas, Paint paint, Offset center, double radius) {
    canvas.drawCircle(center, radius, paint);
  }

  void drawBufferedProgressBar(Canvas canvas, Size size, double start, double end) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(start, size.height / 2),
          Offset(end, size.height / 2 + _progressBarHeightPx),
        ),
        Radius.circular(_roundRadius),
      ),
      _colors.bufferedPaint,
    );
  }

  void _drawCurrentTimeIndicator(Canvas canvas, Size size, double playedPart) {
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + _progressBarHeightPx / 2),
      _progressBarCurrentTimeIndicatorPx,
      _colors.handlePaint,
    );
  }

  void _drawPlayedProgressBar(Canvas canvas, Size size, double playedPart) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + _progressBarHeightPx),
        ),
        Radius.circular(_roundRadius),
      ),
      _colors.playedPaint,
    );
  }

  //make sure that progress is not minus or more than 100%. This can only apply for live content.
  double _getLiveContentProgress() => (_value.position.inMilliseconds / _value.duration!.inMilliseconds).clamp(0, 1);
}
