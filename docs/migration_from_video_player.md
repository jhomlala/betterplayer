---
id: migration_from_video_player
title: Migrating from video_player
---

# Migrating from `video_player`

While Flutter's official `video_player` plugin provides a low-level primitive for video playback, building a production-ready media experience often requires implementing custom controls, caching, subtitles, HLS/DASH adaptive streaming, Picture-in-Picture (PiP), and list view optimizations from scratch.

**Better Player** is built on top of robust foundations (extending core video player architecture) and provides all these features out of the box with a rich, modern UI and extensive configuration options.

This guide outlines step-by-step instructions on how to migrate your existing project from `video_player` to `better_player`.

---

## Step 1: Update `pubspec.yaml`

Remove `video_player` from your dependencies and add `better_player`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Remove this line:
  # video_player: ^x.y.z
  
  # Add this line:
  better_player: ^1.2.0
```

Run `flutter pub get` in your terminal to update dependencies.

---

## Step 2: Update Imports

Replace all `video_player` imports across your Dart files with `better_player`:

```dart
// Remove:
// import 'package:video_player/video_player.dart';

// Add:
import 'package:better_player/better_player.dart';
```

---

## Step 3: Code Migration Examples

### 1. Controller Initialization

#### `video_player` approach:
```dart
late VideoPlayerController _controller;

@override
void initState() {
  super.initState();
  _controller = VideoPlayerController.networkUrl(
    Uri.parse('https://example.com/video.mp4'),
  )..initialize().then((_) {
      setState(() {});
    });
}
```

#### `better_player` approach:
Better Player encapsulates data source configuration, caching, headers, and initialization cleanly using `BetterPlayerController` and `PlayerDataSource`:

```dart
late BetterPlayerController _betterPlayerController;

@override
void initState() {
  super.initState();
  
  PlayerDataSource dataSource = PlayerDataSource(
    DataSourceType.network,
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

#### `video_player` approach:
In `video_player`, you have to manually wrap the video with aspect ratio widgets and implement your own player controls or use a package like Chewie.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(),
    ),
  );
}
```

#### `better_player` approach:
`BetterPlayer` provides a fully featured, customizable playback UI with controls, loading indicators, full-screen switching, subtitles, and overflow menus right out of the box.

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

Both controllers need to be disposed properly when the widget is removed from the widget tree.

#### `video_player`:
```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

#### `better_player`:
```dart
@override
void dispose() {
  _betterPlayerController.dispose();
  super.dispose();
}
```

---

## Step 4: Platform-Specific Requirements

Make sure your project meets the platform configuration requirements specified in [Installation](install):

- **iOS**: Minimum deployment target set to **iOS 13.0** and Swift 5.
- **Android**: `compileSdkVersion` set to **36** and MultiDex enabled.

---

## Step 5: Unlock Advanced Features

Now that you are using `better_player`, you can easily enable advanced features that required complex custom code in `video_player`:

- **Caching**: Enable video caching with a single configuration flag:
  ```dart
  PlayerDataSource(
    DataSourceType.network,
    'https://example.com/video.mp4',
    cacheConfiguration: const CacheConfiguration(
      useCache: true,
      maxCacheSize: 10 * 1024 * 1024,
      maxCacheFileSize: 10 * 1024 * 1024,
    ),
  );
  ```
- **Subtitles**: Add SRT or WebVTT subtitles effortlessly via `PlayerSubtitlesSource`.
- **HLS / DASH Adaptive Streaming**: Pass adaptive streaming URLs directly into `DataSourceType.network`. Note: DASH is currently only supported on Android.
- **Picture-in-Picture (PiP)**: Enable PiP support with built-in controls and state listeners.
