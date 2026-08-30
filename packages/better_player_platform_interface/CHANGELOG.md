## Unreleased
- Added: `setupLogger` method to `BetterPlayerPlatform` to support synchronized native logging.

## 1.1.0
- Added: Removed legacy `MethodChannelVideoPlayer` and replaced it with a modern JNI/Swiftgen implementation.
- Added: Renamed `VideoPlayerPlatform` to `BetterPlayerPlatform` for better project branding.
- Refactor: Rename `VideoPlayerPlatform` to `BetterPlayerPlatform` for consistency.
- Refactor: Remove legacy `MethodChannelVideoPlayer` implementation in favor of FFI/JNI.

## 1.0.2

* Docs: Updated model name references in example.md.

## 1.0.1
* Add thin examples to platform packages and decoupled example app.


## 1.0.0
* Added: Established as the central platform interface package for the federated plugin architecture.
* Updated: Consolidated core models (`DataSource`, `VideoEvent`, etc.) and `MethodChannelVideoPlayer` into this package.
* Updated: Renamed `isPictureInPictureEnabled` to `isPictureInPictureSupported` for API consistency.
* Added: `dataSourceToMap` serialization in `MethodChannelVideoPlayer` to allow platform-specific extensions.


