---
id: migration_from_media_kit
title: Migrating from media_kit
---

# Migrating from `media_kit`

`media_kit` brings `libmpv` to Flutter, which works well for desktop experimentation. But when you ship to mobile in production, bundling full C/C++ media engines introduces serious trade-offs: 30 to 50 MB of binary bloat per architecture, higher battery consumption from non-native render loops, missing hardware DRM on mobile, and zero built-in offline caching.

**Better Player** uses each platform's native multimedia engine where it matters most: Google Media3 / ExoPlayer on Android, Apple AVPlayer on iOS and macOS, and Shaka Player on Web. (To be completely candid: Better Player also uses `libmpv` on Windows desktop via `better_player_windows`, because `libmpv` is the right tool for Windows. The difference is federated isolation: mobile and Apple platforms remain 100% native). You get native hardware acceleration, system-level DRM (Widevine, FairPlay), offline caching, PiP, and a tiny footprint (~1-2 MB overhead on mobile).

This guide walks you through migrating from `media_kit` to `better_player`.

---

## Why Migrate?

| Consideration | `media_kit` | `better_player` |
|---|---|---|
| **Mobile Binary Size** | **+30 MB to 50 MB** (bundled `libmpv` / FFmpeg binaries) | **~1-2 MB** (uses OS-provided native frameworks) |
| **Mobile Engine** | `libmpv` rendered to Flutter texture | Native Google Media3 / ExoPlayer & Apple AVPlayer |
| **Desktop Engines** | `libmpv` on Windows, macOS, Linux | Native AVPlayer on macOS, `libmpv` on Windows |
| **Battery & Thermals** | Higher draw due to custom C rendering pipeline on mobile | Optimized by OS hardware decoders and power policies |
| **DRM Support** | None on mobile (no hardware Widevine or FairPlay) | Production Widevine Modular L1/L3 and FairPlay EZDRM |
| **Offline Caching** | None (requires external proxy or custom downloaders) | Built-in disk cache and pre-caching APIs |
| **Video Ads** | None | Client-side VAST 2.0-4.x and VMAP ad engine |
| **Feed Performance** | Prone to decoder exhaustion with multiple instances | Bounded instance pooling (`BetterPlayerPool`) |
| **Entrypoint Ceremony** | Requires `MediaKit.ensureInitialized()` in `main()` | Zero global initialization boilerplate |

> [!NOTE]
> **Full disclosure on Windows:**
> Better Player uses `libmpv` on Windows too (via `better_player_windows`). On Windows desktop, `libmpv` is a proven powerhouse with wide codec coverage and Direct3D 11 texture sharing.
>
> The key difference is federated packaging. In Better Player, `libmpv` is scoped strictly to Windows desktop builds. Your iOS, Android, macOS, and Web builds never touch or bundle `libmpv`. You get the right engine for each platform without burdening your mobile users with 50 MB downloads or battery-heavy software loops.

---

## Step 1: Update `pubspec.yaml`

Remove `media_kit`, its UI package, and any platform-specific binary bundles. Add `better_player`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Remove media_kit packages:
  # media_kit: ^1.1.10
  # media_kit_video: ^1.2.4
  # media_kit_libs_video: ^1.0.4
  # media_kit_native_event_loop: ^1.0.4

  # Add Better Player:
  better_player: ^1.27.0
```

Run `flutter pub get` in your terminal to update dependencies.

---

## Step 2: Clean up `main.dart`

`media_kit` required global initialization before `runApp()` to register native hooks and binary symbols. Better Player initializes on demand through standard platform channels and plugins.

Remove the `MediaKit.ensureInitialized()` call:

```dart
// Remove this import:
// import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove this line:
  // MediaKit.ensureInitialized();

  runApp(const MyApp());
}
```

> [!WARNING]
> If you keep `MediaKit.ensureInitialized()` in your code after removing `media_kit_libs_video`, your app will crash at startup searching for missing dynamic libraries (`libmpv.so` or `mpv.framework`).

---

## Step 3: Update Imports

Replace all `media_kit` imports with `better_player`:

```dart
// Remove:
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';

// Add:
import 'package:better_player/better_player.dart';
```

---

## Step 4: Code Migration Examples

### 1. Controller Initialization

In `media_kit`, you maintain two separate objects: a `Player` for media state and a `VideoController` for texture presentation.

Better Player unifies playback state, configuration, and presentation into a single `BetterPlayerController`.

#### `media_kit`:
```dart
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);

  @override
  void initState() {
    super.initState();
    _player.open(Media('https://example.com/video.mp4'));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
```

#### `better_player`:
```dart
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late final BetterPlayerController _controller;

  @override
  void initState() {
    super.initState();

    final dataSource = PlayerDataSource(
      DataSourceType.network,
      'https://example.com/video.mp4',
    );

    _controller = BetterPlayerController(
      const PlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### 2. UI Widget Rendering

#### `media_kit`:
`media_kit` uses the `Video` widget and requires manual sizing or wrapping:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        child: Video(controller: _videoController),
      ),
    ),
  );
}
```

#### `better_player`:
`BetterPlayer` handles aspect ratio, controls, loading spinners, and error banners internally:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(controller: _controller),
      ),
    ),
  );
}
```

