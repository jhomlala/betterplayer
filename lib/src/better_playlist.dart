import 'package:better_player/better_player.dart';
import 'package:better_player/src/better_player_event_type.dart';
import 'package:flutter/material.dart';

class BetterPlaylist extends StatefulWidget {
  final List<BetterPlayerDataSource> betterPlayerDataSource;
  final BetterPlayerController controller;

  BetterPlaylist({Key key, this.betterPlayerDataSource, this.controller})
      : super(key: key);

  @override
  _BetterPlaylistState createState() => _BetterPlaylistState();
}

class _BetterPlaylistState extends State<BetterPlaylist> {
  BetterPlayerDataSource _currentSource;
  BetterPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.betterPlayerDataSource.first;
    _setupNewController();
  }

  void _setupNewController() {
    _controller = BetterPlayerController(
        autoPlay: false, autoInitialize: true, allowFullScreen: true);
    //_controller.setup(_currentSource);
    _controller.addEventsListener((event) async {
      if (event.betterPlayerEventType == BetterPlayerEventType.FINISHED) {
        _onVideoFinished();
      }
    });
  }

  void _onVideoFinished() {
    print("FINISHED!!!" + _controller.hashCode.toString());
    Future.delayed(const Duration(milliseconds: 3000), () {
      _controller = BetterPlayerController(
          autoPlay: false, autoInitialize: true, allowFullScreen: true);
      setState(() {
        _currentSource = widget.betterPlayerDataSource[1];
      });
      print("Playing: $_currentSource");
    });
  }

  @override
  Widget build(BuildContext context) {
    print(">>>>BUILD<<<<");
    if (_controller == null) {
      return Text("Loading...");
    }
    return BetterPlayer(
        key: Key(_currentSource.hashCode.toString()),
        controller: _controller,
        betterPlayerDataSource: _currentSource);
  }
}
