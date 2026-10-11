import 'dart:math';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/model/video_list_data.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_controller.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_widget.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ReusableVideoListPage extends StatefulWidget {
  const ReusableVideoListPage({super.key});

  @override
  _ReusableVideoListPageState createState() => _ReusableVideoListPageState();
}

class _ReusableVideoListPageState extends State<ReusableVideoListPage> {
  ReusableVideoListController videoListController =
      ReusableVideoListController();
  final _random = Random();
  final List<String> _videos = [
    Constants.forBiggerBlazesUrl,
    Constants.forBiggerJoyridesVideoUrl,
  ];
  List<VideoListData> dataList = [];
  int value = 0;
  final ScrollController _scrollController = ScrollController();
  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  bool _canBuildVideo = true;

  @override
  void initState() {
    _setupData();
    super.initState();
  }

  void _setupData() {
    for (var index = 0; index < 10; index++) {
      final randomVideoUrl = _videos[_random.nextInt(_videos.length)];
      dataList.add(VideoListData('Video $index', randomVideoUrl));
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
      appBar: AppBar(title: const Text('Reusable Video List Feed')),
      body: NotificationListener<ScrollNotification>(
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
          itemCount: dataList.length + 1,
          controller: _scrollController,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const DemoContainer(
                child: DemoHeader(
                  title: 'Reusable Video Player Feed',
                  description:
                      'Recycles a bounded pool of BetterPlayerControllers across '
                      'a scrolling list for peak memory efficiency.',
                  instructions:
                      'Scroll smoothly to observe controller reuse and fast cleanup.',
                  icon: Icons.recycling_outlined,
                ),
              );
            }
            final videoListData = dataList[index - 1];
            return DemoContainer(
              child: ReusableVideoListWidget(
                videoListData: videoListData,
                videoListController: videoListController,
                canBuildVideo: _checkCanBuildVideo,
              ),
            );
          },
        ),
      ),
    );
  }

  bool _checkCanBuildVideo() {
    return _canBuildVideo;
  }
}
