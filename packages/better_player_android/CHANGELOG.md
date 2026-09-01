## 1.2.0
- Added: Support for native-to-Dart log streaming (`setupLogCallback`) via JNI for ExoPlayer.
- Added: Reintroduced `example` directory with documentation to the package.
- Updated: Enhanced package description in `pubspec.yaml` for better discoverability.

## 1.1.0
- Added: Migrated native bridge to JNI using `jnigen` for high-performance direct communication with the Android media engine.
- Fixed: Memory leak in player disposal and optimized WorkManager threading for caching.

## 1.0.2

* Docs: Updated model name references in example.md.

## 1.0.1
* Add thin examples to platform packages and decoupled example app.


## 1.0.0
* Updated: Extracted Android native code from the core package into a standalone federated plugin package (`better_player_android`).
* Fixed: Added missing `result.success(null)` for `setMixWithOthers` method channel call.


