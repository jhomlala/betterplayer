import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class PictureInPicturePage extends StatefulWidget {
  @override
  _PictureInPicturePageState createState() => _PictureInPicturePageState();
}

class _PictureInPicturePageState extends State<PictureInPicturePage>
    with WidgetsBindingObserver {
  late BetterPlayerController _betterPlayerController;
  late Function(BetterPlayerEvent) _betterPlayerListener;
  GlobalKey _betterPlayerKey = GlobalKey();
  late bool shouldStartPIP = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);

    _betterPlayerListener = (event) async {
      if (!mounted) {
        return;
      }

      if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        _betterPlayerController.setupAutomaticPictureInPictureTransition(
            willStartPIP: true);
        setState(() {
          shouldStartPIP = true;
        });
      } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
        _betterPlayerController.setupAutomaticPictureInPictureTransition(
            willStartPIP: false);
        setState(() {
          shouldStartPIP = false;
        });
      }
    };

    _betterPlayerController.addEventsListener(_betterPlayerListener);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _betterPlayerController.removeEventsListener(_betterPlayerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Picture in Picture player"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Example which shows how to use PiP.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(
              controller: _betterPlayerController,
              key: _betterPlayerKey,
            ),
          ),
          ElevatedButton(
            child: Text("Show PiP"),
            onPressed: () {
              _betterPlayerController.enablePictureInPicture(_betterPlayerKey);
            },
          ),
          ElevatedButton(
            child: Text("Disable PiP"),
            onPressed: () async {
              _betterPlayerController.disablePictureInPicture();
            },
          ),
          ElevatedButton(
            child: Text('Auto PIP: ' + (shouldStartPIP ? 'ON' : 'OFF')),
            onPressed: () async {
              setState(() {
                shouldStartPIP = !shouldStartPIP;
                _betterPlayerController
                    .setupAutomaticPictureInPictureTransition(
                        willStartPIP: shouldStartPIP);
              });
            },
          ),
        ],
      ),
    );
  }
}
