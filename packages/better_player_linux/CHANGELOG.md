## 1.0.2
- Updated: Modernized `analysis_options.yaml` to inherit root options and resolved static analysis lints.

## 1.0.1
- Fixed: Restricted `MpvEventId.endFile` completion events to `MpvEndFileReason.eof`, restarted playback from `0.0` when `play()` is called after EOF, and preserved position on `time-pos` property query errors.
- Fixed: Normalized local file URLs with `toFilePath()` to prevent invalid file paths on Linux.
- Fixed: Guarded zero or negative video frame dimensions in `CopyPixels` to prevent allocating temporary frame buffers before first frame presentation.
- Fixed: Awaited pending native player cleanup during startup in `create()` to prevent race conditions with newly initialized players.

## 1.0.0
- Added: Initial Linux implementation powered by libmpv and Flutter's FlPixelBufferTexture.
