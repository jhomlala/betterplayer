---
id: platform_support
title: Platform Support
---

# Platform Support

Better Player strives to provide a consistent and powerful playback experience across all supported platforms. However, due to underlying native video engine limitations, not all features are equally available across Android, iOS, and Web.

The following matrix details the current feature support for Better Player across platforms:

| Feature | Android | iOS | macOS | Web |
| :--- | :---: | :---: | :---: | :---: |
| **Basic Playback (MP4/WebM)** | ✓ | ✓ | ✓ | ✓ |
| **HLS (HTTP Live Streaming)** | ✓ | ✓ | ✓ | ✓ |
| **DASH (Dynamic Adaptive Streaming)**| ✓ | x | x | ✓ |
| **Smooth Streaming** | ✓ | x | x | x |
| **Subtitles (SRT/WebVTT)** | ✓ | ✓ | ✓ | ✓ |
| **Audio Track Selection** | ✓ | ✓ | ✓ | ✓ |
| **Picture in Picture (PiP)** | ✓ | ✓ | ✓ | ✓ |
| **DRM (Widevine)** | ✓ | x | x | ✓ |
| **DRM (FairPlay)** | x | ✓ | ✓ | ✓ |
| **DRM (ClearKey)** | ✓ | ✓ | ✓ | ✓ |
| **Caching (Normal)** | ✓ | ✓ | ✓ | x |
| **Pre-caching & Stop Caching** | ✓ | ✓ | ✓ | x |
| **Background Audio / Notifications** | ✓ | ✓ | x | x |
| **Mix Audio with Others** | ✓ | ✓ | ✓ | x |
| **Auto Frame Rate (AFR)** | ✓ | x | x | x |

## Platform Specific Details

### Android
* Android playback is powered by [ExoPlayer](https://exoplayer.dev/).
* Full support for almost all streaming formats and advanced DRM (Widevine, ClearKey, PlayReady).
* Built-in caching through native ExoPlayer cache systems.
* Support for **Auto Frame Rate (AFR)** matching via `_betterPlayerController.setAndroidMatchFrameRate(true)`, which syncs the display refresh rate to the video's frame rate.

### iOS
* iOS playback is powered by native `AVPlayer`.
* Native HLS support, but lacks DASH and Smooth Streaming support.
* FairPlay DRM is fully supported, whereas Widevine is not natively supported by Apple devices.

### macOS
* macOS playback is powered by native `AVPlayer` with `AppKitView` platform view rendering and FFI interop.
* Native HLS and progressive playback.
* FairPlay DRM and ClearKey are supported.
* Audio mixing is handled automatically by CoreAudio.
* Requires the App Sandbox network client entitlement (`com.apple.security.network.client`) for network streams.

### Web
* Web playback is powered by the open-source [Shaka Player](https://shaka-player-demo.appspot.com/docs/api/tutorial-welcome.html) library, connecting Flutter to web playback capabilities.
* To use Better Player on the web, you **must** include the Shaka Player library in your `web/index.html` file (see the [Installation](install.md) page).
* Background notifications and fine-grained caching (`preCache`) are not supported on standard web browsers.
