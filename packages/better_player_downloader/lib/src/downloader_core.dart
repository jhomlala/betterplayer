import 'package:better_player_downloader/src/models/download_state.dart';

DownloadResult validateRequest(DownloadRequest req) {
  if (req.url.isEmpty) {
    return const DownloadErr('url is empty');
  }
  if (req.url.toLowerCase().contains('.m3u8') ||
      req.url.toLowerCase().contains('.mpd')) {
    return DownloadRequiresNativeService(req.url);
  }
  return DownloadOk(
    DownloadInfo(
      url: req.url,
      bytesDownloaded: 0,
      totalBytes: 0,
      state: DownloadState.notStarted,
    ),
  );
}
