---
name: better_player-usage
description: >-
  Use when adding better_player to a Flutter app or implementing video playback,
  HLS/DASH streaming, controls, DRM, subtitles, caching, PiP, or playlists.
---

# Better Player Usage Guide

Better Player is a full-featured video player for Flutter built on ExoPlayer (Android), AVPlayer (iOS & macOS), and Shaka Player (Web). Use this skill to add Better Player to an app and write idiomatic 1.x code.

## 1. Adding Better Player to a Flutter App

### Install the package

Run:

```bash
flutter pub add better_player
```

Import the library:

```dart
import 'package:better_player/better_player.dart';
```

### Platform setup

* **Android**: Set `compileSdkVersion` to `36` in `android/app/build.gradle` (or `build.gradle.kts`) and enable MultiDex. Requires Flutter 3.47.0+.
* **iOS**: Set the minimum iOS deployment target to `13.0` in `ios/Podfile` and Xcode, and use Swift 5. For fullscreen auto-rotation, declare portrait and landscape orientations under `UISupportedInterfaceOrientations` in `ios/Runner/Info.plist`.
* **macOS**: Set minimum macOS deployment target to `10.15` (Catalina). If using App Sandbox, add `com.apple.security.network.client` to `DebugProfile.entitlements` and `Release.entitlements` to stream network videos.
* **Web**: Load Shaka Player in `web/index.html` before the closing `</body>` tag:

```html
<script src="https://cdn.jsdelivr.net/npm/shaka-player@4/dist/shaka-player.compiled.js"></script>
```

## 2. Core Rules & Anti-Patterns

* **Use 1.x model names**: Almost all configuration and data classes dropped the `BetterPlayer` prefix in 1.x.
  * ✅ `PlayerConfiguration`, `PlayerDataSource`, `PlayerControlsConfiguration`, `PlayerSubtitlesSource`, `PlayerSubtitlesConfiguration`, `PlayerPlaylistConfiguration`, `PlayerEvent`, `PlayerEventType`, `DrmConfiguration`, `DrmType`, `CacheConfiguration`, `NotificationConfiguration`, `BufferingConfiguration`, `VideoFormat`, `DataSourceType`.
  * ❌ Never use 0.0.84 names like `BetterPlayerConfiguration`, `BetterPlayerDataSource`, `BetterPlayerDrmConfiguration`, or `BetterPlayerEvent`.
* **Keep `BetterPlayer` prefix only where it still exists**:
  * ✅ `BetterPlayer`, `BetterPlayerController`, `BetterPlayerPlaylist`, `BetterPlayerPlaylistController`, `BetterPlayerListVideoPlayer`, `BetterPlayerListVideoPlayerController`, `BetterPlayerClearKeyUtils`, `BetterPlayerControlsState`, `BetterPlayerMultipleGestureDetector`.
* **Initialize in `initState()`**: Create `BetterPlayerController` inside `State.initState()`, never inside `build()`.
* **Provide bounded layout constraints**: Wrap `BetterPlayer` in an `AspectRatio` widget (for example, `aspectRatio: 16 / 9`) so the video view has concrete dimensions.
* **Do not double-dispose**: `PlayerConfiguration.autoDispose` defaults to `true`, so `BetterPlayer` automatically disposes its `BetterPlayerController` when the widget unmounts. Only call `_controller.dispose()` manually in `State.dispose()` if you set `autoDispose: false`.
* **Do not access `.videoPlayerController`**: Direct access to the underlying engine controller was removed in 1.4.0. Call `play()`, `pause()`, `seekTo()`, `setVolume()`, `setSpeed()`, and read `videoPlayerValue` directly on `BetterPlayerController`.

## 3. Basic & Common Workflows

### Quick network or file playback

For a single video without external controller calls, use the `BetterPlayer.network` or `BetterPlayer.file` factory:

