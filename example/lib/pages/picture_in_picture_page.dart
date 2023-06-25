import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class PictureInPicturePage extends StatefulWidget {
  @override
  _PictureInPicturePageState createState() => _PictureInPicturePageState();
}

class _PictureInPicturePageState extends State<PictureInPicturePage> {
  late BetterPlayerController _betterPlayerController;
  late Function(BetterPlayerEvent) _betterPlayerListener;
  GlobalKey _betterPlayerKey = GlobalKey();
  late bool _shouldStartPIP = false;
  // Whether need to switch to PIP layout. Only used in Android.
  late bool _willSwitchToPIPLayout = false;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      handleLifecycle: false,
      autoPlay: true,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
      notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: true,
          title: 'Text title',
          author: 'Test author',
          imageUrl: 'https://www.gstatic.com/webp/gallery/1.sm.jpg',
          notificationChannelName: "メディアコントロール用"),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);

    _betterPlayerListener = (event) async {
      if (!mounted) {
        return;
      }

      debugPrint(
          'betterPlayerEventType: ${event.betterPlayerEventType}, event.parameters: ${event.parameters.toString()}');

      if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        _betterPlayerController.setupAutomaticPictureInPictureTransition(
            willStartPIP: true);
        setState(() {
          _shouldStartPIP = true;
        });
      } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
        _betterPlayerController.setupAutomaticPictureInPictureTransition(
            willStartPIP: false);
        setState(() {
          _shouldStartPIP = false;
        });
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.enteringPIP) {
        _betterPlayerController.setControlsEnabled(false);
        setState(() {
          _willSwitchToPIPLayout = true;
        });
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.exitingPIP) {
        _betterPlayerController.setControlsEnabled(true);
        setState(() {
          _willSwitchToPIPLayout = false;
        });
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.tapExternalPlayButton) {
        _betterPlayerController.play();
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.tapExternalPauseButton) {
        _betterPlayerController.pause();
      }
    };

    _betterPlayerController.addEventsListener(_betterPlayerListener);
    super.initState();
  }

  @override
  void dispose() {
    _betterPlayerController.removeEventsListener(_betterPlayerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show on only BetterPlayerView for android.
    if (Platform.isAndroid && _willSwitchToPIPLayout) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(
          controller: _betterPlayerController,
          key: _betterPlayerKey,
        ),
      );
    }

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
          // Button for testing.
          ElevatedButton(
            child: Text('Auto PIP: ' + (_shouldStartPIP ? 'ON' : 'OFF')),
            onPressed: () async {
              setState(() {
                if (Platform.isAndroid) {
                  _shouldStartPIP = !_shouldStartPIP;
                }
                _betterPlayerController
                    .setupAutomaticPictureInPictureTransition(
                        willStartPIP: _shouldStartPIP);
              });
            },
          ),
        ],
      ),
    );
  }
}
