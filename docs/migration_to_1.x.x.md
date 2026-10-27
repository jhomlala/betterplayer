---
id: migration_to_1.x.x
title: Migrating to v1.x.x (from 0.0.84 & better_player_plus)
---

# Migrating to Better Player 1.x.x

Better Player 1.x.x introduces a **federated plugin architecture** and a significantly cleaner public API. 
This guide covers upgrading from **Better Player 0.0.84** or migrating from community forks including **`better_player_plus`**, **`better_player_enhanced`**, and **`river_player`**.

---

## Migrating from `better_player_plus` & Community Forks

Community forks like `better_player_plus` originated as temporary patches for Better Player `0.0.84`. Because those forks preserved the legacy `0.0.84` API, they share the same class names (`BetterPlayerConfiguration`, `BetterPlayerDataSource`, etc.) and the same limitations (legacy MethodChannels, mobile-only platforms, and no video feed pooling).

### Feature Comparison: `better_player` 1.x vs `better_player_plus`

| Feature | `better_player_plus` | `better_player` 1.x |
|---|:---:|:---:|
| **Platform Coverage** | Mobile only (Android & iOS) | **6 Platforms** (Android, iOS, macOS, Windows, Linux, Web) |
| **Native Architecture** | Legacy MethodChannels | **Direct JNI & native Swift/AppKit FFI** |
| **Android Engine** | Legacy ExoPlayer | **AndroidX Media3 (1.11+)** with AGP 8+ namespace |
| **Web Engine** | Basic HTML5 Video | **Shaka Player** (HLS, DASH, and DRM on web) |
| **Short-form Video Feeds** | Manual / prone to OOM crashes | **Built-in `BetterPlayerFeed` & `BetterPlayerPool`** |
| **Video Monetization** | None | **Client-side VAST 2.0-4.x & VMAP linear ads** |
| **Content Protection** | Basic DRM (Mobile only) | **Widevine, FairPlay, ClearKey, Watermarking & Screen Shield** |
| **Telemetry & QoE** | None | **Real-time video metrics, offline retention & cloud export** |
| **Automated Migration** | None | **Automated `dart fix --apply`** |

### 3-Step Migration from `better_player_plus`

#### Step 1: Update `pubspec.yaml`
Replace `better_player_plus` (or any legacy fork) with `better_player`:

```yaml
dependencies:
  # Remove:
  # better_player_plus: ^x.y.z
  
  # Add:
  better_player: ^1.29.0
```

Run `flutter pub get`.

#### Step 2: Update Dart imports
Search and replace across your project:
- Replace `package:better_player_plus/better_player_plus.dart` with `package:better_player/better_player.dart`.

#### Step 3: Run `dart fix`
Run automated migration in your terminal to rename all legacy `BetterPlayer*` classes to the clean 1.x `Player*` naming:

```bash
dart fix --apply
```

---

## Version History & Key Architecture Changes
- **v1.17.x**: Standardized internal widget and utility naming under the `Player*` prefix (including exported `PlayerAsmsUtils` and `PlayerUiUtils`).
- **v1.13.x**: Bug-fix release — HLS pre-cache blocking, PiP event fixes, DASH parsing fixes, `enableReplay` control, iOS seek stability, and enhanced error payloads.
- **v1.5.x**: Refactored `BetterPlayerController` state into immutable data classes.
- **v1.4.x**: Replaced `VideoPlayerController` with `PlayerEngineController`.
- **v1.3.x**: Introduced the extensible `PlayerLogger` logging system.
- **v1.2.x**: Migrated to modern JNI/Swift architecture (FFI) for native bridges.
- **v1.1.x**: Unified model names and introduced `fix_data.yaml` for automated migration.
- **v1.0.x**: Initial federated plugin architecture, delegating to `better_player_android` and `better_player_ios`.

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
<th width="50%">Before (0.0.84)</th>
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
      drmType: DrmType.widevine,
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
<th width="50%">Before (0.0.84)</th>
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
<th width="50%">Before (0.0.84)</th>
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
<th width="50%">Before (0.0.84)</th>
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
<th width="50%">Before (0.0.84)</th>
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

