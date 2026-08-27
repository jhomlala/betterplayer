---
id: migration_from_chewie
title: Migrating from chewie
---

# Migrating from `chewie`

While `chewie` is a popular video player controller wrapper for Flutter's official `video_player`, applications often outgrow its capabilities when requiring advanced features such as robust video caching, seamless HLS/DASH track selection, built-in multi-format subtitle support (SRT/WebVTT), Picture-in-Picture (PiP), and optimized `ListView` video playback.

**Better Player** extends the core playback concepts inspired by Chewie and bundles them into a robust, all-in-one plugin with native UI controls and extensive configuration options.

This guide outlines step-by-step instructions on how to migrate your project from `chewie` (and its underlying `video_player`) to `better_player`.

---

## Step 1: Update `pubspec.yaml`

Remove `chewie` and `video_player` from your dependencies and add `better_player`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Remove these lines:
  # chewie: ^x.y.z
  # video_player: ^x.y.z
  
  # Add this line:
  better_player: ^0.6.0
```

Run `flutter pub get` in your terminal to fetch the packages.

---

## Step 2: Update Imports

Replace all `chewie` and `video_player` imports across your Dart files with `better_player`:

```dart
// Remove:
// import 'package:chewie/chewie.dart';
// import 'package:video_player/video_player.dart';

// Add:
import 'package:better_player/better_player.dart';
```

---

## Step 3: Code Migration Examples

### 1. Controller Initialization

#### `chewie` + `video_player` approach:
In Chewie, you must initialize and maintain a `VideoPlayerController` and pass it into a `ChewieController`.

```dart
late VideoPlayerController _videoPlayerController;
late ChewieController _chewieController;

@override
void initState() {
  super.initState();
  _videoPlayerController = VideoPlayerController.networkUrl(
    Uri.parse('https://example.com/video.mp4'),
  );

  _videoPlayerController.initialize().then((_) {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
    );
    setState(() {});
  });
}
```

#### `better_player` approach:
Better Player combines data source definition and playback configuration into `BetterPlayerController` and `PlayerDataSource`, managing initialization under the hood.

```dart
late BetterPlayerController _betterPlayerController;

@override
void initState() {
  super.initState();

  PlayerDataSource dataSource = PlayerDataSource(
    PlayerDataSourceType.network,
    'https://example.com/video.mp4',
  );

  _betterPlayerController = BetterPlayerController(
    const PlayerConfiguration(
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
    ),
    betterPlayerDataSource: dataSource,
  );
}
```

---

### 2. UI Widget & Rendering

#### `chewie` approach:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: _chewieController.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController)
          : const CircularProgressIndicator(),
    ),
  );
}
```

#### `better_player` approach:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(
          controller: _betterPlayerController,
        ),
      ),
    ),
  );
}
```

---

### 3. Lifecycle Disposal

#### `chewie`:
You need to dispose both controllers separately.
```dart
@override
void dispose() {
  _videoPlayerController.dispose();
  _chewieController.dispose();
  super.dispose();
}
```

#### `better_player`:
Disposing the `BetterPlayerController` automatically cleans up all internal players, listeners, and resources.
```dart
@override
void dispose() {
  _betterPlayerController.dispose();
  super.dispose();
}
```

---

## Step 4: Leverage Better Player's Advanced Features

Switching to Better Player gives you immediate access to features that often require custom implementations or plugins when using Chewie:

- **Built-in Video Caching**:
  ```dart
  PlayerDataSource(
    PlayerDataSourceType.network,
    'https://example.com/video.mp4',
    cacheConfiguration: const BetterPlayerCacheConfiguration(
      useCache: true,
      maxCacheSize: 10 * 1024 * 1024,
    ),
  );
  ```
- **Subtitles & Closed Captions**: Pass SRT/WebVTT subtitles directly via `subtitles` configuration or `PlayerSubtitlesSource`.
- **ListView / RecyclerView Playback**: Optimized playback out of the box using `BetterPlayerListPlayerController`.
- **Picture-in-Picture (PiP)**: Built-in PiP support via `_betterPlayerController.enablePictureInPicture(...)`.
