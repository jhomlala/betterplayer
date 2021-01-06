import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/model/video_list_data.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

class ReusableVideoListWidget extends StatefulWidget {
  final VideoListData videoListData;
  final ReusableVideoListController videoListController;

  const ReusableVideoListWidget({
    Key key,
    this.videoListData,
    this.videoListController,
  }) : super(key: key);

  @override
  _ReusableVideoListWidgetState createState() =>
      _ReusableVideoListWidgetState();
}

class _ReusableVideoListWidgetState extends State<ReusableVideoListWidget> {
  VideoListData get videoListData => widget.videoListData;
  BetterPlayerController controller;
  StreamController<BetterPlayerController>
      betterPlayerControllerStreamController = StreamController.broadcast();
  bool _initialized = false;
  bool _wasPlaying = false;
  Duration _lastPosition;
  bool _afterBuild = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _afterBuild = true;
    });
  }

  @override
  void dispose() {
    betterPlayerControllerStreamController.close();
    super.dispose();
  }

  void _setupController() {
    if (controller == null) {
      controller = widget.videoListController.getBetterPlayerController();
      controller.setupDataSource(
          BetterPlayerDataSource.network(videoListData.videoUrl));
      betterPlayerControllerStreamController.add(controller);
      controller.addEventsListener(onPlayerEvent);
    }
  }

  void _freeController() {
    if (!_initialized) {
      _initialized = true;
      return;
    }
    if (controller != null && _initialized) {
      _afterBuild = false;
      controller.removeEventsListener(onPlayerEvent);
      _wasPlaying = controller.isPlaying();
      _lastPosition = controller.videoPlayerController.value.position;
      widget.videoListController.freeBetterPlayerController(controller);
      controller.pause();
      controller = null;
      betterPlayerControllerStreamController.add(null);
      _initialized = false;
    }
  }

  void onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      if (_lastPosition != null) {
        controller.seekTo(_lastPosition);
      }
      if (_wasPlaying) {
        controller.play();
      }
    }
  }

  ///TODO: Handle "setState() or markNeedsBuild() called during build." error
  ///when fast scrolling through the list
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              videoListData.videoTitle,
              style: TextStyle(fontSize: 50),
            ),
          ),
          VisibilityDetector(
            key: Key(hashCode.toString() + DateTime.now().toString()),
            onVisibilityChanged: (info) {
              if (!_afterBuild) {
                return;
              }
              if (info.visibleFraction >= 0.8) {
                _setupController();
              } else {
                _freeController();
              }
            },
            child: StreamBuilder<BetterPlayerController>(
              stream: betterPlayerControllerStreamController.stream,
              builder: (context, snapshot) {
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: controller != null
                      ? BetterPlayer(
                          controller: controller,
                        )
                      : Container(),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
                "Horror: In Steven Spielberg's Jaws, a shark terrorizes a beach "
                "town. Plainspoken sheriff Roy Scheider, hippie shark "
                "researcher Richard Dreyfuss, and a squirrely boat captain "
                "set out to find the beast, but will they escape with their "
                "lives? 70's special effects, legendary score, and trademark "
                "humor set this classic apart."),
          ),
          Center(
            child: Wrap(children: [
              RaisedButton(
                child: Text("Play"),
                onPressed: () {
                  controller.play();
                },
              ),
              const SizedBox(width: 8),
              RaisedButton(
                child: Text("Pause"),
                onPressed: () {
                  controller.pause();
                },
              ),
              const SizedBox(width: 8),
              RaisedButton(
                child: Text("Set max volume"),
                onPressed: () {
                  controller.setVolume(100);
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    _initialized = true;
    _freeController();
    super.deactivate();
  }
}
