## 1.3.0
- Fixed: Forward video and Shaka error events as `PlatformException` to the event stream to prevent infinite loading state on 404 and network errors.
- Fixed: Unregister old HTTP request filters when switching data source and upon player disposal to prevent header leaks across sessions.
- Fixed: Handle local asset paths with `assets/` prefix fallback and wrap manifest loading in try-catch to report load failures cleanly.

## 1.2.0
- Added: `setTextTrack` method on `BetterPlayerWebPlayer` using Shaka Player `selectTextLanguage` and `setTextTrackVisibility` for embedded text tracks (#1066).
- Added: Active `TextTrack` cue change listener emitting `captionUpdate` events with active cues.
- Fixed: Suppressed duplicate browser native cue rendering via global CSS shadow DOM and cue hiding rules without interrupting active cue event delivery.

## 1.1.4
- Added: Better Player logo screenshot and branding metadata for pub.dev package listing.
- Fixed: Migrated from deprecated `shaka.Player(mediaElement)` constructor to `shaka.Player.attach(mediaElement)`.
- Fixed: Configured resilient retry parameters (`maxAttempts`, `timeout`, `stallTimeout`) for streaming segments and manifests to prevent network timeout errors (`1003`).
- Fixed: Guarded `play()` and `pause()` against redundant invocations when `videoElement` is already in the requested state.
- Refactored: Made `BetterPlayerWebPlayer.initialize()` asynchronous to guarantee attachment before playback operations.

## 1.1.3
- Updated: `better_player_platform_interface` version bump.

## 1.1.2
- Updated: etter_player_platform_interface version bump.

## 1.1.1
- Updated: package metadata

## 1.1.0
- Added: Support for `drmSecurityLevel` mapping to Shaka Player's `videoRobustness`.

## 1.0.1

* Added example application for web platform.

## 1.0.0

* Initial release of better_player_web package.




