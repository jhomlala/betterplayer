---
id: migration_to_1.x.x
title: Migrating to v1.x.x
---

# Migrating to Better Player 1.x.x

Better Player 1.x.x introduces a **federated plugin architecture** and a significantly cleaner public API. 
The package was split into smaller specialized packages, and redundant `BetterPlayer` prefixes were removed from model names.

## 1. Automated Migration (Recommended)

The easiest way to migrate your codebase is to use the automated Dart fix tool. We have provided a `fix_data.yaml` that will handle all the class renames for you.

Just run this in your terminal:
```bash
dart fix --apply
```

## 2. Real-world API Name Changes

To make the API cleaner and more idiomatic, almost all configuration and data models have dropped the `BetterPlayer` prefix. Here are side-by-side real-world examples of how to migrate your code in various scenarios.

### Player & Data Source Configuration

<table>
<tr>
<th width="50%">Before (0.8.x)</th>
<th width="50%">After (1.x.x)</th>
</tr>
<tr>
<td>

```dart
BetterPlayerController(
  BetterPlayerConfiguration(
    autoPlay: true,
  ),
  betterPlayerDataSource: BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "https://example.com/video.mp4",
    videoFormat: BetterPlayerVideoFormat.hls,
    cacheConfiguration: BetterPlayerCacheConfiguration(
      useCache: true,
    ),
    bufferingConfiguration: BetterPlayerBufferingConfiguration(
      minBufferMs: 50000,
    ),
    notificationConfiguration: BetterPlayerNotificationConfiguration(
      showNotification: true,
      title: "My Video",
    ),
    drmConfiguration: BetterPlayerDrmConfiguration(
      drmType: BetterPlayerDrmType.widevine,
      licenseUrl: "https://example.com/license",
    ),
  ),
)
```

</td>
<td>

```dart
BetterPlayerController(
  PlayerConfiguration( // [!code focus]
    autoPlay: true,
  ),
  betterPlayerDataSource: PlayerDataSource( // [!code focus]
    DataSourceType.network, // [!code focus]
    "https://example.com/video.mp4",
    videoFormat: VideoFormat.hls, // [!code focus]
    cacheConfiguration: CacheConfiguration( // [!code focus]
      useCache: true,
    ),
    bufferingConfiguration: BufferingConfiguration( // [!code focus]
      minBufferMs: 50000,
    ),
    notificationConfiguration: NotificationConfiguration( // [!code focus]
      showNotification: true,
      title: "My Video",
    ),
    drmConfiguration: DrmConfiguration( // [!code focus]
      drmType: BetterPlayerDrmType.widevine,
      licenseUrl: "https://example.com/license",
    ),
  ),
)
```

</td>
</tr>
</table>

### Controls & UI Customization

<table>
<tr>
<th width="50%">Before (0.8.x)</th>
<th width="50%">After (1.x.x)</th>
</tr>
<tr>
<td>

```dart
BetterPlayerControlsConfiguration(
  playerTheme: BetterPlayerTheme.material,
  progressBarPlayedColor: Colors.red,
  overflowMenuCustomItems: [
    BetterPlayerOverflowMenuItem(
      Icons.star,
      "Favorite",
      () => print("Clicked"),
    ),
  ],
)
```

</td>
<td>

```dart
PlayerControlsConfiguration( // [!code focus]
  playerTheme: PlayerTheme.material, // [!code focus]
  progressBarPlayedColor: Colors.red,
  overflowMenuCustomItems: [
    PlayerOverflowMenuItem( // [!code focus]
      Icons.star,
      "Favorite",
      () => print("Clicked"),
    ),
  ],
)
```

</td>
</tr>
</table>

### Subtitles & Tracks

<table>
<tr>
<th width="50%">Before (0.8.x)</th>
<th width="50%">After (1.x.x)</th>
</tr>
<tr>
<td>

```dart
final source = BetterPlayerSubtitlesSource(
  type: BetterPlayerSubtitlesSourceType.network,
  urls: ["https://example.com/sub.srt"],
);

final config = BetterPlayerSubtitlesConfiguration(
  fontSize: 20,
  fontColor: Colors.white,
);
```

</td>
<td>

```dart
final source = PlayerSubtitlesSource( // [!code focus]
  type: BetterPlayerSubtitlesSourceType.network,
  urls: ["https://example.com/sub.srt"],
);

final config = PlayerSubtitlesConfiguration( // [!code focus]
  fontSize: 20,
  fontColor: Colors.white,
);
```

</td>
</tr>
</table>

### Playlists

<table>
<tr>
<th width="50%">Before (0.8.x)</th>
<th width="50%">After (1.x.x)</th>
</tr>
<tr>
<td>

```dart
final playlistConfig = BetterPlayerPlaylistConfiguration(
  loopVideos: true,
  nextVideoDelay: Duration(seconds: 3),
);
```

</td>
<td>

```dart
final playlistConfig = PlayerPlaylistConfiguration( // [!code focus]
  loopVideos: true,
  nextVideoDelay: Duration(seconds: 3),
);
```

</td>
</tr>
</table>

### Events & Utils

<table>
<tr>
<th width="50%">Before (0.8.x)</th>
<th width="50%">After (1.x.x)</th>
</tr>
<tr>
<td>

```dart
_controller.addEventsListener((BetterPlayerEvent event) {
  if (event.betterPlayerEventType == BetterPlayerEventType.play) {
    print("Video is playing");
  }
});
```

</td>
<td>

```dart
_controller.addEventsListener((PlayerEvent event) { // [!code focus]
  if (event.betterPlayerEventType == PlayerEventType.play) { // [!code focus]
    print("Video is playing");
  }
});
```

</td>
</tr>
</table>

## 3. Parameter Renames

- `isPictureInPictureEnabled` in `BetterPlayerController` has been renamed to `isPictureInPictureSupported` to better reflect its function (it checks if the hardware/OS supports PiP, not if it's currently turned on).

