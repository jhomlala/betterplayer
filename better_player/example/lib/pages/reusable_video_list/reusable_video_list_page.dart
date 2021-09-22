import 'dart:math';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/model/video_list_data.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_controller.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_widget.dart';
import 'package:flutter/material.dart';

class ReusableVideoListPage extends StatefulWidget {
  @override
  _ReusableVideoListPageState createState() => _ReusableVideoListPageState();
}

class _ReusableVideoListPageState extends State<ReusableVideoListPage> {
  ReusableVideoListController videoListController =
      ReusableVideoListController();
  final _random = new Random();
  final List<String> _videos = [
    Constants.forBiggerBlazesUrl,
    Constants.forBiggerJoyridesVideoUrl,
  ];
  List<VideoListData> dataList = [];
  var value = 0;
  final ScrollController _scrollController = ScrollController();
  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  bool _canBuildVideo = true;

  @override
  void initState() {
    _setupData();
    super.initState();
  }

  void _setupData() {
    for (int index = 0; index < 10; index++) {
      var randomVideoUrl = _videos[_random.nextInt(_videos.length)];
      dataList.add(VideoListData("Video $index", randomVideoUrl));
    }
  }

  @override
  void dispose() {
    videoListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reusable video list")),
      body: Container(
        color: Colors.grey,
        child: Column(children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final now = DateTime.now();
                final timeDiff = now.millisecondsSinceEpoch - lastMilli;
                if (notification is ScrollUpdateNotification) {
                  final pixelsPerMilli = notification.scrollDelta! / timeDiff;
                  if (pixelsPerMilli.abs() > 1) {
                    _canBuildVideo = false;
                  } else {
                    _canBuildVideo = true;
                  }
                  lastMilli = DateTime.now().millisecondsSinceEpoch;
                }

                if (notification is ScrollEndNotification) {
                  _canBuildVideo = true;
                  lastMilli = DateTime.now().millisecondsSinceEpoch;
                }

                return true;
              },
              child: ListView.builder(
                itemCount: dataList.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  VideoListData videoListData = dataList[index];
                  return ReusableVideoListWidget(
                    videoListData: videoListData,
                    videoListController: videoListController,
                    canBuildVideo: _checkCanBuildVideo,
                  );
                },
              ),
            ),
          )
        ]),
      ),
    );
  }

  bool _checkCanBuildVideo() {
    return _canBuildVideo;
  }
}
