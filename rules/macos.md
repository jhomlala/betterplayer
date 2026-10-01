# macOS Architecture & Testing Guidelines

This document outlines the architecture, code-sharing model, rendering pipeline, and E2E testing strategy for the macOS federated package (`packages/better_player_macos`).

---

## Architecture: Dedicated Federated Package

Better Player uses a federated architecture. macOS is implemented as a standalone package: `packages/better_player_macos`.

### Why an Isolated Package Instead of Unified Darwin

While Apple platforms share Foundation and AVFoundation, unifying them into a single `better_player_darwin` package introduces severe fragility:

* **`swiftgen` Clang AST parsing conflicts:** `package:swiftgen` compiles Swift source against a single SDK target at a time (`iphoneos` or `macosx`). Introducing `#if os(macOS)` or AppKit imports into iOS Swift files risks dropping Objective-C protocol metadata or failing AST generation on CI.
* **CocoaPods dependency collision:** iOS requires `s.dependency 'Flutter'`, while macOS requires `s.dependency 'FlutterMacOS'`. Splitting these cleanly in a shared podspec across different Flutter SDK versions is notoriously brittle.
* **Regex string-patching fragility:** [`swiftgen.dart`](file:///C:/Users/jhoml/betterplayer/packages/better_player_ios/tool/swiftgen.dart) relies on exact string replacements (`NSProtocolFromString`, module headers, force-load symbols). Changing directory layouts or package namespaces breaks iOS FFI generation.
* **Zero blast radius:** Keeping `better_player_ios` untouched guarantees zero regressions for iOS production builds and CI workflows.

---

## Code Sharing Strategy: Source of Truth + Sync Script

To avoid maintaining duplicate logic across iOS and macOS while keeping packages self-contained for pub.dev:

1. **`better_player_ios` is the single source of truth** for core Apple playback logic.
2. Shared files are maintained in `better_player_ios` and synced to `better_player_macos` via `scripts/sync_apple_core.dart`.

### File Categorization

| File | Status | Rationale |
|---|---|---|
| `BetterPlayerApi.swift` | **Shared** (Synced) | FFI interface and player registry. Pure Foundation. |
| `BetterPlayerEzDrmAssetsLoaderDelegate.swift` | **Shared** (Synced) | FairPlay DRM key loading via `AVAssetResourceLoaderDelegate`. Identical on macOS. |
| `BetterPlayerTimeUtils.swift` | **Shared** (Synced) | CoreMedia time conversion utilities. |
| `CacheManager.swift` | **Shared** (Synced) | Disk/memory caching logic via `Cache` package. |
| `CachingPlayerItem.swift` | **Shared** (Synced) | Custom AVAssetResourceLoader byte range interception. |
| `BetterPlayerView.swift` | **Platform-specific** | Inherits `NSView` on macOS (with `wantsLayer = true` and `layer = AVPlayerLayer()`), vs `UIView` on iOS. |
| `BetterPlayerPlugin.swift` | **Platform-specific** | Implements `FlutterPlatformViewFactory` returning an `NSView`. |
| `BetterPlayer.swift` | **Platform-specific** | macOS version strips `AVAudioSession` calls and uses native PiP/window management. |

### Sync Script Workflow

Run whenever shared files in `better_player_ios` change:

```bash
dart run scripts/sync_apple_core.dart
```

---

## Video Rendering: Platform View (`AppKitView`)

`better_player_macos` uses `AppKitView` backed by `AVPlayerLayer` rather than `FlutterTexture`:

* **Hardware FairPlay DRM:** Protected content decrypts in hardware directly into the GPU compositor. Apple blocks reading pixel buffers from DRM streams, making `FlutterTexture` incompatible with FairPlay.
* **Zero Frame Copying:** Frames composite natively via Metal/Quartz without copying `CVPixelBuffer` data to system memory.
* **Picture in Picture:** Native integration with `AVPictureInPictureController(playerLayer:)`.

---

## E2E Testing Strategy

### Why Not Maestro or Playwright

* **Maestro** only drives mobile devices/simulators and web browsers. It cannot automate native macOS desktop windows.
* **Playwright** automates web browsers.
* **Appium (`mac2-driver`)** sees Flutter desktop windows as opaque black boxes unless complex native accessibility bridges are maintained.

### The Solution: Flutter `package:integration_test`

E2E testing on macOS is handled by Flutter's built-in `integration_test` framework:

```bash
flutter test integration_test/macos_flow_test.dart -d macos
```

1. Compiles the real macOS `.app` bundle.
2. Spawns the native desktop window.
3. Interacts with the player UI using the exact `Semantics(identifier: ...)` IDs used by Maestro on mobile.
4. Executes real AVPlayer playback, buffering, seeks, volume changes, and DRM decryption.
5. Runs headlessly on GitHub Actions `macos-14` / `macos-latest` runners.

### Test Suite Parity (1:1 with Mobile and Web)

macOS replicates the 5 standard Better Player test suites:

| Suite | File | What it verifies |
|---|---|---|
| **Core Flow** | `macos_flow_test.dart` | Play, pause, skip ±15s, mute, speed, resolution, subtitles, seek bar, Cupertino/Material theme swap. |
| **HLS Stream** | `macos_hls_test.dart` | Adaptive bitrate, variant switching, live streams. |
| **Data Source Swap** | `macos_datasource_swap_test.dart` | Dynamic URL changes, key handling, aspect ratio reactivity. |
| **Error Recovery** | `macos_error_recovery_test.dart` | Invalid streams, error callbacks, retry behavior. |
| **Native FFI** | `macos_ffi_test.dart` | Direct FFI method calls (`play`, `pause`, `seekTo`, `setVolume`, `setSpeed`, `setTrack`). |

### Native OS Interactions (Outside Flutter Canvas)

If a test scenario requires interacting with the macOS operating system itself (native application menu bar, Dock, window resizing, or hardware media keys), execute AppleScript from the test runner:

```dart
// Example: Trigger macOS system media key via AppleScript
await Process.run('osascript', [
  '-e',
  'tell application "System Events" to key code 16',
]);
```

---

## CI & FFI Generation

* **FFI Generation:** macOS has its own generation script `packages/better_player_macos/tool/swiftgen.dart` configured with `--sdk macosx` and target `arm64-apple-macos`.
* **CI Workflow:** `.github/workflows/e2e_macos.yml` runs on `macos-14` or `macos-latest`, building the example app and executing all `integration_test` suites.