---

### 3. Playback Controls & Methods

Most core methods map directly, with one critical difference in volume handling.

#### Play, Pause, and Seek:
```dart
// media_kit
await _player.play();
await _player.pause();
await _player.seek(const Duration(seconds: 45));

// better_player
await _controller.play();
await _controller.pause();
await _controller.seekTo(const Duration(seconds: 45));
```

#### Volume Normalization (Important Gotcha):
`media_kit` uses a `0.0` to `100.0` percentage scale for volume. Better Player follows Flutter's standard normalized `0.0` to `1.0` scale.

```dart
// media_kit (0.0 to 100.0)
await _player.setVolume(80.0);

// better_player (0.0 to 1.0)
await _controller.setVolume(0.8);
```

#### Playback Speed:
```dart
// media_kit
await _player.setRate(1.5);

// better_player
await _controller.setSpeed(1.5);
```

#### Looping:
```dart
// media_kit
await _player.setPlaylistMode(PlaylistMode.loop);

// better_player
await _controller.setLooping(true);
```

---

### 4. Listening to Playback State & Events

`media_kit` separates state into individual streams on `player.stream` and synchronous snapshots on `player.state`.

Better Player provides instant getters on the controller and a unified event stream via `addEventsListener`.

#### State Inspection:
```dart
// media_kit (synchronous state)
final position = _player.state.position;
final duration = _player.state.duration;
final isPlaying = _player.state.playing;
final isBuffering = _player.state.buffering;

// better_player (synchronous getters)
final position = _controller.videoPlayerController?.value.position ?? Duration.zero;
final duration = _controller.videoPlayerController?.value.duration ?? Duration.zero;
final isPlaying = _controller.isPlaying() ?? false;
final isBuffering = _controller.isBuffering() ?? false;
```

#### Event Listening:
```dart
// media_kit: multiple stream subscriptions
final positionSub = _player.stream.position.listen((pos) => print('Pos: $pos'));
final completedSub = _player.stream.completed.listen((done) => print('Done: $done'));

// better_player: one unified listener
_controller.addEventsListener((BetterPlayerEvent event) {
  switch (event.betterPlayerEventType) {
    case BetterPlayerEventType.progress:
      print('Position: ${_controller.videoPlayerController?.value.position}');
      break;
    case BetterPlayerEventType.finished:
      print('Playback finished');
      break;
    case BetterPlayerEventType.play:
      print('Playback started');
      break;
    case BetterPlayerEventType.pause:
      print('Playback paused');
      break;
    case BetterPlayerEventType.exception:
      print('Playback error occurred');
      break;
    default:
      break;
  }
});
```

---

### 5. Playlists

#### `media_kit`:
```dart
await _player.open(
  Playlist([
    Media('https://example.com/video1.mp4'),
    Media('https://example.com/video2.mp4'),
  ]),
);

await _player.next();
await _player.previous();
```

#### `better_player`:
Better Player offers the `BetterPlayerPlaylist` widget for automatic video transitions with optional countdown overlays:

```dart
final dataSources = [
  PlayerDataSource(DataSourceType.network, 'https://example.com/video1.mp4'),
  PlayerDataSource(DataSourceType.network, 'https://example.com/video2.mp4'),
];

@override
Widget build(BuildContext context) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: BetterPlayerPlaylist(
      betterPlayerConfiguration: const PlayerConfiguration(),
      betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
        nextVideoDelay: Duration(seconds: 3),
      ),
      betterPlayerDataSourceList: dataSources,
    ),
  );
}
```

For programmatic transitions outside the widget, use `BetterPlayerPlaylistController`:

```dart
betterPlayerPlaylistController.playNextVideo();
betterPlayerPlaylistController.playPreviousVideo();
```

---

### 6. Subtitles & Audio Tracks

#### Subtitles:
In `media_kit`, you assign subtitles at runtime using `player.setSubtitleTrack(SubtitleTrack.uri(...))`.

