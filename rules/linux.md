# Linux Architecture & Testing Guidelines

This document outlines the architecture, rendering pipeline, and E2E testing strategy for the Linux federated package (`packages/better_player_linux`).

---

## Architecture: Dedicated Federated Package

Better Player uses a federated architecture. Linux is implemented as a standalone package: `packages/better_player_linux`.

### Engine: `libmpv` (FFmpeg-backed)

Linux desktop playback is powered by `libmpv`:
* **Broad format coverage**: Native playback for HLS (`.m3u8`), MPEG-DASH (`.mpd`), RTSP, and progressive containers (MP4, MKV, WebM).
* **Direct FFI communication**: Playback commands, seeking, volume, and property observation run directly in Dart via `dart:ffi`.
* **Dynamic library loading**: Dynamically resolves `libmpv.so.2`, `libmpv.so.1`, or `libmpv.so` without hardcoded path dependencies.
* **Zero blast radius**: Keeping `better_player_linux` isolated guarantees zero regressions for Android, iOS, macOS, Windows, and Web workflows.

---

## Video Rendering: FlPixelBufferTexture with Hardware Acceleration

Flutter Linux uses the GTK embedding API (`<flutter_linux/flutter_linux.h>`):

* **Pixel Buffer Texture**: `TextureBridge` registers a GObject deriving from `FlPixelBufferTexture` with `FlTextureRegistrar` to stream video frames into Flutter's compositor.
* **Hardware Decoding (`hwdec=auto-safe`)**: `mpv` enables GPU video decoding (VAAPI, NVDEC, or VDPAU via FFmpeg) when supported by the hardware, falling back to software decoding when necessary.
* **Thread Safety**: Texture unregistration during disposal executes outside mutex locks to prevent deadlocks between the GTK platform thread and the Flutter raster thread.

---

## E2E Testing Strategy

### The Solution: Flutter `package:integration_test` with `xvfb-run`

E2E testing on Linux is handled by Flutter's built-in `integration_test` framework running headlessly in virtual framebuffer:

```bash
# Run full suite headlessly
xvfb-run -a flutter test integration_test/linux_all_tests.dart -d linux

# Or run an individual suite
xvfb-run -a flutter test integration_test/linux_flow_test.dart -d linux
```

1. Compiles the real Linux binary using CMake and Ninja.
2. Spawns the GTK desktop window inside `xvfb`.
3. Interacts with the player UI using the exact `Semantics(identifier: ...)` IDs used across all platforms.
4. Executes real video playback, buffering, seeks, speed, volume, and quality switching.
5. Runs in GitHub Actions `ubuntu-latest` runners.

### Test Suite Parity (1:1 with Windows, macOS, Mobile, and Web)

Linux desktop test suites:

| Suite | File | What it verifies |
|---|---|---|
| **Core Flow** | `linux_flow_test.dart` | Play, pause, keyboard seek, mute, speed, resolution, subtitles, seek bar, Web/Material theme swap. |
| **HLS Stream** | `linux_hls_test.dart` | Adaptive bitrate, variant switching, live streams. |
| **Data Source Swap** | `linux_datasource_swap_test.dart` | Dynamic URL changes, key handling, aspect ratio reactivity. |
| **Error Recovery** | `linux_error_recovery_test.dart` | Invalid streams, error callbacks, retry behavior. |
| **Native FFI** | `linux_ffi_test.dart` | Direct FFI method calls (`play`, `pause`, `seekTo`, `setVolume`, `setSpeed`, `setTrack`). |
| **Shortcuts & Mouse** | `linux_shortcuts_test.dart` | Desktop hotkeys (Space/K play-pause, Left/Right seek, Up/Down volume, M mute) and mouse hover. |
| **Local File** | `linux_local_file_test.dart` | Local filesystem video playback (`DataSourceType.file`), native Linux file path loading. |

---

## CI Workflow

* **CI Workflow**: `.github/workflows/e2e_linux.yml` runs on `ubuntu-latest`, installing `libgtk-3-dev` and `libmpv-dev`, building the example app, and executing `linux_all_tests.dart` via `xvfb-run`.