final durationStr = BetterPlayerUtils.formatDuration(position);
final isAsms = BetterPlayerAsmsUtils().isDataSourceAsms(url);
```

</td>
<td>

```dart
_controller.addEventsListener((PlayerEvent event) {
  if (event.betterPlayerEventType == PlayerEventType.play) {
    print("Video is playing");
  }
});

final durationStr = PlayerUiUtils.formatDuration(position);
final isAsms = PlayerAsmsUtils().isDataSourceAsms(url);
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

<table>
<tr>
<th width="50%">Before</th>
<th width="50%">After</th>
</tr>
<tr>
<td>

```dart
class MyCustomPlatform extends VideoPlayerPlatform { ... }
```

</td>
<td>

```dart
class MyCustomPlatform extends BetterPlayerPlatform { ... }
```

</td>
</tr>
</table>

2.  **Legacy `MethodChannelVideoPlayer` Removal**:
    The class `MethodChannelVideoPlayer` is no longer available. All logic has been moved to the respective FFI/JNI implementations in `better_player_android` and `better_player_ios`.

## 5. Removing VideoPlayerController from the Public API

In version 1.4.0, direct access to the underlying video player controller (`VideoPlayerController` / `PlayerEngineController`) has been removed from the public API. This was done to provide a cleaner and safer abstraction, ensuring all state changes flow through `BetterPlayerController`.

The `VideoPlayerController` type is no longer exported, and the `videoPlayerController` (or `engineController`) getter has been removed.

### How to migrate

If you were accessing the underlying video player controller directly, you should now use the proxied methods on `BetterPlayerController`:

**Playback Controls:**

<table>
<tr>
<th width="50%">Before</th>
<th width="50%">After</th>
</tr>
<tr>
<td>

```dart
controller.videoPlayerController!.play();
controller.videoPlayerController!.seekTo(Duration.zero);
```

</td>
<td>

```dart
controller.play();
controller.seekTo(Duration.zero);
```

</td>
</tr>
</table>

**State Access:**

<table>
<tr>
<th width="50%">Before</th>
<th width="50%">After</th>
</tr>
<tr>
<td>

```dart
final value = controller.videoPlayerController!.value;
final isPlaying = value.isPlaying;
```

</td>
<td>

```dart
final value = controller.videoPlayerValue;
final isPlaying = value?.isPlaying ?? false;
```

</td>
</tr>
</table>

**Event Listeners:**

<table>
<tr>
<th width="50%">Before</th>
<th width="50%">After</th>
</tr>
<tr>
<td>

```dart
void listener() { ... }
controller.videoPlayerController!.addListener(listener);
controller.videoPlayerController!.removeListener(listener);
```

</td>
<td>

```dart
void listener() { ... }
controller.addVideoListener(listener);
controller.removeVideoListener(listener);
```

</td>
</tr>
</table>

## 6. Migrating to v1.7.0 (Web & WASM Support)

Better Player 1.7.0 introduces full support for **Flutter Web and WASM**. To achieve this, the core library has been decoupled from the `dart:io` library, which is not available on web platforms.

### Breaking Change: `setFileDataSource`

The method `setFileDataSource` in `PlayerEngineController` (and its mock version) now accepts a `String filePath` instead of a `dart:io` `File` object.

**How to migrate:**

<table>
<tr>
<th width="50%">Before (v1.6.x)</th>
<th width="50%">After (v1.7.0)</th>
</tr>
<tr>
<td>

```dart
import 'dart:io';

// ...
final file = File('/path/to/video.mp4');
controller.engineController.setFileDataSource(file);
```

</td>
<td>

```dart
// No dart:io import needed for this call
final filePath = '/path/to/video.mp4';
controller.engineController.setFileDataSource(filePath);
```

</td>
</tr>
</table>

> [!NOTE]
> If you are using `PlayerDataSource.file(path)`, no changes are required as it already used a `String` path internally. This change only affects direct calls to the engine controller.

