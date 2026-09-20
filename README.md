<p align="center">
<img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/logo.png" width="250px">
</p>

# Better Player

[![pub package](https://img.shields.io/pub/v/better_player.svg)](https://pub.dartlang.org/packages/better_player)
[![pub package](https://img.shields.io/github/license/jhomlala/betterplayer.svg?style=flat)](https://github.com/jhomlala/betterplayer)
[![pub package](https://img.shields.io/badge/platform-flutter-blue.svg)](https://github.com/jhomlala/betterplayer)

Better Player handles the complex video playback edge cases so you don't have to. Originally based on `video_player`, it's now fully independent. It tackles HLS, DRM, and caching out of the box.

> **[IMPORTANT] Migrating from 0.0.84 to 1.x.x?**
> See the [Migration Guides](#-migration-guides) section below.

---

## 📱 Visual Showcase

<table align="center">
   <tr>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/1.png"></td>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/3.png"></td>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/7.png"></td>
      <td><img width="200px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/assets/media/9.png"></td>
   </tr>
   <tr align="center">
      <td><b>Default Controls</b></td>
      <td><b>Settings Menu</b></td>
      <td><b>Audio Tracks</b></td>
      <td><b>Event Listener</b></td>
   </tr>
</table>

---

## 🏆 vs Competitors

Why choose Better Player? Here is how it stacks up against the alternatives.

| Feature | Better Player | video_player | chewie | media_kit |
|---|:---:|:---:|:---:|:---:|
| **Engine** | ExoPlayer/AVPlayer/Shaka | ExoPlayer/AVPlayer | video_player | libmpv |
| **UI Controls** | ✅ Built-in & Customizable | ❌ None | ✅ Built-in | ✅ Built-in |
| **HLS / DASH** | ✅ Native | ⚠️ Basic | ⚠️ Basic | ✅ Native |
| **DRM Support** | ✅ Widevine/FairPlay/ClearKey | ❌ None | ❌ None | ❌ None |
| **Subtitles** | ✅ Advanced (WebVTT, HTML, SRT) | ⚠️ Basic (SRT only) | ⚠️ Basic | ✅ Advanced |
| **Caching** | ✅ Built-in | ❌ None | ❌ None | ❌ None |
| **Playlists** | ✅ Built-in | ❌ None | ❌ None | ✅ Built-in |

---

## 🚀 Key Features

- **Adaptive Streaming**: Play HLS, DASH, and Smooth Streaming with automatic track selection.
- **DRM Support**: Protect your content with Widevine, FairPlay, and ClearKey.
- **Smart Caching**: Cache videos for seamless offline playback.
- **Picture in Picture (PiP)**: Keep videos playing while users multitask.
- **Advanced Subtitles**: Parse SRT and WebVTT, including HTML tags.

---

## 📦 Quick Start

### 1. Add dependency
Add Better Player to your `pubspec.yaml`:
```yaml
dependencies:
  better_player: ^1.12.0
```

### 2. Basic Usage
Use the network factory to get a player up and running fast.

```dart
import 'package:better_player/better_player.dart';

// Inside your build method
AspectRatio(
  aspectRatio: 16 / 9,
  child: BetterPlayer.network(
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    betterPlayerConfiguration: PlayerConfiguration(
      aspectRatio: 16 / 9,
      looping: true,
      autoPlay: true,
    ),
  ),
)
```

### 3. Advanced Controller Usage
Need full control? Initialize a `BetterPlayerController` manually.

```dart
BetterPlayerController _controller = BetterPlayerController(
    const PlayerConfiguration(),
    betterPlayerDataSource: PlayerDataSource(
        DataSourceType.network,
        "https://example.com/video.mp4",
    ),
);

BetterPlayer(controller: _controller)
```

---

## 🤖 AI Agent Quick Reference

Writing a script or prompt? Feed this to your AI to get the right code on the first try.

- **Initialization**: Always initialize `BetterPlayerController` in `initState()` with a `PlayerConfiguration` and `PlayerDataSource`.
- **Core Classes**:
  - `BetterPlayerController`: Manages state and configuration.
  - `PlayerDataSource`: Wraps video URL, DRM config, subtitles, headers.
  - `PlayerConfiguration`: UI, looping, autoPlay, aspect ratio.
  - `PlayerControlsConfiguration`: Colors, icons, padding for the control bar.
- **Subtitles**: Pass `PlayerSubtitlesSource` directly into `PlayerDataSource`.
- **Disposal**: Default is `autoDispose: true`. Avoid manual `controller.dispose()` unless you opt out.

---

## 🔄 Migration Guides

Moving from another package? Follow these guides:
- [Migrating from `video_player`](https://jhomlala.github.io/betterplayer/migration_from_video_player)
- [Migrating from `chewie`](https://jhomlala.github.io/betterplayer/migration_from_chewie)
- [Migrating from 0.0.84 to 1.x.x](https://jhomlala.github.io/betterplayer/migration_to_1.x.x)

---

## 📖 Resources

- [Official Documentation](https://jhomlala.github.io/betterplayer/)
- [Example Application](https://github.com/jhomlala/betterplayer/tree/master/packages/better_player_example)
- [API Reference](https://pub.dev/documentation/better_player/latest/better_player/better_player-library.html)

---

## 🤝 Contributing

Bugs? Feature requests? Open an issue. Better yet, submit a PR.

## 💼 Enterprise Support

Need a custom video source adapter, bespoke DRM implementation, or tailored UI controls? I'm available for consulting.

[Let's talk on LinkedIn →](https://pl.linkedin.com/in/jhomlala)
