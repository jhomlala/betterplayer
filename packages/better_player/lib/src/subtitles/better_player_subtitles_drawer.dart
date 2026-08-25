import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer_item.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerSubtitlesDrawer extends StatefulWidget {
  final List<BetterPlayerSubtitle> subtitles;
  final BetterPlayerController betterPlayerController;
  final BetterPlayerSubtitlesConfiguration? betterPlayerSubtitlesConfiguration;
  final Stream<bool> playerVisibilityStream;

  const BetterPlayerSubtitlesDrawer({
    required this.subtitles,
    required this.betterPlayerController,
    required this.playerVisibilityStream,
    super.key,
    this.betterPlayerSubtitlesConfiguration,
  });

  @override
  _BetterPlayerSubtitlesDrawerState createState() =>
      _BetterPlayerSubtitlesDrawerState();
}

class _BetterPlayerSubtitlesDrawerState
    extends State<BetterPlayerSubtitlesDrawer> {
  final RegExp htmlRegExp =
      // ignore: unnecessary_raw_strings
      RegExp(r'<[^>]*>', multiLine: true);
  late TextStyle _innerTextStyle;
  late TextStyle _outerTextStyle;

  VideoPlayerValue? _latestValue;
  BetterPlayerSubtitlesConfiguration? _configuration;
  bool _playerVisible = false;

  ///Stream used to detect if play controls are visible or not
  late StreamSubscription _visibilityStreamSubscription;

  @override
  void initState() {
    _visibilityStreamSubscription = widget.playerVisibilityStream.listen((
      state,
    ) {
      setState(() {
        _playerVisible = state;
      });
    });

    if (widget.betterPlayerSubtitlesConfiguration != null) {
      _configuration = widget.betterPlayerSubtitlesConfiguration;
    } else {
      _configuration = setupDefaultConfiguration();
    }

    widget.betterPlayerController.videoPlayerController!.addListener(
      _updateState,
    );

    _outerTextStyle = TextStyle(
      fontSize: _configuration!.fontSize,
      fontFamily: _configuration!.fontFamily,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _configuration!.outlineSize
        ..color = _configuration!.outlineColor,
    );

    _innerTextStyle = TextStyle(
      fontFamily: _configuration!.fontFamily,
      color: _configuration!.fontColor,
      fontSize: _configuration!.fontSize,
    );

    super.initState();
  }

  @override
  void dispose() {
    widget.betterPlayerController.videoPlayerController!.removeListener(
      _updateState,
    );
    _visibilityStreamSubscription.cancel();
    super.dispose();
  }

  ///Called when player state has changed, i.e. new player position, etc.
  void _updateState() {
    if (mounted) {
      setState(() {
        _latestValue =
            widget.betterPlayerController.videoPlayerController!.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _getSubtitleAtCurrentPosition();
    widget.betterPlayerController.renderedSubtitle = subtitle;
    final subtitles = subtitle?.texts ?? [];
    final textWidgets = subtitles.map((subtitleText) {
      return BetterPlayerSubtitlesDrawerItem(
        subtitleText: subtitleText,
        configuration: _configuration!,
        innerTextStyle: _innerTextStyle,
        outerTextStyle: _outerTextStyle,
      );
    }).toList();

    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: _playerVisible
              ? _configuration!.bottomPadding + 30
              : _configuration!.bottomPadding,
          left: _configuration!.leftPadding,
          right: _configuration!.rightPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: textWidgets,
        ),
      ),
    );
  }

  BetterPlayerSubtitle? _getSubtitleAtCurrentPosition() {
    if (_latestValue == null) {
      return null;
    }

    final position = _latestValue!.position;
    for (final subtitle in widget.betterPlayerController.subtitlesLines) {
      if (subtitle.start! <= position && subtitle.end! >= position) {
        return subtitle;
      }
    }
    return null;
  }

  BetterPlayerSubtitlesConfiguration setupDefaultConfiguration() {
    return const BetterPlayerSubtitlesConfiguration();
  }
}
