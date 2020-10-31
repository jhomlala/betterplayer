import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class BetterPlayerSubtitlesDrawer extends StatefulWidget {
  final List<BetterPlayerSubtitle> subtitles;
  final BetterPlayerController betterPlayerController;
  final BetterPlayerSubtitlesConfiguration betterPlayerSubtitlesConfiguration;
  final Stream<bool> playerVisibilityStream;

  const BetterPlayerSubtitlesDrawer({
    Key key,
    this.subtitles,
    this.betterPlayerController,
    this.betterPlayerSubtitlesConfiguration,
    this.playerVisibilityStream,
  })  : assert(subtitles != null),
        assert(betterPlayerController != null),
        assert(playerVisibilityStream != null),
        super(key: key);

  @override
  _BetterPlayerSubtitlesDrawerState createState() =>
      _BetterPlayerSubtitlesDrawerState();
}

class _BetterPlayerSubtitlesDrawerState
    extends State<BetterPlayerSubtitlesDrawer> {
  final RegExp htmlRegExp =
      RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  TextStyle _innerTextStyle;
  TextStyle _outerTextStyle;

  VideoPlayerValue _latestValue;
  BetterPlayerSubtitlesConfiguration _configuration;
  bool _playerVisible = false;

  ///Stream used to detect if play controls are visible or not
  StreamSubscription _visibilityStreamSubscription;

  @override
  void initState() {
    _visibilityStreamSubscription =
        widget.playerVisibilityStream.listen((state) {
      setState(() {
        _playerVisible = state;
      });
    });

    if (widget.betterPlayerSubtitlesConfiguration != null) {
      _configuration = widget.betterPlayerSubtitlesConfiguration;
    } else {
      _configuration = setupDefaultConfiguration();
    }

    widget.betterPlayerController.videoPlayerController
        .addListener(_updateState);

    _outerTextStyle = TextStyle(
        fontSize: _configuration.fontSize,
        fontFamily: _configuration.fontFamily,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _configuration.outlineSize
          ..color = _configuration.outlineColor);

    _innerTextStyle = TextStyle(
        fontFamily: _configuration.fontFamily,
        color: _configuration.fontColor,
        fontSize: _configuration.fontSize);

    super.initState();
  }

  @override
  void dispose() {
    widget.betterPlayerController.videoPlayerController
        .removeListener(_updateState);
    _visibilityStreamSubscription.cancel();
    super.dispose();
  }

  ///Called when player state has changed, i.e. new player position, etc.
  void _updateState() {
    if (mounted) {
      setState(() {
        _latestValue =
            widget.betterPlayerController.videoPlayerController.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> subtitles = _getSubtitlesAtCurrentPosition();
    List<Widget> textWidgets =
        subtitles.map((text) => _buildSubtitleTextWidget(text)).toList();

    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: _playerVisible
                ? _configuration.bottomPadding + 30
                : _configuration.bottomPadding,
            left: _configuration.leftPadding,
            right: _configuration.rightPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: textWidgets,
        ),
      ),
    );
  }

  List<String> _getSubtitlesAtCurrentPosition() {
    if (_latestValue == null) {
      return List();
    }
    Duration position = _latestValue.position;
    for (BetterPlayerSubtitle subtitle
        in widget.betterPlayerController.subtitlesLines) {
      if (subtitle.start <= position && subtitle.end >= position) {
        return subtitle.texts;
      }
    }
    return List();
  }

  Widget _buildSubtitleTextWidget(String subtitleText) {
    return Row(children: [
      Expanded(
        child: Align(
          child: _getTextWithStroke(subtitleText),
          alignment: _configuration.alignment ?? Alignment.center,
        ),
      ),
    ]);
  }

  Widget _getTextWithStroke(String subtitleText) {
    if (subtitleText == null) {
      subtitleText = "";
    }
    return Container(
      color: _configuration.backgroundColor ?? Colors.transparent,
      child: Stack(
        children: [
          _configuration.outlineEnabled
              ? _buildHtmlWidget(subtitleText, _outerTextStyle)
              : const SizedBox(),
          _buildHtmlWidget(subtitleText, _innerTextStyle)
        ],
      ),
    );
  }

  Widget _buildHtmlWidget(String text, TextStyle textStyle) {
    assert(text != null);
    assert(textStyle != null);
    return HtmlWidget(
      text,
      textStyle: textStyle,
    );
  }

  BetterPlayerSubtitlesConfiguration setupDefaultConfiguration() {
    return BetterPlayerSubtitlesConfiguration();
  }
}
