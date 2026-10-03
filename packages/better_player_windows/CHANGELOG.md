## Unreleased

- Fixed: Prevented duplicate `initialized` events by reserving `initialized` for initial file load and emitting `changedSize` for dynamic resolution changes.
- Fixed: Prevented duplicate `completed` events between `eof-reached` and `end-file`.
- Fixed: Cleared HTTP headers on data source change when the new source provides no custom headers.
- Fixed: Surfaced native `loadfile` and `seek` command errors as `PlatformException`.
- Fixed: Clamped playback speed to `0.01..4.0` to prevent invalid mpv property errors at 0 speed.
- Updated: Corrected `setTrackParameters` to avoid distorting video aspect ratio, and improved missing DLL error diagnostics.

## 1.0.0

- Added: Initial release of `better_player_windows` with native `libmpv` playback, pixel buffer texture rendering, FFI bindings, native logging, and HLS/DASH support.