```dart
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class QuickVideoPlayer extends StatelessWidget {
  const QuickVideoPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer.network(
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        betterPlayerConfiguration: const PlayerConfiguration(
          aspectRatio: 16 / 9,
          autoPlay: true,
          looping: true,
        ),
      ),
    );
  }
}
```

### Production setup with `BetterPlayerController`

Use `BetterPlayerController` in a `StatefulWidget` when you need headers, adaptive streaming (HLS/DASH), subtitles, DRM, caching, or programmatic playback control:

```dart
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final BetterPlayerController _controller;

  @override
  void initState() {
    super.initState();
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      headers: const {'User-Agent': 'MyFlutterApp/1.0'},
    );

    _controller = BetterPlayerController(
      const PlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: true,
        fit: BoxFit.contain,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayer(controller: _controller),
        ),
      ),
    );
  }
}
```

### Switching video sources at runtime

Call `setupDataSource` on an existing `BetterPlayerController` to load a new video without recreating the controller:

```dart
await _controller.setupDataSource(
  PlayerDataSource.network(
    'https://example.com/stream.m3u8',
    videoFormat: VideoFormat.hls,
  ),
);
```

### Customizing UI controls

Configure colors, icons, and feature toggles with `PlayerControlsConfiguration`:

```dart
const configuration = PlayerConfiguration(
  aspectRatio: 16 / 9,
  controlsConfiguration: PlayerControlsConfiguration(
    playerTheme: PlayerTheme.material, // or PlayerTheme.cupertino
    controlBarColor: Colors.black54,
    iconsColor: Colors.white,
    progressBarPlayedColor: Colors.redAccent,
     progressBarHandleColor: Colors.redAccent,
    enableSkips: true,
    enableFullscreen: true,
    enablePip: true,
    enablePlaybackSpeed: true,
    enableSubtitles: true,
    enableQualities: true,
    enableAudioTracks: true,
    playbackSpeeds: [0.5, 1.0, 1.25, 1.5, 2.0],
  ),
);
```

### Listening to player events

Pass `eventListener` in `PlayerConfiguration` or register a listener with `_controller.addEventsListener`:

```dart
_controller.addEventsListener((PlayerEvent event) {
  switch (event.betterPlayerEventType) {
    case PlayerEventType.initialized:
      // Video is ready to play
      break;
    case PlayerEventType.finished:
      // Video playback completed
      break;
    case PlayerEventType.exception:
      final error = event.parameters?['exception'];
      debugPrint('Playback error: $error');
    default:
      break;
  }
});
```

### Picture-in-Picture (PiP) & lock screen notifications

* **PiP**: Attach a `GlobalKey` to `BetterPlayer(controller: _controller, key: _playerKey)`. Check support with `await _controller.isPictureInPictureSupported()`, then call `_controller.enablePictureInPicture(_playerKey)`.
  * Android requires `android:supportsPictureInPicture="true"` on the `<activity>` tag in `AndroidManifest.xml`.
  * iOS requires **Audio, AirPlay, and Picture in Picture** enabled in Xcode Background Modes.
* **Notifications**: Pass `notificationConfiguration` inside `PlayerDataSource` and set `handleLifecycle: false` in `PlayerConfiguration` if playback should continue when the app moves to the background:

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mp4',
  notificationConfiguration: const NotificationConfiguration(
    showNotification: true,
    title: 'Episode 1',
    author: 'Channel Name',
    imageUrl: 'https://example.com/poster.jpg',
  ),
);
```

## 4. Advanced Topic References

Read these reference files when implementing specialized features:

* **DRM (Widevine, FairPlay, ClearKey, Token)**: See [references/drm.md](references/drm.md)
* **Subtitles (SRT, WebVTT, HLS/DASH tracks, styling)**: See [references/subtitles.md](references/subtitles.md)
* **Caching, Playlists, and Scrollable Lists**: See [references/caching_and_playlists.md](references/caching_and_playlists.md)
* **Migrating from 0.0.84 to 1.x.x**: See [references/migration_1x.md](references/migration_1x.md)
