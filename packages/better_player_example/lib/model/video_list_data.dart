class VideoListData {
  VideoListData(this.videoTitle, this.videoUrl);
  final String videoTitle;
  final String videoUrl;
  Duration? lastPosition;
  bool? wasPlaying = false;
}
