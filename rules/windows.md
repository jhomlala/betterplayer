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

## Video Rendering: PixelBufferTexture with Hardware Acceleration

Flutter Windows does not support native `PlatformView` embedding in the widget tree. Instead, `better_player_windows` uses Flutter's `TextureRegistrar`:

* **Pixel Buffer Texture**: `TextureBridge` registers a `flutter::PixelBufferTexture` with `flutter::TextureRegistrar` to stream frames into Flutter's compositor.
* **Hardware Decoding (`hwdec=auto-safe`)**: `mpv` enables GPU video decoding (DXVA2 or D3D11VA via FFmpeg) when supported by the hardware, falling back to software decoding when necessary.
* **Thread Safety**: Texture unregistration during disposal executes outside mutex locks to prevent deadlocks between the platform and raster threads.

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

Windows desktop test suites:

| Suite | File | What it verifies |
|---|---|---|
| **Core Flow** | `windows_flow_test.dart` | Play, pause, keyboard seek, mute, speed, resolution, subtitles, seek bar, Web/Material theme swap. |
| **HLS Stream** | `windows_hls_test.dart` | Adaptive bitrate, variant switching, live streams. |
| **Data Source Swap** | `windows_datasource_swap_test.dart` | Dynamic URL changes, key handling, aspect ratio reactivity. |
| **Error Recovery** | `windows_error_recovery_test.dart` | Invalid streams, error callbacks, retry behavior. |
| **Native FFI** | `windows_ffi_test.dart` | Direct FFI method calls (`play`, `pause`, `seekTo`, `setVolume`, `setSpeed`, `setTrack`). |
| **Shortcuts & Mouse** | `windows_shortcuts_test.dart` | Desktop hotkeys (Space/K play-pause, Left/Right seek, Up/Down volume, M mute) and mouse hover. |
| **Local File** | `windows_local_file_test.dart` | Local filesystem video playback (`DataSourceType.file`), native Windows file path loading. |

---

## CI Workflow

* **CI Workflow**: `.github/workflows/e2e_windows.yml` runs on `windows-latest`, building the example app and executing `windows_all_tests.dart`.
