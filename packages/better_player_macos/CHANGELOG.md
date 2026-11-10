## Unreleased
- Fixed: Video stutters when it resumes from Picture in Picture, and a video paused from the PiP controls can resume on its own. The stall check and `updatePlayingState` no longer force `playImmediately(atRate:)` while AVKit plays or buffers in PiP, and `isPlaying` now follows the PiP play and pause controls (by @Marionetista).
- Added: `FlutterFramework` dependency to `Package.swift` for Swift Package Manager support (by @hellohuanlin).
- Updated: Bumped `better_player_platform_interface` constraint to `^1.8.0` to resolve constructor compatibility during dependency lower-bound analysis.

## 1.8.0
- Added: `getAudioTracks` implementation to query audible options on AVPlayer's current media asset.
- Updated: Increased playback speed ceiling from `4.0` to `10.0` in `setSpeed`.

## 1.7.0
- [BREAKING_CHANGE] Fixed: Resolved FairPlay key loading thread deadlocks by removing blocking `DispatchSemaphore`, made `assetId` strictly local per request to prevent race conditions, added thread-safe certificate caching with in-flight request deduplication, and scoped EZDRM URL path rewriting to EZDRM domains only. Non-EZDRM license servers now receive standard direct POST requests.
- Fixed: CacheManager shared state race condition during concurrent pre-caching and dynamic maxCacheSize updates.

## 1.6.1
- Updated: Modernized `analysis_options.yaml` to inherit root options and resolved static analysis lints.

## 1.6.0
- Added: Native AirPlay route picker (`AVRoutePickerView`) and `externalPlaybackActive` KVO state stream.
- Updated: Bumped `better_player_platform_interface` dependency to `^1.7.0`.

## 1.5.1
- Fixed: Dispatched KVO observer updates and asynchronous video track loading to the main thread, guarded invalid asset durations in `getVideoComposition`, and kept observers attached after playback completion.
- Fixed: Reset window screen capture protection (`sharingType = .readWrite`) on plugin registration across hot restarts.

## 1.5.0
- Added: Screen capture and window recording protection via `NSWindow.sharingState`.
- Updated: Dependency `better_player_platform_interface` to `^1.6.0`.

## 1.4.1
- Fixed: Forwarded HTTP headers from `DataSource` to native wrapper in `setDataSource` to support authenticated network streams.

## 1.4.0
- Added: Native pre-cache progress reporting in `CacheManager` via `BetterPlayerPreCacheCallback`.
- Fixed: App crash on hot restart by using asynchronous listener callbacks (`implementAsListener`), resetting the native log callback, safely extracting orphaned player IDs, and clearing callbacks before resource teardown (#1617).

## 1.3.0
- Fixed: Added fallback matching by displayName, language, and index in `setAudioTrack` to support HLS audio tracks lacking common title metadata.

## 1.2.0
- Added: `setTextTrack` method on `BetterPlayer` to select or disable legible media selection group tracks in `AVPlayerItem` (#1066).
- Added: `AVPlayerItemLegibleOutput` push delegate and `onCues` callback on `BetterPlayerCallback` emitting parsed subtitle cues.
- Fixed: Forwarded dynamic presentation size changes to Flutter to resolve black screen on HLS playback with delayed track resolution (#1595).
- Fixed: Prevented native KVO crash on disposal and hot restart by unregistering observers, clearing callbacks, and resetting player item (#1600).

## 1.1.1
- Added: Better Player logo screenshot and branding metadata for pub.dev package listing.

## 1.1.0
- Updated: Defaulted controls to desktop theme and synchronized with core player 1.22.0.

## 1.0.0
- Added: Initial release of `better_player_macos` with native AVPlayer playback, `AppKitView` rendering, FFI bindings, and FairPlay DRM support.

