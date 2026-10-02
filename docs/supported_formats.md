---
id: supported_formats
title: Supported Formats
---

# Supported Formats & Codecs

Better Player uses the native media players for each platform: **ExoPlayer (Media3)** on Android, **AVPlayer (AVFoundation)** on iOS and macOS, and **Shaka Player** on the Web. 

Because we rely on these native engines without applying custom decoding, **Better Player supports whatever formats the underlying platform player supports**.

Here is a comprehensive breakdown of supported formats, streaming protocols, and codecs across platforms.

---

## 1. Streaming Protocols

| Protocol | Android | iOS / macOS | Web |
|---|---|---|---|
| **HLS (HTTP Live Streaming)** | ✓ | ✓ (Native) | ✓ |
| **MPEG-DASH** | ✓ | x | ✓ |
| **SmoothStreaming (MSS)** | ✓ | x | ✓ |
| **RTSP** | ✓ | x | x |
| **Progressive HTTP (MP4, WebM…)**| ✓ | ✓ | ✓ |
| **Low-latency HLS (LL-HLS)** | ✓ | ✓ (iOS 15+, macOS 12+) | ✓ |
| **Low-latency DASH** | ✓ | x | ✓ |

> **Note on Apple platforms (iOS & macOS):** Apple platforms are heavily HLS-centric. Apple does not provide native support for DASH or SmoothStreaming in AVFoundation. If you need to support iOS or macOS, HLS is strongly recommended.
> 
> **Note on RTSP:** RTSP streaming is supported on Android via the ExoPlayer RTSP module. Native support for RTSP is not available on Apple platforms (`AVPlayer`) or Web, and typically requires server-side proxying (e.g. transmuxing to WebRTC or HLS).

---

## 2. Video Codecs

| Codec | Android | iOS / macOS | Web (Chrome) | Web (Safari) | Web (Firefox) |
|---|---|---|---|---|---|
| **H.264 / AVC** | ✓ All devices | ✓ | ✓ | ✓ | ✓ |
| **H.265 / HEVC** | ⚠️ HW only (Android 5+) | ✓ (A9+, Apple Silicon, Intel) | ⚠️ Limited | ✓ (Safari 11+) | x |
| **VP8** | ✓ | x | ✓ | x | ✓ |
| **VP9** | ✓ (Android 4.4+) | ⚠️ Safari 14+ | ✓ | ✓ (Safari 14+) | ✓ |
| **AV1** | ⚠️ HW only (Android 10+) | ⚠️ iOS 17+, macOS 14+ | ✓ | ⚠️ Safari 17+ | ✓ |
| **MPEG-4 / H.263** | ✓ (Legacy) | ✓ | ⚠️ | x | ⚠️ |

> **Recommendation:** **H.264 Baseline/Main/High** is the only universal codec that guarantees safe playback across all old and new devices across all platforms.

---

## 3. Audio Codecs

| Codec | Android | iOS / macOS | Web |
|---|---|---|---|
| **AAC-LC** | ✓ | ✓ | ✓ |
| **AAC-HE v1 / v2** | ✓ | ✓ | ✓ |
| **MP3** | ✓ | ✓ | ✓ |
| **Opus** | ✓ | ✓ (iOS 11+, macOS 10.13+) | ✓ |
| **Vorbis** | ✓ | x | ✓ |
| **FLAC** | ✓ (Android 3.1+) | ✓ | ✓ |
| **AC-3 / E-AC-3 (Dolby)** | ⚠️ Passthrough / HW | ✓ | ⚠️ Browser-dependent|
| **ALAC** | ✓ | ✓ | x |
| **PCM / WAV** | ✓ | ✓ | ✓ |

---

## 4. Container Formats

| Container | Android | iOS / macOS | Web |
|---|---|---|---|
| **MP4 / M4V** | ✓ | ✓ | ✓ |
| **fMP4 (Fragmented MP4)** | ✓ | ✓ | ✓ |
| **WebM** | ✓ | x | ✓ |
| **MKV (Matroska)** | ✓ | x | x |
| **MPEG-TS (.ts)** | ✓ via HLS | ✓ via HLS | ✓ via HLS |
| **OGG** | ✓ | x | ✓ |
| **MOV (QuickTime)** | ⚠️ Limited | ✓ | x |

---

## 5. DRM (Digital Rights Management)

| DRM System | Android | iOS / macOS | Web |
|---|---|---|---|
| **Widevine L1/L3** | ✓ | x | ✓ (Chrome, Firefox) |
| **FairPlay (FPS)** | x | ✓ | ✓ (Safari only) |
| **PlayReady** | x | x | ⚠️ (Edge only) |
| **ClearKey** | ✓ | ✓ (HLS AES-128) | ✓ |

> **Note on Multi-DRM:** To achieve full cross-platform DRM coverage, your backend streaming architecture must provide both **Widevine** (for Android and Chrome/Web) and **FairPlay** (for iOS, macOS, and Safari) in parallel.

---

## 6. Subtitle & Caption Formats

Subtitle handling is broken down into two distinct categories in Better Player: external subtitles (parsed by Flutter) and in-stream embedded subtitles (parsed by the native player).

### External Subtitles (Flutter Layer)
These formats are loaded manually via `PlayerSubtitlesSource` and rendered using Better Player's custom Flutter UI overlay. **They behave identically across all platforms.**

| Format | Support | Notes |
|---|---|---|
| **SRT (SubRip)** | ✓ Full | Plain text, no styling. |
| **WebVTT** | ✓ Full | Supports inline styling (`<b>`, `<i>`, `<c.color>`), HTML entity decoding, and `X-TIMESTAMP-MAP` sync for HLS live streams. |

### Embedded / In-Stream Subtitles (Native Layer)
These tracks are embedded directly inside the HLS/DASH manifest or MP4 file. They are rendered natively by ExoPlayer/AVPlayer/Shaka, **not** by the Flutter overlay. 

| Format | Android | iOS / macOS | Web (Shaka) |
|---|---|---|---|
| **WebVTT (in HLS / DASH)** | ✓ | ✓ | ✓ |
| **TTML / DFXP** | ✓ | ✓ | ✓ |
| **CEA-608 (EIA-608)** | ✓ | ✓ | ✓ |
| **CEA-708** | ✓ | ✓ | ✓ |
| **SMPTE-TT** | ✓ | x | ⚠️ |
| **SubStation Alpha (SSA)** | x | x | x |

> ⚠️ **Important:** Because embedded subtitles are rendered by the native player's surface (below the Flutter widget tree), they **cannot** be customized using Better Player's `PlayerSubtitlesConfiguration`.

---

## Reference Links

* **Android (ExoPlayer):** [ExoPlayer Supported Formats](https://developer.android.com/media/media3/exoplayer/supported-formats)
* **iOS & macOS (AVFoundation):** [Apple HTTP Live Streaming Overview](https://developer.apple.com/documentation/http-live-streaming) and [Apple Supported Media Formats](https://developer.apple.com/documentation/technotes/tn3136-iosipados-supported-media-formats)
* **Web (Shaka Player):** [Shaka Player Project](https://github.com/shaka-project/shaka-player)
