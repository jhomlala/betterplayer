import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BetterPlayerSubtitlesDrawer extends StatefulWidget {
  final List<BetterPlayerSubtitle> subtitles;
  final BetterPlayerController betterPlayerController;
  final BetterPlayerSubtitlesConfiguration betterPlayerSubtitlesConfiguration;

  const BetterPlayerSubtitlesDrawer(
      {Key key,
      this.subtitles,
      this.betterPlayerController,
      this.betterPlayerSubtitlesConfiguration})
      : super(key: key);

  @override
  _BetterPlayerSubtitlesDrawerState createState() =>
      _BetterPlayerSubtitlesDrawerState();
}

class _BetterPlayerSubtitlesDrawerState
    extends State<BetterPlayerSubtitlesDrawer> {
  VideoPlayerValue _latestValue;

  @override
  void initState() {
    print("Got subtitles: " + widget.subtitles.length.toString());
    widget.betterPlayerController.videoPlayerController
        .addListener(_updateState);
    super.initState();
  }

  @override
  void dispose() {
    widget.betterPlayerController.videoPlayerController
        .removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _latestValue = widget.betterPlayerController.videoPlayerController.value;
      print("Update state ${_latestValue.position}");
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> subtitles = _getSubtitlesAtCurrentPosition();
    List<Widget> textWidgets = subtitles
        .map(
          (text) => Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        )
        .toList();

    return Column(
      children: [
        Expanded(child: Container()),
        Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: Column(children: textWidgets))
      ],
    );
  }

  List<String> _getSubtitlesAtCurrentPosition() {
    Duration position = _latestValue.position;
    for (BetterPlayerSubtitle subtitle in widget.subtitles) {
      if (subtitle.start <= position && subtitle.end >= position) {
        return subtitle.texts;
      }
    }

    return [];
  }
}
