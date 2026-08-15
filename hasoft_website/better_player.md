---
layout: default
title: Better Player
---

# Better Player

**The most advanced and feature-rich video player for Flutter.**

Better Player is built on top of the official `video_player` plugin and inspired by `Chewie`. It solves common playback issues and handles complex media use cases out of the box.

## 🚀 Key Features

### 🎬 Advanced Playback
* **Adaptive Streaming**: Full support for **HLS**, **DASH**, and **Smooth Streaming**.
* **Smart Caching**: Seamlessly cache videos for offline playback.
* **Resolution Control**: Easy switching between video resolutions.

### 🛡️ Security
* **DRM Support**: Widevine, FairPlay, and ClearKey.
* **Secured Requests**: Support for custom HTTP Headers.

### 📱 User Experience
* **Picture in Picture (PiP)**: Native PiP for Android and iOS.
* **Background Playback**: Controls in system notifications.
* **Subtitles**: SRT and WebVTT support.

## 📦 Quick Start

Add to `pubspec.yaml`:
```yaml
dependencies:
  better_player: ^latest_version
```

Basic usage:
```dart
BetterPlayer.network(
  "https://example.com/video.mp4",
  betterPlayerConfiguration: BetterPlayerConfiguration(
    aspectRatio: 16 / 9,
    autoPlay: true,
  ),
)
```

## 📖 Links
* [Pub.dev](https://pub.dev/packages/better_player)
* [GitHub Repository](https://github.com/jhomlala/betterplayer)
* [Official Documentation](https://jhomlala.github.io/betterplayer/)
