import 'dart:async';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';

class BetterPlayerCupertinoVideoProgressBar extends StatefulWidget {
  BetterPlayerCupertinoVideoProgressBar(
    this.controller,
    this.betterPlayerController, {
    BetterPlayerProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    Key? key,
  })  : colors = colors ?? BetterPlayerProgressColors(),
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

class _VideoProgressBarState
    extends State<BetterPlayerCupertinoVideoProgressBar> {
  _VideoProgressBarState() {
    listener = () {
      if (mounted) setState(() {});
    };
  }

  late VoidCallback listener;
  bool _controllerWasPlaying = false;

  VideoPlayerController? get controller => widget.controller;

  BetterPlayerController? get betterPlayerController =>
      widget.betterPlayerController;

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
    final bool enableProgressBarDrag = betterPlayerController!
        .betterPlayerControlsConfiguration.enableProgressBarDrag;
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
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              _getValue(),
              widget.colors,
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
  _ProgressBarPainter(this.value, this.colors);

  VideoPlayerValue value;
  BetterPlayerProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 5.0;
    const handleHeight = 6.0;
    final baseOffset = size.height / 2 - barHeight / 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    final double playedPartPercent =
        value.position.inMilliseconds / value.duration!.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration!) * size.width;
      final double end = range.endFraction(value.duration!) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    final shadowPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(playedPart, baseOffset + barHeight / 2),
          radius: handleHeight));

    canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}
