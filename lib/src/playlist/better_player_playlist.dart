// Dart imports:
import 'dart:async';

// Project imports:
import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_configuration.dart';
import 'package:better_player/src/configuration/better_player_data_source.dart';
import 'package:better_player/src/configuration/better_player_event_type.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/playlist/better_player_playlist_configuration.dart';
// Flutter imports:
import 'package:flutter/material.dart';

class BetterPlayerPlaylist extends StatefulWidget {
  final List<BetterPlayerDataSource> betterPlayerDataSourceList;
  final BetterPlayerConfiguration betterPlayerConfiguration;
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;

  const BetterPlayerPlaylist({
    Key key,
    @required this.betterPlayerDataSourceList,
    @required this.betterPlayerConfiguration,
    @required this.betterPlayerPlaylistConfiguration,
  })  : assert(betterPlayerDataSourceList != null,
            "BetterPlayerDataSourceList can't be null or empty"),
        assert(betterPlayerConfiguration != null,
            "BetterPlayerConfiguration can't be null"),
        assert(betterPlayerPlaylistConfiguration != null,
            "BetterPlayerPlaylistConfiguration can't be null"),
        super(key: key);

  @override
  BetterPlayerPlaylistState createState() => BetterPlayerPlaylistState();
}

class BetterPlayerPlaylistState extends State<BetterPlayerPlaylist> {
  BetterPlayerDataSource _currentSource;
  BetterPlayerController _controller;
  bool _changingToNextVideo = false;

  List<BetterPlayerDataSource> get _betterPlayerDataSourceList =>
      widget.betterPlayerDataSourceList;
  StreamSubscription _nextVideoTimeStreamSubscription;

  @override
  void initState() {
    super.initState();
    _currentSource = _getNextDateSource();
    _setupPlayer();
    _registerListeners();
  }

  void _registerListeners() {
    _nextVideoTimeStreamSubscription =
        _controller.nextVideoTimeStreamController.stream.listen((data) {
      if (data == 0) {
        _onVideoChange();
      }
    });
  }

  void _onVideoChange() {
    if (_changingToNextVideo) {
      return;
    }
    if (_controller.isFullScreen) {
      _controller.exitFullScreen();
    }
    _changingToNextVideo = true;
    final BetterPlayerDataSource _nextDataSource = _getNextDateSource();

    if (_nextDataSource == null) {
      return;
    }

    setState(() {
      _currentSource = _nextDataSource;
    });
    _setupNextDataSource();
    _changingToNextVideo = false;
  }

  void _setupPlayer() {
    _controller = BetterPlayerController(widget.betterPlayerConfiguration,
        betterPlayerPlaylistConfiguration:
            widget.betterPlayerPlaylistConfiguration,
        betterPlayerDataSource: _currentSource);

    _controller.addEventsListener((event) async {
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        _controller.startNextVideoTimer();
      }
    });
    _controller.addListener(_onStateChanged);
  }

  void _setupNextDataSource() async {
    _controller.setupDataSource(_currentSource);
  }

  String _getKey() => _controller.hashCode.toString();

  BetterPlayerDataSource _getNextDateSource() {
    if (_currentSource == null) {
      return _betterPlayerDataSourceList.first;
    } else {
      final int index = _betterPlayerDataSourceList.indexOf(_currentSource);
      if (index + 1 < _betterPlayerDataSourceList.length) {
        return _betterPlayerDataSourceList[index + 1];
      } else {
        if (widget.betterPlayerPlaylistConfiguration.loopVideos) {
          return _betterPlayerDataSourceList.first;
        } else {
          return null;
        }
      }
    }
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller.getAspectRatio() ??
          BetterPlayerUtils.calculateAspectRatio(context),
      child: BetterPlayer(
        key: Key(_getKey()),
        controller: _controller,
      ),
    );
  }

  @override
  void dispose() {
    _nextVideoTimeStreamSubscription.cancel();
    super.dispose();
  }

  ///Get currently used source in playlist
  BetterPlayerDataSource get currentSource => _currentSource;

  ///Get [BetterPlayerController] instance used in playlist
  BetterPlayerController get betterPlayerController => _controller;
}
