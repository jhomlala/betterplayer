import 'dart:io';

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
  late bool _shouldStartPIP = false;
  // Whether need to switch to PIP layout. Only used in Android.
  late bool _willSwitchToPIPLayout = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      handleLifecycle: false,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
      // notificationConfiguration: BetterPlayerNotificationConfiguration(
      //   showNotification: true,
      //   title: "Elephant dream",
      //   author: "Some author",
      //   imageUrl:
      //       "https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/African_Bush_Elephant.jpg/1200px-African_Bush_Elephant.jpg",
      //   activityName: "MainActivity",
      // ),
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
          _shouldStartPIP = true;
        });
      } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
        _betterPlayerController.setupAutomaticPictureInPictureTransition(
            willStartPIP: false);
        setState(() {
          _shouldStartPIP = false;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AppLifecycleState: ${state.toString()}');
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (Platform.isAndroid && _willSwitchToPIPLayout) {
          setState(() {
            _willSwitchToPIPLayout = false;
          });
        }
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        if (Platform.isAndroid && _shouldStartPIP) {
          setState(() {
            _willSwitchToPIPLayout = true;
          });
        }
        break;
      default:
        break;
    }
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
