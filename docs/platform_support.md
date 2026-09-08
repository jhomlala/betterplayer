---
id: platform_support
title: Platform Support
---

# Platform Support

Better Player strives to provide a consistent and powerful playback experience across all supported platforms. However, due to underlying native video engine limitations, not all features are equally available across Android, iOS, and Web.

The following matrix details the current feature support for Better Player across platforms:

| Feature | Android | iOS | Web |
| :--- | :---: | :---: | :---: |
| **Basic Playback (MP4/WebM)** | ✓ | ✓ | ✓ |
| **HLS (HTTP Live Streaming)** | ✓ | ✓ | ✓ |
| **DASH (Dynamic Adaptive Streaming)**| ✓ | x | ✓ |
| **Smooth Streaming** | ✓ | x | x |
| **Subtitles (SRT/WebVTT)** | ✓ | ✓ | ✓ |
| **Audio Track Selection** | ✓ | ✓ | ✓ |
| **Picture in Picture (PiP)** | ✓ | ✓ | ✓ |
| **DRM (Widevine)** | ✓ | x | ✓ |
| **DRM (FairPlay)** | x | ✓ | ✓ |
| **DRM (ClearKey)** | ✓ | ✓ | ✓ |
| **Caching (Normal)** | ✓ | ✓ | x |
| **Pre-caching & Stop Caching** | ✓ | ✓ | x |
| **Background Audio / Notifications** | ✓ | ✓ | x |
| **Mix Audio with Others** | ✓ | ✓ | x |

## Platform Specific Details

### Android
* Android playback is powered by [ExoPlayer](https://exoplayer.dev/).
* Full support for almost all streaming formats and advanced DRM (Widevine, ClearKey, PlayReady).
* Robust caching capabilities through native ExoPlayer cache systems.

### iOS
* iOS playback is powered by native `AVPlayer`.
* Native HLS support, but lacks DASH and Smooth Streaming support.
* FairPlay DRM is fully supported, whereas Widevine is not natively supported by Apple devices.

### Web
* Web playback is powered by the open-source [Shaka Player](https://shaka-player-demo.appspot.com/docs/api/tutorial-welcome.html) library, seamlessly bridging Flutter to advanced web playback capabilities.
* To use Better Player on the web, you **must** include the Shaka Player library in your `web/index.html` file (see the [Installation](install.md) page).
* Background notifications and fine-grained caching (`preCache`) are not supported on standard web browsers.
