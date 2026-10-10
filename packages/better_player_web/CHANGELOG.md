## 1.1.4
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




