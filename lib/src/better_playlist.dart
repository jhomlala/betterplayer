import 'package:better_player/better_player.dart';
import 'package:better_player/src/better_player_event_type.dart';
import 'package:better_player/src/better_player_playlist_settings.dart';
import 'package:better_player/src/better_player_settings.dart';
import 'package:flutter/material.dart';

class BetterPlaylist extends StatefulWidget {
  final List<BetterPlayerDataSource> betterPlayerDataSourceList;
  final BetterPlayerSettings betterPlayerSettings;
  final BetterPlayerPlaylistSettings betterPlayerPlaylistSettings;

  BetterPlaylist(
      {Key key,
      this.betterPlayerDataSourceList,
      this.betterPlayerSettings,
      this.betterPlayerPlaylistSettings})
      : super(key: key);

  @override
  _BetterPlaylistState createState() => _BetterPlaylistState();
}

class _BetterPlaylistState extends State<BetterPlaylist> {
  BetterPlayerDataSource _currentSource;
  BetterPlayerController _controller;
  bool _changingToNextVideo = false;

  List<BetterPlayerDataSource> get _betterPlayerDataSourceList =>
      widget.betterPlayerDataSourceList;

  @override
  void initState() {
    super.initState();
    _currentSource = _getNextDateSource();
    _setupPlayer();
  }

  void _onVideoFinished() {
    print("Finished " + _controller.hashCode.toString());
    if (_changingToNextVideo) {
      return;
    }
    if (_controller.isFullScreen) {
      _controller.exitFullScreen();
    }
    _controller.isDisposing = true;
    _changingToNextVideo = true;
    BetterPlayerDataSource _nextDataSource = _getNextDateSource();
    if (_nextDataSource == null) {
      return;
    }

    Future.delayed(widget.betterPlayerPlaylistSettings.nextVideoDelay, () {
      _setupPlayer();
      setState(() {
        _currentSource = _nextDataSource;
      });
      print("Playing: $_currentSource");
      _changingToNextVideo = false;
    });
  }

  void _setupPlayer() {
    _controller = BetterPlayerController(widget.betterPlayerSettings,
        betterPlayerPlaylistSettings: widget.betterPlayerPlaylistSettings);
    _controller.addEventsListener((event) async {
      if (event.betterPlayerEventType == BetterPlayerEventType.FINISHED) {
        _onVideoFinished();
      }
    });
  }

  String _getKey() => _currentSource.hashCode.toString();

  BetterPlayerDataSource _getNextDateSource() {
    if (_currentSource == null) {
      return _betterPlayerDataSourceList.first;
    } else {
      int index = _betterPlayerDataSourceList.indexOf(_currentSource);
      if (index + 1 < _betterPlayerDataSourceList.length) {
        return _betterPlayerDataSourceList[index + 1];
      } else {
        if (widget.betterPlayerPlaylistSettings.loopVideos) {
          return _betterPlayerDataSourceList.first;
        } else {
          return null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterPlayer(
        key: Key(_getKey()),
        controller: _controller,
        betterPlayerDataSource: _currentSource);
  }
}
