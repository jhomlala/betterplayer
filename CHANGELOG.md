## Unreleased
* Added: Maestro E2E testing suite and CI integration for iOS (covering MP4, HLS flows, and player controls).
* Added: Semantic identifiers across player controls and UI components for robust E2E testing.
* Fixed: Race condition when launching sub-menus (quality, speed, etc.) from the overflow menu on iOS.
* Fixed: Missing semantic identifiers for resolution selection items in normal MP4 videos and robust HLS auto quality detection.
* Refactored: Replaced widget helper methods in controls with dedicated stateless widgets (`BetterPlayerVideoAreaSemantics`) to adhere to architecture standards.
* Updated: Documentation (`docs/drmconfiguration.md`) to explicitly note that DRM playback requires a physical device.

## 0.8.0
* Added: Maestro E2E flows for iOS and integrated them into GitHub Actions.
* Updated: [BREAKING_CHANGE] Migrated iOS implementation to Swift.
* Updated: [BREAKING_CHANGE] Finalized Swift Package Manager (SPM) migration for iOS.

## 0.7.1
* Fixed: HLS ABR video sizing issues (small video in corner) on Android TV and other platforms by making UI components reactive to resolution changes reported by the native layer.
* Fixed: Broken image links in the documentation by updating the paths to `assets/media/`.
* Fixed: Audio tracks returning null immediately after data source setup by awaiting ASMS parsing and improving track state management.
* Fixed: Embedded HLS/ASMS subtitles not being rendered due to incorrect segment timing and JIT loading logic.

## 0.7.0
* Fixed: Improved error handling for DASH streams on iOS by providing a descriptive Dart-side exception instead of a generic native error (AVPlayer does not support DASH).
* Updated: Documentation to clarify that DASH and Smooth Streaming are currently Android-only features.
* Added: `changedSize` event for both Android and iOS to update player dimensions during playback, fixing the issue where video container does not resize when resolution changes dynamically.
* Fixed: DASH live streams with sliding windows jumping or looping back on Android. Improved native DASH live configuration and correctly marked example streams as live.

## 0.6.1
* Added: Example demonstrating auto-fullscreen on rotation using `OrientationBuilder`.
* Updated: Reorganized media files into `assets/media/` and added `assets/pub/` for pub.dev screenshots and logo.
* Fixed: Android duration sometimes reporting zero for VOD streams by handling ExoPlayer's `C.TIME_UNSET` value and delaying the `initialized` event until a valid duration is available via `onTimelineChanged`.
