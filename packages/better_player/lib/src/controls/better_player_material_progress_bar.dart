import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerMaterialVideoProgressBar extends StatefulWidget {
  BetterPlayerMaterialVideoProgressBar(
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
    extends State<BetterPlayerMaterialVideoProgressBar> {
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
    betterPlayerController?.addVideoListener(listener);
  }

  @override
  void deactivate() {
    betterPlayerController?.removeVideoListener(listener);
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final enableProgressBarDrag =
        betterPlayerController
            ?.betterPlayerControlsConfiguration
            .enableProgressBarDrag ??
        true;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        final videoPlayerValue = betterPlayerController?.videoPlayerValue;
        if (videoPlayerValue == null ||
            !videoPlayerValue.initialized ||
            !enableProgressBarDrag) {
          return;
        }

        _controllerWasPlaying = videoPlayerValue.isPlaying;
        if (_controllerWasPlaying) {
          betterPlayerController?.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart!();
        }
      },
      onHorizontalDragUpdate: (details) {
        final videoPlayerValue = betterPlayerController?.videoPlayerValue;
        if (videoPlayerValue == null ||
            !videoPlayerValue.initialized ||
            !enableProgressBarDrag) {
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
        final videoPlayerValue = betterPlayerController?.videoPlayerValue;
        if (videoPlayerValue == null ||
            !videoPlayerValue.initialized ||
            !enableProgressBarDrag) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
        _setupUpdateBlockTimer();
        if (widget.onTapDown != null) {
          widget.onTapDown!();
        }
      },
      child: Semantics(
        label:
            betterPlayerController?.translations.progressBarLabel ??
            'Video progress',
        identifier: 'better_player_material_progress_bar',
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
            height: MediaQuery.of(context).size.height / 2,
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
    final videoPlayerValue = betterPlayerController?.videoPlayerValue;
    final duration = videoPlayerValue?.duration;
    if (videoPlayerValue != null && duration != null) {
      final position = videoPlayerValue.position;
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
    final videoPlayerValue = betterPlayerController?.videoPlayerValue;
    if (videoPlayerValue == null) {
      return VideoPlayerValue.uninitialized();
    }
    if (lastSeek != null) {
      return videoPlayerValue.copyWith(
        position: lastSeek,
      );
    } else {
      return videoPlayerValue;
    }
  }

  Future<void> seekToRelativePosition(Offset globalPosition) async {
    final videoPlayerValue = betterPlayerController?.videoPlayerValue;
    final duration = videoPlayerValue?.duration;
    if (videoPlayerValue == null || duration == null) {
      return;
    }
    final renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final tapPos = box.globalToLocal(globalPosition);
      final relative = tapPos.dx / box.size.width;
      if (relative > 0) {
        final position = duration * relative;
        lastSeek = position;
        await betterPlayerController?.seekTo(position);
        onFinishedLastSeek();
        if (relative >= 1) {
          lastSeek = duration;
          await betterPlayerController?.seekTo(duration);
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
    const height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        const Radius.circular(4),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    var playedPartPercent =
        value.position.inMilliseconds / value.duration!.inMilliseconds;
    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }
    final playedPart = playedPartPercent > 1
        ? size.width
        : playedPartPercent * size.width;
    for (final range in value.buffered) {
      var start = range.startFraction(value.duration!) * size.width;
      if (start.isNaN) {
        start = 0;
      }
      var end = range.endFraction(value.duration!) * size.width;
      if (end.isNaN) {
        end = 0;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, size.height / 2),
            Offset(end, size.height / 2 + height),
          ),
          const Radius.circular(4),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        const Radius.circular(4),
      ),
      colors.playedPaint,
    );
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}
