# Windows Architecture & Testing Guidelines

This document outlines the architecture, rendering pipeline, and E2E testing strategy for the Windows federated package (`packages/better_player_windows`).

---

## Architecture: Dedicated Federated Package

Better Player uses a federated architecture. Windows is implemented as a standalone package: `packages/better_player_windows`.

### Engine: `libmpv` (FFmpeg-backed)

Windows desktop playback is powered by `libmpv`:
* **Broad format coverage**: Native playback for HLS (`.m3u8`), MPEG-DASH (`.mpd`), RTSP, and progressive containers (MP4, MKV, WebM).
* **Direct FFI communication**: Playback commands, seeking, volume, and property observation run directly in Dart via `dart:ffi`.
* **Zero blast radius**: Keeping `better_player_windows` isolated guarantees zero regressions for Android, iOS, macOS, and Web workflows.

---

## Video Rendering: Direct3D 11 (`flutter::GpuBufferTexture`)

Flutter Windows does not support native `PlatformView` embedding in the widget tree. Instead, `better_player_windows` uses Flutter's `TextureRegistrar`:

* **Direct3D 11 Shared Surfaces**: `TextureBridge` creates an `ID3D11Texture2D` shared surface and exposes it to Flutter's GPU compositor via `flutter::GpuBufferTexture`.
* **Zero Frame Copying**: Frames are rendered directly by `mpv_render_context` into the GPU surface without copying pixel buffers across CPU/GPU boundaries.
* **Fallback**: Supports software WARP rasterization if hardware acceleration is unavailable.

---

## E2E Testing Strategy

### The Solution: Flutter `package:integration_test`

E2E testing on Windows is handled by Flutter's built-in `integration_test` framework:

```bash
# Run full suite (builds once)
flutter test integration_test/windows_all_tests.dart -d windows

# Or run an individual suite
flutter test integration_test/windows_flow_test.dart -d windows
```

1. Compiles the real Windows `.exe` binary.
2. Spawns the native desktop window.
3. Interacts with the player UI using the exact `Semantics(identifier: ...)` IDs used across all platforms.
4. Executes real video playback, buffering, seeks, speed, volume, and quality switching.
5. Runs in GitHub Actions `windows-latest` runners.

### Test Suite Parity (1:1 with macOS, Mobile, and Web)

Windows replicates the 5 standard Better Player test suites:

| Suite | File | What it verifies |
|---|---|---|
| **Core Flow** | `windows_flow_test.dart` | Play, pause, skip ±15s, mute, speed, resolution, subtitles, seek bar, Cupertino/Material theme swap. |
| **HLS Stream** | `windows_hls_test.dart` | Adaptive bitrate, variant switching, live streams. |
| **Data Source Swap** | `windows_datasource_swap_test.dart` | Dynamic URL changes, key handling, aspect ratio reactivity. |
| **Error Recovery** | `windows_error_recovery_test.dart` | Invalid streams, error callbacks, retry behavior. |
| **Native FFI** | `windows_ffi_test.dart` | Direct FFI method calls (`play`, `pause`, `seekTo`, `setVolume`, `setSpeed`, `setTrack`). |

---

## CI Workflow

* **CI Workflow**: `.github/workflows/e2e_windows.yml` runs on `windows-latest`, building the example app and executing `windows_all_tests.dart`.