In Better Player, attach subtitle tracks directly to `PlayerDataSource`, or switch sources on the fly:

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mp4',
  subtitles: [
    PlayerSubtitlesSource(
      type: PlayerSubtitlesSourceType.network,
      name: 'English',
      urls: ['https://example.com/en.vtt'],
    ),
    PlayerSubtitlesSource(
      type: PlayerSubtitlesSourceType.network,
      name: 'Spanish',
      urls: ['https://example.com/es.vtt'],
    ),
  ],
);
```

Switch subtitle tracks dynamically with:

```dart
_controller.setupSubtitleSource(
  PlayerSubtitlesSource(
    type: PlayerSubtitlesSourceType.network,
    name: 'French',
    urls: ['https://example.com/fr.vtt'],
  ),
);
```

#### Audio Tracks:
In HLS / DASH adaptive streams, inspect and switch audio languages:

```dart
// Check available tracks:
final tracks = _controller.betterPlayerAsmsAudioTracks;

// Select track:
if (tracks != null && tracks.isNotEmpty) {
  _controller.setAudioTrack(tracks.first);
}
```

---

## Features You Unlock After Migrating

Migrating to Better Player unlocks capabilities that require complex third-party tools or are unsupported in `media_kit`:

### 1. Native Hardware DRM
Deliver protected Widevine Modular (Android / Web) and FairPlay (iOS / macOS) content with hardware-backed decryptors:

```dart
PlayerDataSource(
  DataSourceType.network,
  'https://example.com/protected.mpd',
  drmConfiguration: DrmConfiguration(
    drmType: DrmType.widevine,
    licenseUrl: 'https://license.example.com/get-license',
    headers: {'Authorization': 'Bearer token'},
  ),
);
```

### 2. Built-in Offline Caching
Cache video chunks directly to device flash memory without setting up an external HTTP proxy server:

```dart
PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mp4',
  cacheConfiguration: const CacheConfiguration(
    useCache: true,
    maxCacheSize: 100 * 1024 * 1024,      // 100 MB total cache budget
    maxCacheFileSize: 20 * 1024 * 1024,  // 20 MB max file size
  ),
);
```

Pre-cache videos ahead of time:
```dart
_controller.preCache(dataSource);
```

### 3. Native Picture-in-Picture (PiP)
Enable system-level PiP on Android and iOS:

```dart
if (await _controller.isPictureInPictureSupported()) {
  await _controller.enablePictureInPicture(
    left: 20,
    top: 20,
    width: 200,
    height: 120,
  );
}
```

### 4. Client-Side VAST & VMAP Ad Engine
Play pre-roll, mid-roll, and post-roll video advertisements with companion ads, skip buttons, and verified tracking beacons without third-party SDK dependencies.

### 5. High-Performance Feeds & Pooling
When building vertical swipe feeds (TikTok / Reels style), `media_kit` instances quickly exhaust hardware decoders. Better Player includes `BetterPlayerFeed` and `BetterPlayerPool` with bounded instance slots and off-screen resource reuse.

---

## API Mapping Reference

| `media_kit` | `better_player` | Notes |
|---|---|---|
| `MediaKit.ensureInitialized()` | *(Not needed)* | Remove from `main.dart`. |
| `Player()` | `BetterPlayerController(...)` | Manages playback state and configuration. |
| `VideoController(player)` | *(Not needed)* | Handled directly by `BetterPlayerController`. |
| `Video(controller: ...)` | `BetterPlayer(controller: ...)` | Main UI playback widget. |
| `Media(url)` | `PlayerDataSource(DataSourceType.network, url)` | Defines data source, DRM, caching, and headers. |
| `player.open(media)` | `controller.setupDataSource(dataSource)` | Loads a new media source. |
| `player.play()` | `controller.play()` | Starts playback. |
| `player.pause()` | `controller.pause()` | Pauses playback. |
| `player.seek(duration)` | `controller.seekTo(duration)` | Seeks to target position. |
| `player.setVolume(val)` (0-100) | `controller.setVolume(val)` (0.0-1.0) | **Gotcha:** Better Player uses normalized 0.0-1.0 scale. |
| `player.setRate(val)` | `controller.setSpeed(val)` | Sets playback speed. |
| `player.setPlaylistMode(mode)` | `controller.setLooping(val)` | Toggles video looping. |
| `player.dispose()` | `controller.dispose()` | Releases player and native resources. |
| `player.state.position` | `controller.videoPlayerController?.value.position` | Synchronous position getter. |
| `player.state.playing` | `controller.isPlaying()` | Synchronous playing check. |
| `player.state.buffering` | `controller.isBuffering()` | Synchronous buffering check. |
| `player.stream.*` | `controller.addEventsListener(...)` | Unified reactive event stream. |
| `player.setSubtitleTrack(...)` | `controller.setupSubtitleSource(...)` | Switches subtitle source. |
| `player.setAudioTrack(...)` | `controller.setAudioTrack(...)` | Switches active audio track. |
| `Playlist([media1, media2])` | `BetterPlayerPlaylist(...)` | Built-in playlist widget and controller. |
