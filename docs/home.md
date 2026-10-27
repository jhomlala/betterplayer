---
id: home
title: Introduction
slug: /
---

import useBaseUrl from '@docusaurus/useBaseUrl';

<div style={{textAlign: 'center', marginBottom: '2rem'}}>
  <img src={useBaseUrl('/img/logo.png')} alt="Better Player Logo" width="120" style={{borderRadius: '1rem', marginBottom: '1rem'}} />
</div>

# Better Player

Better Player is the complete, production-grade video player for Flutter. It provides native OS performance, multi-platform support (Android, iOS, macOS, Windows, Linux, Web), and built-in commercial streaming features including HLS/DASH adaptive bitrate switching, Widevine and FairPlay DRM, offline caching, VAST/VMAP advertising, and short-form video feeds.

## Key Features

Better Player provides a robust set of features designed for production-ready applications:

*   **Reliability**: Fixes for common bugs found in other players.
*   **Advanced Configuration**: Granular control over player behavior and appearance.
*   **Refactored Controls**: Modern, customizable user interface.
*   **Playlist Support**: Play sequences of videos continuously.
*   **Feed & List Pooling**: High-performance vertical swipe feeds (`BetterPlayerFeed`) and bounded controller pooling (`BetterPlayerPool`) to prevent hardware decoder exhaustion.
*   **Comprehensive Subtitles**: Support for SRT and WebVTT formats (with HTML tags), TTML, HLS segmented subtitles, and multiple subtitle tracks.
*   **Adaptive Streaming**: Full support for HLS and DASH, including track, subtitle, and audio track selection.
*   **Performance & Optimization**: Integrated cache support and alternative resolution selection.
*   **Advanced Capabilities**: Support for Picture-in-Picture (PiP), DRM (Token, Widevine, FairPlay EZDRM), and custom HTTP headers.
*   **VAST & VMAP Ads**: Client-side linear video ads (VAST 2.0/3.0/4.x, VMAP) with dual-texture player stacking, tracking beacons, and custom UI overlays (see [VAST & VMAP Ads](vast_vmap_ads.md)).
*   **Dynamic Watermarking & Screen Shield**: Forensic viewer overlays and native OS screen capture protection across Android, iOS, macOS, and Windows (see [Dynamic Watermarking & Screen Shield](enterprise_watermarking.md)).
*   **Platform Features**: Native notifications and comprehensive BoxFit support.
*   **macOS Support**: Dedicated desktop playback powered by native AVPlayer, AppKitView, and FFI bindings.
*   **Windows Support**: Desktop playback powered by libmpv and Direct3D 11 texture sharing.
*   **Linux Support**: Desktop playback powered by libmpv and FlPixelBufferTexture.
*   **Web Support**: Advanced web playback using Shaka Player for HLS, DASH, and DRM.
*   ... and much more! See the detailed [Platform Support](platform_support.md) matrix.

## Migration Guides

Switching from another package? Follow our step-by-step migration guides:

*   **[Migrating from video_player](migration_from_video_player.md)**: Replace `VideoPlayerController` and remove separate UI packages.
*   **[Migrating from chewie](migration_from_chewie.md)**: Consolidate your player and controls into a single controller.
*   **[Migrating from media_kit](migration_from_media_kit.md)**: Reclaim 30-50 MB of mobile app size and switch to native OS media engines.
*   **[Migrating to 1.x.x (from 0.0.84 & better_player_plus)](migration_to_1.x.x.md)**: Upgrade from legacy 0.0.84 or community forks (`better_player_plus`, `better_player_enhanced`) using automated `dart fix`.

## Important Information

:::important
Better Player is currently under active development. While we aim for stability, breaking changes may occur between versions.
:::

This plugin is developed as a community-driven project. If you require a feature that is currently missing or supported by other players on pub.dev, we highly encourage you to submit a Pull Request. All valuable contributions are welcome!

## Screenshots

| Mobile Overview | Native Picture-in-Picture (PiP) |
|:---:|:---:|
| ![Android](./static/img/screenshots/android_01_overview.png) | ![PiP](./static/img/screenshots/android_05_pip.png) |

| Web & Desktop Overview | Touch & Fullscreen Controls |
|:---:|:---:|
| ![Web and Desktop](./static/img/screenshots/web_01_overview_dark.png) | ![Fullscreen](./static/img/screenshots/android_04_fullscreen.png) |

| Adaptive HLS Quality & Track Switching | Styled Subtitles (WebVTT / TTML / SRT) |
|:---:|:---:|
| ![HLS Tracks](./static/img/screenshots/web_05_hls_tracks.png) | ![Subtitles](./static/img/screenshots/web_04_subtitles.png) |
