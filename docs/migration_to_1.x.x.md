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
    DataSourceType.network,
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
  PlayerConfiguration(
    autoPlay: true,
  ),
  betterPlayerDataSource: PlayerDataSource(
    DataSourceType.network,
    "https://example.com/video.mp4",
    videoFormat: VideoFormat.hls,
    cacheConfiguration: CacheConfiguration(
      useCache: true,
    ),
    bufferingConfiguration: BufferingConfiguration(
      minBufferMs: 50000,
    ),
    notificationConfiguration: NotificationConfiguration(
      showNotification: true,
      title: "My Video",
    ),
    drmConfiguration: DrmConfiguration(
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
PlayerControlsConfiguration(
  playerTheme: PlayerTheme.material,
  progressBarPlayedColor: Colors.red,
  overflowMenuCustomItems: [
    PlayerOverflowMenuItem(
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
final source = PlayerSubtitlesSource(
  type: PlayerSubtitlesSourceType.network,
  urls: ["https://example.com/sub.srt"],
);

final config = PlayerSubtitlesConfiguration(
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
final playlistConfig = PlayerPlaylistConfiguration(
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
_controller.addEventsListener((PlayerEvent event) {
  if (event.betterPlayerEventType == PlayerEventType.play) {
    print("Video is playing");
  }
});
```

</td>
</tr>
</table>

## 3. Parameter Renames

- `isPictureInPictureEnabled` in `BetterPlayerController` has been renamed to `isPictureInPictureSupported` to better reflect its function (it checks if the hardware/OS supports PiP, not if it's currently turned on).

## 4. Migrating to v1.2.0 (Direct Native Bridges)

Better Player 1.2.0 replaces the legacy asynchronous `MethodChannel` communication with **Direct Native Bridges**. 
This architectural shift provides higher performance, better type safety, and more reliable state synchronization.

### What Changed?

*   **Android**: Migrated to **JNI** using `jnigen`. The plugin now communicates directly with the Java/Kotlin media engine without the overhead of MethodChannel serialization.
*   **iOS**: Migrated to **Swift FFI** using `swiftgen`. This allows Dart to call into `AVPlayer` logic directly through the Objective-C runtime.
*   **Platform Interface**: 
    *   Renamed `VideoPlayerPlatform` to `BetterPlayerPlatform`.
    *   Removed `MethodChannelVideoPlayer`. 

### Breaking Changes for Custom Implementations

If you have extended Better Player or implemented a custom platform backend, you must update your references:

1.  **Replace `VideoPlayerPlatform` with `BetterPlayerPlatform`**:
    ```dart
    // Before
    class MyCustomPlatform extends VideoPlayerPlatform { ... }
    
    // After
    class MyCustomPlatform extends BetterPlayerPlatform { ... }
    ```

2.  **Legacy `MethodChannelVideoPlayer` Removal**:
    The class `MethodChannelVideoPlayer` is no longer available. All logic has been moved to the respective FFI/JNI implementations in `better_player_android` and `better_player_ios`.

## 5. Removing VideoPlayerController from the Public API

In version 1.x.x, direct access to the underlying video player controller (`VideoPlayerController` / `PlayerEngineController`) has been removed from the public API. This was done to provide a cleaner and safer abstraction, ensuring all state changes flow through `BetterPlayerController`.

The `VideoPlayerController` type is no longer exported, and the `videoPlayerController` (or `engineController`) getter has been removed.

### How to migrate

If you were accessing the underlying video player controller directly, you should now use the proxied methods on `BetterPlayerController`:

**Playback Controls:**
```dart
// Before
controller.videoPlayerController!.play();
controller.videoPlayerController!.seekTo(Duration.zero);

// After
controller.play();
controller.seekTo(Duration.zero);
```

**State Access:**
```dart
// Before
final value = controller.videoPlayerController!.value;
final isPlaying = value.isPlaying;

// After
final value = controller.videoPlayerValue;
final isPlaying = value?.isPlaying ?? false;
```

**Event Listeners:**
```dart
// Before
void listener() { ... }
controller.videoPlayerController!.addListener(listener);
controller.videoPlayerController!.removeListener(listener);

// After
void listener() { ... }
controller.addVideoListener(listener);
controller.removeVideoListener(listener);
```
