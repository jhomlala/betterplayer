## Unreleased

- Added `better_player_downloader`, a federated Android plugin that downloads DASH and HLS
  streams with Media3 `DownloadManager` for offline playback. It closes the gap reported in
  issue #600, where pre-caching stored only the manifest.
- Added `startDownload`, `downloadProgress` and `deleteDownload` to the `MethodChannel` bridge.
- The plugin stores segments in the cache of `better_player_android`, so a downloaded stream
  plays without a network.
