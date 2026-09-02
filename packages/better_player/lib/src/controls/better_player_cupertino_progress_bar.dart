import 'dart:async';

import 'package:better_player/src/controls/player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerCupertinoVideoProgressBar extends StatefulWidget {
  BetterPlayerCupertinoVideoProgressBar(
    this.betterPlayerController, {
    PlayerProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    super.key,
  }) : colors = colors ?? PlayerProgressColors();

  final BetterPlayerController? betterPlayerController;
  final PlayerProgressColors colors;
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

  

  BetterPlayerController? get betterPlayerController =>
      widget.betterPlayerController;

  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  @override
  void initState() {
    super.initState();
    betterPlayerController!.addVideoListener(listener);
  }

  @override
  void deactivate() {
    betterPlayerController!.removeVideoListener(listener);
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final controller = BetterPlayerController.of(context);
    final enableProgressBarDrag = betterPlayerController!
        .betterPlayerControlsConfiguration
        .enableProgressBarDrag;
    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (!betterPlayerController!.videoPlayerValue!.initialized || !enableProgressBarDrag) {
          return;
        }
        _controllerWasPlaying = betterPlayerController!.videoPlayerValue!.isPlaying;
        if (_controllerWasPlaying) {
          betterPlayerController!.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart!();
        }
      },
      onHorizontalDragUpdate: (details) {
        if (!betterPlayerController!.videoPlayerValue!.initialized || !enableProgressBarDrag) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!();
        }
      },
      onHorizontalDragEnd: (details) {
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
      onTapDown: (details) {
        if (!betterPlayerController!.videoPlayerValue!.initialized || !enableProgressBarDrag) {
          return;
        }

        seekToRelativePosition(details.globalPosition);
        _setupUpdateBlockTimer();
        if (widget.onTapDown != null) {
          widget.onTapDown!();
        }
      },
      child: Semantics(
        label: betterPlayerController!.translations.progressBarLabel,
        identifier: 'better_player_cupertino_progress_bar',
        value: _getSemanticsValue(),
        increasedValue: _getSemanticsValue(relative: 0.1),
        decreasedValue: _getSemanticsValue(relative: -0.1),
        container: true,
        slider: true,
        onIncrease: () {
          _seekRelative(0.1);
        },
        onDecrease: () {
          _seekRelative(-0.1);
        },
        child: Center(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.transparent,
            child: CustomPaint(
              painter: _ProgressBarPainter(_getValue(), widget.colors),
            ),
          ),
        ),
      ),
    );
  }

  String _getSemanticsValue({double relative = 0}) {
    final value = _getValue();
    if (!value.initialized) {
      return '0%';
    }
    final duration = value.duration?.inMilliseconds ?? 0;
    final position = value.position.inMilliseconds;
    if (duration == 0) {
      return '0%';
    }

    final currentPercent = position / duration;
    final targetPercent = (currentPercent + relative).clamp(0.0, 1.0);

    return '${(targetPercent * 100).round()}%';
  }

  void _seekRelative(double relative) {
    final duration = betterPlayerController!.videoPlayerValue!.duration;
    if (duration != null) {
      final position = betterPlayerController!.videoPlayerValue!.position;
      final newPosition = position + duration * relative;
      betterPlayerController?.seekTo(newPosition);
    }
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
      return betterPlayerController!.videoPlayerValue!.copyWith(position: lastSeek);
    } else {
      return betterPlayerController!.videoPlayerValue!;
    }
  }

  Future<void> seekToRelativePosition(Offset globalPosition) async {
    final renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final tapPos = box.globalToLocal(globalPosition);
      final relative = tapPos.dx / box.size.width;
      if (relative > 0) {
        final position = betterPlayerController!.videoPlayerValue!.duration! * relative;
        lastSeek = position;
        await betterPlayerController!.seekTo(position);
        onFinishedLastSeek();
        if (relative >= 1) {
          lastSeek = betterPlayerController!.videoPlayerValue!.duration;
          await betterPlayerController!.seekTo(betterPlayerController!.videoPlayerValue!.duration!);
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
  PlayerProgressColors colors;

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
          Offset(0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    final playedPartPercent =
        value.position.inMilliseconds / value.duration!.inMilliseconds;
    final playedPart = playedPartPercent > 1
        ? size.width
        : playedPartPercent * size.width;
    for (final range in value.buffered) {
      final start = range.startFraction(value.duration!) * size.width;
      final end = range.endFraction(value.duration!) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4),
      ),
      colors.playedPaint,
    );

    final shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(playedPart, baseOffset + barHeight / 2),
          radius: handleHeight,
        ),
      );

    canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}





