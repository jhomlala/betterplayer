// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:math';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/model/video_list_data.dart';
import 'package:better_player_example/pages/better_player_feed_page.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_page.dart';
import 'package:better_player_example/pages/video_list/video_list_widget.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

/// Legacy scrollable video list page demonstrating BetterPlayerListVideoPlayer.
///
/// Deprecated: use [BetterPlayerFeedPage] for full-screen swipe feeds
/// or [ReusableVideoListPage] for scrollable list controller pooling.
@Deprecated(
  'Use BetterPlayerFeedPage or ReusableVideoListPage instead. '
  'BetterPlayerListVideoPlayer does not recycle native decoders and causes OOM.',
)
class VideoListPage extends StatefulWidget {
  /// Deprecated: use [BetterPlayerFeedPage] or [ReusableVideoListPage].
  @Deprecated(
    'Use BetterPlayerFeedPage or ReusableVideoListPage instead.',
  )
  const VideoListPage({super.key});

  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final _random = Random();
  final List<String> _videos = [
    Constants.bugBuckBunnyVideoUrl,
    Constants.forBiggerBlazesUrl,
    Constants.forBiggerJoyridesVideoUrl,
    Constants.phantomVideoUrl,
  ];
  List<VideoListData> dataList = [];
  int value = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autoplay Video Feed')),
      body: ListView.builder(
        itemCount: dataList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const DemoContainer(
              child: DemoHeader(
                title: 'Scroll-Triggered Autoplay Feed (Deprecated)',
                description:
                    'Legacy BetterPlayerListVideoPlayer without pooling. '
                    'For high-performance feeds and bounded memory, use BetterPlayerFeed or BetterPlayerPool.',
                instructions:
                    'Scroll vertically to observe un-pooled play/pause switching.',
                icon: Icons.view_agenda_outlined,
              ),
            );
          }
          final videoListData = dataList[index - 1];
          return DemoContainer(
            child: VideoListWidget(videoListData: videoListData),
          );
        },
      ),
    );
  }
}
