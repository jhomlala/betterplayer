import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';

// TODO: get all downloaded assets
// TODO: remove download
// TODO: stream download progress
// TODO: support DRM config
// TODO: remove before downloading if already exists?
class BetterPlayerDownloader {
  static Stream<double> download({
    required String url,
    Map<String, dynamic> data = const <String, dynamic>{},
    BetterPlayerDrmConfiguration? drmConfiguration,
    BetterPlayerVideoFormat? videoFormat,
  }) {
    return VideoPlayerPlatform.instance.downloadAsset(
      url: url,
      data: data,
      drmConfiguration: drmConfiguration,
      videoFormat: videoFormat,
    );
  }

  static Future<void> remove(String url) {
    return VideoPlayerPlatform.instance.removeAsset(url);
  }

  static Future<Map<String, Map<String, dynamic>>> downloadedAssets() {
    return VideoPlayerPlatform.instance.downloadedAssets();
  }
}
