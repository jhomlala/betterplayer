## Unreleased
- Updated: Bumped `better_player_platform_interface` constraint to `^1.8.0` for consistency across platform packages.

## 1.5.0
- Added: `getAudioTracks` implementation to query container and stream audio tracks from mpv `track-list`.
- Updated: Increased playback speed ceiling from `4.0` to `10.0` in `setSpeed`.

## 1.4.2
- Updated: Modernized `analysis_options.yaml` to inherit root options and resolved static analysis lints.

## 1.4.1
- Fixed: Restricted `MpvEventId.endFile` completion events to `MpvEndFileReason.eof`, restarted playback from `0.0` when `play()` is called after EOF, and preserved position on `time-pos` property query errors.
- Fixed: Queried native video display dimensions (`dwidth`/`dheight`) in `CopyPixelBuffer` to avoid black frames prior to first decode and unnecessary CPU scaling.
- Fixed: Eliminated deadlocks during `dispose`, `clear`, and plugin destruction by releasing mutex prior to tearing down player instances.
- Fixed: Guarded zero or negative video frame dimensions in `CopyPixelBuffer` to prevent allocating temporary frame buffers before first frame presentation.
- Fixed: Awaited pending native player cleanup during startup in `create()` to prevent race conditions with newly initialized players.
- Fixed: Removed Linux shared library lookup candidates from Windows `mpv_ffi` bindings.

## 1.4.0
- Added: Window screen capture protection via Win32 `SetWindowDisplayAffinity` (`WDA_EXCLUDEFROMCAPTURE`).
- Updated: Dependency `better_player_platform_interface` to `^1.6.0`.

## 1.3.0
- Fixed: Resolved deadlocks during `TextureBridge::Dispose()` by unregistering textures outside mutex lock.
- Fixed: Enabled hardware video decoding (`hwdec=auto-safe`) in mpv initialization.
- Fixed: Resolved orphan player leaks across hot restarts by clearing native players on plugin startup.
- Fixed: Added ClearKey DRM playback support via mpv `decryption_key`.
- Fixed: Quoted HTTP headers containing commas to prevent incorrect mpv header field splitting.
- Fixed: Supported `bufferingConfiguration` by configuring `demuxer-readahead-secs` and `demuxer-cache-wait`.
- Fixed: Respected `overriddenDuration` when loading data sources and on property updates.
- Fixed: Resolved video, audio, and subtitle track selection by matching IDs in `track-list`.
- Fixed: Resolved local asset path resolution for packaged Flutter desktop executables.

## 1.2.1
- Fixed: Aligned `BetterPlayerWindows.preCache` method signature with `BetterPlayerPlatform` in `better_player_platform_interface` 1.5.0.
- Updated: Bumped `better_player_platform_interface` dependency to `^1.5.0`.

## 1.2.0
- Fixed: Added disposal state guards across player methods and mpv FFI invocations to prevent invalid pointer access after disposal.
- Fixed: Corrected audio track indexing to map 0-based index to 1-based `aid` property and disable audio with `'no'`.
- Fixed: Added `hls-bitrate` property configuration in `setTrackParameters`.
- Fixed: Added `seek` and `bufferingUpdate` (from `demuxer-cache-time`) event emissions and use display dimensions `dwidth`/`dheight` for video sizing.
- Fixed: Cleared mpv render update callback prior to freeing render context in `TextureBridge` to avoid native callback race conditions during shutdown.

## 1.1.0
- Added: `setTextTrack` method on `MpvPlayer` to select or disable subtitle and closed caption tracks via mpv `sid` property (#1066).
- Added: `sub-text` property observer emitting `captionUpdate` events with active subtitle lines.

## 1.0.1
- Added: Better Player logo screenshot and branding metadata for pub.dev package listing.

## 1.0.0
- Added: Initial release of `better_player_windows` with native `libmpv` playback, pixel buffer texture rendering, FFI bindings, native logging, and HLS/DASH support.
