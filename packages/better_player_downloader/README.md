# Better Player Downloader

Federated plugin for Better Player (`jhomlala/betterplayer`) to download video content offline.

## Issue Reference

- Issue: `#600` - Download DASH media on Android
- Repository: `https://github.com/jhomlala/betterplayer/issues/600`
- Solution: Plugin-based architecture (`plugin-first`) without modifying the core player.

## Data Structures

- `DownloadRequest`: `{ url, drmUrl?, key? }`
- `DownloadInfo`: `{ url, bytesDownloaded, totalBytes, state }`
- `DownloadProgress`: `{ state, percent, bytesDownloaded, totalBytes }`
- `DownloadResult`: sealed class (`DownloadOk`, `DownloadErr`, `DownloadRequiresNativeService`)

## Usage

```dart
final req = DownloadRequest(url: 'https://example.com/video.mpd');
final result = await BetterPlayerDownloader.startDownload(req);
final progress = await BetterPlayerDownloader.downloadProgress(req);
```

- `DownloadOk`: the download was accepted by the native service.
- `DownloadErr`: validation error (e.g., empty URL) or a native rejection.
- `DownloadRequiresNativeService`: returned when no native implementation is registered for the current platform.

## Adaptive Streams

`.m3u8` (HLS) and `.mpd` (DASH) URLs are flagged by `validateRequest` and routed to the Android
`DownloadService`, which uses Media3 `DownloadManager` with `DashDownloader` / `HlsDownloader`
so every media segment is stored, not just the manifest.

## Android Setup

The plugin is API 24+ and depends on Media3 1.11.0. No manual manifest setup is required: the
plugin manifest declares `DownloadService` and the foreground service permissions.

## Shared Cache

The plugin stores segments in the cache of `better_player_android`
(`cache/betterPlayerCache`), because a segment is playable offline only when the player reads it
from the cache it already uses. Media3 rejects two `SimpleCache` instances on the same folder,
so the plugin never creates its own cache.

`BetterPlayerCache.createCache` keeps the first budget it receives. Keep the player and the
plugin on the same budget, or call the plugin first with the intended size:

```dart
PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mpd',
  cacheConfiguration: const CacheConfiguration(
    useCache: true,
    preCacheSize: 3 * 1024 * 1024 * 1024,
  ),
);
```

Do not set `CacheConfiguration.key` for streams that you downloaded. The custom key overrides
the manifest entry only, so the player misses the manifest when the network is down. Segments
keep their own URLs and stay valid.

## Recovery

`BetterPlayerDownloader.deleteDownload` removes one download and its segments. Call it before
retrying a failed download.

## Verification

- `flutter analyze`: clean.
- `flutter test`: unit tests for `validateRequest` plus a widget test for the example app.
- `flutter build apk --debug`: compiles the Kotlin service and the Dart layer.
- `dart format`: applied.
