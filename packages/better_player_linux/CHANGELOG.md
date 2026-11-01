## Unreleased
- Fixed: Normalized local file URLs with `toFilePath()` to prevent invalid file paths on Linux.
- Fixed: Guarded zero or negative video frame dimensions in `CopyPixels` to prevent allocating temporary frame buffers before first frame presentation.
- Fixed: Awaited pending native player cleanup during startup in `create()` to prevent race conditions with newly initialized players.

## 1.0.0
- Added: Initial Linux implementation powered by libmpv and Flutter's FlPixelBufferTexture.
