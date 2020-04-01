import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/video_list/video_list_data.dart';
import 'package:better_player_example/video_list/video_list_widget.dart';
import 'package:flutter/material.dart';

class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final _random = new Random();
  final List<String> _videos = [
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    //"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
   // "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
  ];
  List<VideoListData> dataList = List();

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
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        VideoListData videoListData = dataList[index];
        print("Video url: ${videoListData.videoUrl}");
        return VideoListWidget(videoListData: videoListData,);
      },
    );
  }


}
