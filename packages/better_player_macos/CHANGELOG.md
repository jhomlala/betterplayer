## Unreleased
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
