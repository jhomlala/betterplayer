---
id: downloads
title: Offline Downloads
---

# Offline Downloads

`BetterPlayerController` stores the segments of a DASH or HLS stream on the
device. When the download completes, the same URL plays without a network.

The download cache is separate from the streaming cache. A partial download
does not change the playback behaviour.

:::note
Downloads need Android. Other platforms ignore the calls.
:::

## Start a download

```dart
final controller = BetterPlayerController(
  const PlayerConfiguration(),
);

await controller.startDownload(
  PlayerDataSource(
    DataSourceType.network,
    'https://example.com/video.mpd',
  ),
);
```

The download stores one video track, so the size stays usable. Use
`maxVideoHeight` to limit the resolution. The default is the highest
resolution that the device supports.

```dart
await controller.startDownload(
  PlayerDataSource(DataSourceType.network, url),
  maxVideoHeight: 720,
);
```

## Watch the progress

```dart
final subscription = controller.downloadProgressStream.listen((progress) {
  if (progress.url != url) {
    return;
  }
  print('${progress.state} ${progress.bytesDownloaded}');
});
```

`DownloadProgress.fraction` returns `0.0` while `totalBytes` is `0`. A DASH
manifest reports the size only when the download completes. Show
`bytesDownloaded` in that case.

The engine sends one byte sample per second.

### Use a callback

`setDownloadCallback` receives the state of each download without a stream.

```dart
class _DownloadListener extends BetterPlayerDownloadCallback {
  @override
  void onDownloadState(String url, DownloadState state, String? error) {
    print('$url $state $error');
  }
}

controller.setDownloadCallback(_DownloadListener());
controller.setDownloadCallback(null); // Stops the calls.
```

The stream and the callback work together. A caller can use either of them.

## Stop, resume, and delete

```dart
await controller.stopDownload(url); // Keeps the stored data.
await controller.startDownload(dataSource); // Resumes a stopped download.
await controller.deleteDownload(url); // Removes the download and its data.
```

## Play a completed download

No extra call is necessary. Set the same data source and play it:

```dart
controller.setupDataSource(
  PlayerDataSource(DataSourceType.network, url),
);
```

The player reads the stored segments when the download is complete. It uses
the network again when the download is missing or incomplete.

## Limits

- The download uses the URL as its identifier. Two data sources with the same
  URL share one download.
- Request headers apply to the manifest and to the segments of the same host.
  Segments served from another host need no headers, or the host must match.
- A download starts only when the device has 100 MB or more free space. The
  call throws a `PlatformException` with the code `download_no_space` in other
  case.
- A DASH manifest reports the final size after the download. The check uses a
  minimum free space, not the exact size of the media.

## Android bridge

The download calls and their events use the `better_player_android` method
channel. The player uses generated pigeon/JNI bindings. A download callback
needs a new `jnigen` binding, and `jnigen` runs only in CI. The download API
keeps the method channel until that binding exists.

