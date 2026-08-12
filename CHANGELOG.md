
## 0.4.0
* [BREAKING_CHANGE] Added: Support for Built-in Kotlin.
* [BREAKING_CHANGE] Updated: Minimum Dart SDK version to 3.12.0.
* Fixed: Unreliable video and image URLs in the example app, especially on the Playlist page. Replaced them with stable ones from Google GTV bucket and Lorem Picsum.

## 0.3.0
* [BREAKING_CHANGE] Migrated to Flutter 3.47.0.
* [BREAKING_CHANGE] Migrated Material and Cupertino UI systems to standalone `material_ui` and `cupertino_ui` packages.
* Updated `compileSdkVersion` to 36 in Android.
* Updated Kotlin version to 2.3.20 in the example app.
* Updated Android Gradle Plugin version to 9.0.1 in the example app.

## 0.2.1
* Added: `.pubignore` to exclude `media/` and `AGENTS.md` from the published package.
* Updated: Documentation and README links to point to the new media location on GitHub.
* Updated: `README.md` to remove outdated migration information.
* Fixed: `prefer_if_elements_to_conditional_expressions` lint warnings in Material controls.

## 0.2.0
* [BREAKING_CHANGE] Updated: iOS to Swift Package Manager (SPM). Native source files moved from `ios/Classes` to `ios/better_player/Sources`.
* [BREAKING_CHANGE] Updated: Android `build.gradle` using the `plugins {}` block. Removed legacy `kotlin-android` apply plugin.
* Updated: `very_good_analysis` to 10.3.0 and addressed new linting rules.
* Updated: `xml` dependency to 7.0.0.
* Updated: `meta` dependency to 1.18.0.
