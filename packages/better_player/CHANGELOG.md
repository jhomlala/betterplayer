## Unreleased
- Fixed: Dispatch `changedPlaylistItem` event on playlist video change.
- Fixed: Double/Triple screen glitch on `setResolution()` by sequencing `setupDataSource` controller events.
- Fixed: Race conditions in unit tests for data source setup.

## 1.10.0
- Added: WebVTT metadata block parsing support for `NOTE`, `STYLE`, and `REGION` headers.
- Added: Integrated custom inline tag parser for WebVTT cues, supporting HTML bold, italic, underline, and variable color classes.
- Added: Supported parsing of `X-TIMESTAMP-MAP` blocks with 33-bit MPEG-TS rollover timing adjustment corrections.
- Added: Supported WebVTT cue positioning attributes for individual text alignment customization (`align:left`, `align:right`, `align:center`).
- Fixed: Resolved layout and visibility calculation overlap for stroke-based text outlines using layered `RichText` stacks.

## 1.9.0
- Fixed: Resolved "No MaterialLocalizations found" and "No CupertinoLocalizations found" errors when opening the overflow menu by injecting localized types into the widget subtree.
- Added: Persian and Portuguese translations for player controls and menus.
- Updated: Added `overflowMenuCancelLabel`, `overflowMenuScrimLabel`, and `overflowMenuScrimHint` to `PlayerTranslations` for better localization of menu actions.
- Added: Comprehensive unit tests for localization bridge and translation factories.

## 1.8.1
- Updated: package metadata

## 1.8.0
- Added: Support for configurable DRM security level (Widevine L1/L3) via `PlayerDataSource`.
- Updated: Enhanced DRM documentation with details on `drmSecurityLevel` configuration for Android and Web.
- Added: Documentation for unit and widget testing with platform mocking.
- Updated: Clarified in documentation that `customControlsBuilder` requires `playerTheme` to be set to `PlayerTheme.custom`.
- Updated: Bumped dependencies for `better_player_android`, `better_player_ios`, `better_player_platform_interface`, and `better_player_web`.

## 1.7.0
- [BREAKING_CHANGE] Decoupled `PlayerEngineController` from `dart:io`. `setFileDataSource` now accepts a `String filePath` instead of a `File` object.
- Added: Web and WASM compatibility support.
- Fixed: Transitive `dart:io` imports that prevented web compilation.

## 1.6.0
- Added: Web platform support documentation, including a detailed feature matrix and setup instructions for `Shaka Player`.
