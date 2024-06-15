import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:example/model/video_list_data.dart';
import 'package:example/pages/reusable_video_list/reusable_video_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReusableVideoListWidget extends StatefulWidget {
  const ReusableVideoListWidget({
    super.key,
    this.videoListData,
    this.videoListController,
    this.canBuildVideo,
  });

  final VideoListData? videoListData;
  final ReusableVideoListController? videoListController;
  final Function? canBuildVideo;

  @override
  _ReusableVideoListWidgetState createState() =>
      _ReusableVideoListWidgetState();
}

class _ReusableVideoListWidgetState extends State<ReusableVideoListWidget> {
  VideoListData? get videoListData => widget.videoListData;
  BetterPlayerController? controller;
  StreamController<BetterPlayerController?>
      betterPlayerControllerStreamController = StreamController.broadcast();
  bool _initialized = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    betterPlayerControllerStreamController.close();
    super.dispose();
  }

  void _setupController() {
    if (controller == null) {
      controller = widget.videoListController!.getBetterPlayerController();
      if (controller != null) {
        controller!.setupDataSource(
          BetterPlayerDataSource.network(
            videoListData!.videoUrl,
            cacheConfiguration:
                const BetterPlayerCacheConfiguration(useCache: true),
          ),
        );
        if (!betterPlayerControllerStreamController.isClosed) {
          betterPlayerControllerStreamController.add(controller);
        }
        controller!.addEventsListener(onPlayerEvent);
      }
    }
  }

  void _freeController() {
    if (!_initialized) {
      _initialized = true;
      return;
    }
    if (controller != null && _initialized) {
      controller!.removeEventsListener(onPlayerEvent);
      widget.videoListController!.freeBetterPlayerController(controller);
      controller!.pause();
      controller = null;
      if (!betterPlayerControllerStreamController.isClosed) {
        betterPlayerControllerStreamController.add(null);
      }
      _initialized = false;
    }
  }

  void onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      videoListData!.lastPosition = event.parameters!['progress'] as Duration?;
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      if (videoListData!.lastPosition != null) {
        controller!.seekTo(videoListData!.lastPosition!);
      }
      if (videoListData!.wasPlaying!) {
        controller!.play();
      }
    }
  }

  ///TODO: Handle "setState() or markNeedsBuild() called during build." error
  ///when fast scrolling through the list
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              videoListData!.videoTitle,
              style: const TextStyle(fontSize: 50),
            ),
          ),
          VisibilityDetector(
            key: Key(hashCode.toString() + DateTime.now().toString()),
            onVisibilityChanged: (info) {
              if (!widget.canBuildVideo()) {
                _timer?.cancel();
                _timer = null;
                _timer = Timer(const Duration(milliseconds: 500), () {
                  if (info.visibleFraction >= 0.6) {
                    _setupController();
                  } else {
                    _freeController();
                  }
                });
                return;
              }
              if (info.visibleFraction >= 0.6) {
                _setupController();
              } else {
                _freeController();
              }
            },
            child: StreamBuilder<BetterPlayerController?>(
              stream: betterPlayerControllerStreamController.stream,
              builder: (context, snapshot) {
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: controller != null
                      ? BetterPlayer(
                          controller: controller!,
                        )
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
                "Horror: In Steven Spielberg's Jaws, a shark terrorizes a beach "
                'town. Plainspoken sheriff Roy Scheider, hippie shark '
                'researcher Richard Dreyfuss, and a squirrely boat captain '
                'set out to find the beast, but will they escape with their '
                "lives? 70's special effects, legendary score, and trademark "
                'humor set this classic apart.'),
          ),
          Center(
            child: Wrap(
              children: [
                ElevatedButton(
                  child: const Text('Play'),
                  onPressed: () {
                    controller!.play();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Pause'),
                  onPressed: () {
                    controller!.pause();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Set max volume'),
                  onPressed: () {
                    controller!.setVolume(1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    if (controller != null) {
      videoListData!.wasPlaying = controller!.isPlaying();
    }
    _initialized = true;
    super.deactivate();
  }
}
