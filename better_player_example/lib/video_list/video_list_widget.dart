import 'package:better_player/better_player.dart';
import 'package:better_player_example/video_list/video_list_data.dart';
import 'package:flutter/material.dart';

class VideoListWidget extends StatefulWidget {
  final VideoListData videoListData;

  const VideoListWidget({Key key, this.videoListData}) : super(key: key);

  @override
  _VideoListWidgetState createState() => _VideoListWidgetState();
}

class _VideoListWidgetState extends State<VideoListWidget> {
  VideoListData get videoListData => widget.videoListData;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(videoListData.videoTitle),
          AspectRatio(
              child: BetterPlayerListVideoPlayer(
                BetterPlayerDataSource(
                    BetterPlayerDataSourceType.NETWORK, videoListData.videoUrl),
                settings:
                    BetterPlayerSettings(autoInitialize: true, autoPlay: false),
                key: Key(videoListData.hashCode.toString()),
              ),
              aspectRatio: 16/9),
          Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras vitae semper lorem. Integer vitae porttitor lectus. Duis dignissim velit leo, id imperdiet ante ornare in. Suspendisse sed rhoncus orci. Phasellus facilisis ante eu eros consequat, a volutpat orci sagittis. Morbi vulputate interdum sapien, sit amet iaculis turpis lobortis sed. ")
        ],
      ),
    );
  }
}
