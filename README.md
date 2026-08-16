<p align="center">
<img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/logo.png" width="250px">
</p>

# Better Player
### The most advanced and feature-rich video player for Flutter.

[![pub package](https://img.shields.io/pub/v/better_player.svg)](https://pub.dartlang.org/packages/better_player)
[![pub package](https://img.shields.io/github/license/jhomlala/betterplayer.svg?style=flat)](https://github.com/jhomlala/betterplayer)
[![pub package](https://img.shields.io/badge/platform-flutter-blue.svg)](https://github.com/jhomlala/betterplayer)

Better Player is a powerful video player for Flutter, built on top of the official `video_player` plugin and inspired by `Chewie`. It solves common playback issues, provides extensive configuration options, and handles complex media use cases out of the box.

---

## 📱 Visual Showcase

<table align="center">
   <tr>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/1.png"></td>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/3.png"></td>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/7.png"></td>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/9.png"></td>
   </tr>
   <tr align="center">
      <td><b>Default Controls</b></td>
      <td><b>Settings Menu</b></td>
      <td><b>Audio Tracks</b></td>
      <td><b>Event Listener</b></td>
   </tr>
</table>

---

## 🚀 Key Features

### 🎬 Advanced Playback
* **Adaptive Streaming**: Full support for **HLS**, **DASH**, and **Smooth Streaming** with track selection.
* **Resolution Control**: Easy switching between alternative video resolutions.
* **Smart Caching**: Seamlessly cache videos for high-performance offline playback.
* **Customizable UI**: Refactored controls that are highly customizable via configuration.

### 🛡️ Content Protection & Security
* **DRM Support**: Industry-standard protection with **Widevine**, **FairPlay**, and **ClearKey**.
* **Secured Requests**: Full support for custom HTTP Headers for authenticated streams.

### 📱 User Experience
* **Picture in Picture (PiP)**: Native PiP support for multitasking on Android and iOS.
* **Background Notifications**: Rich media notifications for background control.
* **Subtitle Engine**: Advanced support for SRT and WebVTT with HTML tags.
* **Playlist Support**: Built-in support for multiple videos and continuous playback.
* **Playback Speed**: Native support for changing playback speed.

### 🛠️ Developer Friendly
* **ListView Integration**: Optimized for smooth playback within scrolling lists.
* **Lifecycle Aware**: Automatically handles player disposal and lifecycle changes.
* **Event System**: Comprehensive event listener for tracking every player state.

---

## 📦 Quick Start

### 1. Add dependency
Add Better Player to your `pubspec.yaml`:
```yaml
dependencies:
  better_player: ^latest_version
```

### 2. Basic Usage
The simplest way to play a video is using the network factory:

```dart
import 'package:better_player/better_player.dart';

// Inside your build method
AspectRatio(
  aspectRatio: 16 / 9,
  child: BetterPlayer.network(
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    betterPlayerConfiguration: BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      looping: true,
      autoPlay: true,
    ),
  ),
)
```

### 3. Advanced Controller Usage
For full control, use the `BetterPlayerController`:

```dart
BetterPlayerController _controller = BetterPlayerController(
    const BetterPlayerConfiguration(),
    betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        "https://example.com/video.mp4",
    ),
);

BetterPlayer(controller: _controller)
```

---

## 🔄 Migration Guides
Switching from another package? Check out our step-by-step migration guides:
* 🚀 [Migrating from `video_player`](https://jhomlala.github.io/betterplayer/#/migration_from_video_player)
* 🚀 [Migrating from `chewie`](https://jhomlala.github.io/betterplayer/#/migration_from_chewie)

---

## 📖 Resources
* 📄 [Official Documentation](https://jhomlala.github.io/betterplayer/)
* 📱 [Example Application](https://github.com/jhomlala/betterplayer/tree/master/example)
* 📚 [API Reference](https://pub.dev/documentation/better_player/latest/better_player/better_player-library.html)

---

## 🤝 Contributing
Valuable contributions are welcome! Better Player is a community-driven project. If you encounter bugs or have feature requests, please open an issue. If you want to contribute code, feel free to submit a Pull Request.

## 📄 License
This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
