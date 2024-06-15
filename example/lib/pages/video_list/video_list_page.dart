import 'dart:math';

import 'package:example/constants.dart';
import 'package:example/model/video_list_data.dart';
import 'package:flutter/material.dart';

import 'video_list_widget.dart';

class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final _random = new Random();
  final List<String> _videos = [
    Constants.bugBuckBunnyVideoUrl,
    Constants.forBiggerBlazesUrl,
    Constants.forBiggerJoyridesVideoUrl,
    Constants.elephantDreamVideoUrl,
  ];
  List<VideoListData> dataList = [];
  var value = 0;

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
    return Scaffold(
      appBar: AppBar(title: Text("Video in list")),
      body: Container(
        color: Colors.grey,
        child: Column(children: [
          TextButton(
            child: Text("Update page state"),
            onPressed: () {
              setState(() {
                value++;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                VideoListData videoListData = dataList[index];
                return VideoListWidget(
                  videoListData: videoListData,
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}
