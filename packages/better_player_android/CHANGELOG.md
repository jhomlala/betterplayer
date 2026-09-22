## Unreleased
- Fixed: Resolved Android cache clearing failure and OutOfMemory bugs by properly delegating `clearCache()` to ExoPlayer's `SimpleCache.removeResource()`.
- Fixed: Blocked HLS pre-caching attempts. Pre-caching HLS streams natively caches only the playlist file (causing 0% progress bugs on Android).
- Fixed: Added try-catch block to `enterPictureInPictureMode` to prevent crashes when the activity is not in a valid state for PiP.

## 1.5.0
- Added: Configurable Android Auto Frame Rate (AFR) matching via ExoPlayer's `setVideoChangeFrameRateStrategy`.
- Fixed: Resolved issue where video events were broadcast to all active players instead of the specific player instance by correctly capturing the texture ID.

## 1.4.0
- Added: Supported RTSP streaming on Android via `androidx.media3:media3-exoplayer-rtsp`.

## 1.3.1
- Updated: package metadata

## 1.3.0
- [BREAKING_CHANGE] Updated: Upgraded `androidx.media3` version from `1.1.1` to `1.11.0`.
- [BREAKING_CHANGE] Updated: Raised `minSdkVersion` to `24`.
- [BREAKING_CHANGE] Updated: Upgraded `androidx.media:media` to `1.7.0`.
- Fixed: Resolved MediaSession token resolution error (`sessionCompatToken`) introduced in the Media3 upgrade.
- Added: Supported configurable `drmSecurityLevel` to enable Widevine L1 playback.

## 1.2.0
- Added: Support for native-to-Dart log streaming (`setupLogCallback`) via JNI for ExoPlayer.
- Added: Reintroduced `example` directory with documentation to the package.
- Updated: Enhanced package description in `pubspec.yaml` for better discoverability.

## 1.1.0
- Added: Migrated native bridge to JNI using `jnigen` for high-performance direct communication with the Android media engine.
- Fixed: Memory leak in player disposal and optimized WorkManager threading for caching.

## 1.0.2

* Docs: Updated model name references in example.md.

## 1.0.1
* Add thin examples to platform packages and decoupled example app.


## 1.0.0
* Updated: Extracted Android native code from the core package into a standalone federated plugin package (`better_player_android`).
* Fixed: Added missing `result.success(null)` for `setMixWithOthers` method channel call.




