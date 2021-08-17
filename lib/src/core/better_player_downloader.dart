import 'package:better_player/src/video_player/video_player_platform_interface.dart';

// TODO: get all downloaded assets
// TODO: remove download
// TODO: stream download progress
// TODO: support DRM config
// TODO: remove before downloading if already exists?
class BetterPlayerDownloader {
  final String downloadId;

  const BetterPlayerDownloader(this.downloadId);

  Future<void> download(String url) {
    return VideoPlayerPlatform.instance.downloadAsset(
      url: url,
      downloadId: downloadId,
    );
  }

  static Future<List<String>> downloadedAssets() {
    return VideoPlayerPlatform.instance.downloadedAssets();
  }
}
