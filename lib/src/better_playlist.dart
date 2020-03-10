import 'package:better_player/better_player.dart';
import 'package:better_player/src/better_player_event_type.dart';
import 'package:better_player/src/better_player_settings.dart';
import 'package:flutter/material.dart';

class BetterPlaylist extends StatefulWidget {
  final List<BetterPlayerDataSource> betterPlayerDataSourceList;
  final BetterPlayerSettings betterPlayerSettings;

  BetterPlaylist({Key key, this.betterPlayerDataSourceList, this.betterPlayerSettings})
      : super(key: key);

  @override
  _BetterPlaylistState createState() => _BetterPlaylistState();
}

class _BetterPlaylistState extends State<BetterPlaylist> {
  BetterPlayerDataSource _currentSource;
  BetterPlayerController _controller;

  List<BetterPlayerDataSource> get _betterPlayerDataSourceList =>
      widget.betterPlayerDataSourceList;

  @override
  void initState() {
    super.initState();
    _currentSource = _getNextDateSource();
    _setupPlayer();
  }

  void _onVideoFinished() {
    print("Finished" + _controller.hashCode.toString());
    Future.delayed(const Duration(milliseconds: 3000), () {
      _setupPlayer();
      setState(() {
        _currentSource = _getNextDateSource();
      });
      print("Playing: $_currentSource");
    });
  }

  void _setupPlayer() {
    _controller = BetterPlayerController(widget.betterPlayerSettings);
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
        return null;
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
