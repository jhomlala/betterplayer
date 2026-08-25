# Federated Plugin Refactoring Plan

This plan outlines the steps to refactor the `better_player` plugin into a federated structure, separating the platform-specific implementations into their own packages. This aligns with modern Flutter best practices (following the `video_player` model) and the project's "Plugin-First Principle."

We will use **Flutter Workspaces** (introduced in Flutter 3.24) to manage the monorepo. This provides native dependency resolution, a shared analysis context for the IDE, and simplifies maintenance commands.

## Goal
Split the current monolithic `better_player` plugin into a federated structure:
1. **`better_player`**: The app-facing package (core logic, HLS, DASH, UI, exports platform interface).
2. **`better_player_platform_interface`**: The common contract, data models, and base `MethodChannel` implementation.
3. **`better_player_android`**: The Android-specific native implementation and Dart binding.
4. **`better_player_ios`**: The iOS-specific native implementation and Dart binding.

---

## User Review Required

> [!IMPORTANT]
> **Default Package Declarations**: The app-facing package (`packages/better_player/pubspec.yaml`) will explicitly declare `default_package: better_player_android` and `default_package: better_player_ios`. This ensures Flutter automatically registers the platform implementations when users include `better_player` in their apps.

> [!IMPORTANT]
> **Flutter Workspaces**: We will implement a root `pubspec.yaml` that defines the workspace (`packages/*`). Note that `flutter test` at the root does not automatically run tests in all sub-packages; we will add a workspace test script for CI and local verification.

> [!TIP]
> **Type Exports & Backward Compatibility**: To prevent breaking changes and import leaks, `better_player` will `export` all platform interface types from `better_player_platform_interface`. Users will continue importing `package:better_player/better_player.dart`.

> [!TIP]
> **Shared MethodChannel Logic**: `MethodChannelVideoPlayer` will live in `better_player_platform_interface` as the shared base implementation. Android and iOS platform packages will extend this base, avoiding duplication of MethodChannel/EventChannel handling.

> [!WARNING]
> **iOS Podspec & Paths**: The native `ios/` directory moves to `packages/better_player_ios/ios/`. The `.podspec` file must be updated with accurate relative paths, and old root `.podspec` files deleted to prevent linker errors.

> [!NOTE]
> **Independent Package Artifacts**: Each of the 4 packages will contain its own `pubspec.yaml`, `LICENSE`, `README.md`, and `CHANGELOG.md` set to version **`1.0.0`** to support independent publishing on pub.dev.

---

## Proposed Changes

### 1. [NEW] Root Workspace Configuration
Create a root `pubspec.yaml` to manage all sub-packages under a single workspace context.
- **File**: `pubspec.yaml` (Root)
- **Content**:
  ```yaml
  name: better_player_workspace
  workspace:
    - packages/better_player
    - packages/better_player_android
    - packages/better_player_ios
    - packages/better_player_platform_interface
  ```

---

### 2. [NEW] `better_player_platform_interface`
Defines the `VideoPlayerPlatform` contract using `package:plugin_platform_interface`, raw data models, and default `MethodChannelVideoPlayer`.
- **Path**: `packages/better_player_platform_interface`
- **Version**: `1.0.0`
- **Dependencies**: `flutter`, `plugin_platform_interface: ^2.1.8`, `meta: ^1.18.0`.
- **Logic**:
  - `VideoPlayerPlatform` extends `PlatformInterface` with token verification (`PlatformInterface.verify(instance, _token)`).
  - Move `MethodChannelVideoPlayer` into `platform_interface` as the default channel wrapper.
  - Move raw platform models (`DataSource`, `VideoEvent`, `DurationRange`, `BetterPlayerDataSource`, etc.) decoupled from UI elements.

---

### 3. [NEW] `better_player_android`
The Android-specific native code and Dart platform registration.
- **Path**: `packages/better_player_android`
- **Version**: `1.0.0`
- **`pubspec.yaml`**:
  ```yaml
  name: better_player_android
  version: 1.0.0
  flutter:
    plugin:
      implements: better_player
      platforms:
        android:
          package: pl.hasoft.better_player
          pluginClass: BetterPlayerPlugin
          dartPluginClass: BetterPlayerAndroid
  ```
- **Dart Code**: `BetterPlayerAndroid extends MethodChannelVideoPlayer` with:
  ```dart
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerAndroid();
  }
  ```
- **Native**: Move root `android/` directory (Kotlin/Java, `build.gradle`, `AndroidManifest.xml`) to `packages/better_player_android/android/`.

---

### 4. [NEW] `better_player_ios`
The iOS-specific native code and Dart platform registration.
- **Path**: `packages/better_player_ios`
- **Version**: `1.0.0`
- **`pubspec.yaml`**:
  ```yaml
  name: better_player_ios
  version: 1.0.0
  flutter:
    plugin:
      implements: better_player
      platforms:
        ios:
          pluginClass: BetterPlayerPlugin
          dartPluginClass: BetterPlayerIOS
  ```
- **Dart Code**: `BetterPlayerIOS extends MethodChannelVideoPlayer` with:
  ```dart
  static void registerWith() {
    VideoPlayerPlatform.instance = BetterPlayerIOS();
  }
  ```
- **Native**: Move root `ios/` directory (`better_player.podspec`, Swift/ObjC source) to `packages/better_player_ios/ios/`. Update `.podspec` relative paths.

---

### 5. [MODIFY] `better_player` (App-facing Package)
The high-level package containing UI, HLS/DASH configuration, and controls.
- **Path**: `packages/better_player`
- **Version**: `1.0.0`
- **`pubspec.yaml`**:
  ```yaml
  name: better_player
  version: 1.0.0
  dependencies:
    better_player_platform_interface: ^1.0.0
    better_player_android: ^1.0.0
    better_player_ios: ^1.0.0
  flutter:
    plugin:
      platforms:
        android:
          default_package: better_player_android
        ios:
          default_package: better_player_ios
  ```
- **Exporting**: In `lib/better_player.dart`, export `package:better_player_platform_interface/better_player_platform_interface.dart`.
- **Cleanup**: Remove old root `android/` and `ios/` folders once moved.
- **Example App**: Move root `example/` to `packages/better_player/example`.

---

### 6. [MODIFY] CI/CD Workflows & Maestro
Update GitHub Actions workflows (`quality-gate.yml`, `maestro_android.yml`, `maestro_ios.yml`) and Maestro test scripts:
- Update build paths to point to `packages/better_player/example`.
- Add multi-package execution script for `flutter test` across all `packages/*`.

---

### 7. [MODIFY] `AGENTS.md`
Update developer workflow documentation for federated mono-repository structure:
- Maintenance commands for workspace root (`flutter analyze .`, workspace test runner).
- Layout explanations for `packages/` directory.

---

## Step-by-Step Execution Plan

1. **Phase 1: Workspace Initialization**
   - Create `packages/` layout (`better_player`, `better_player_platform_interface`, `better_player_android`, `better_player_ios`).
   - Create root workspace `pubspec.yaml` and sub-package `pubspec.yaml` files.
   - Add `LICENSE` and `README.md` to each package.

2. **Phase 2: Platform Interface Extraction**
   - Implement `VideoPlayerPlatform` using `package:plugin_platform_interface`.
   - Move `MethodChannelVideoPlayer` and platform models into `better_player_platform_interface`.
   - Write unit tests for platform interface.

3. **Phase 3: Android & iOS Platform Package Migration**
   - Move native Android code into `better_player_android/android/`.
   - Implement `BetterPlayerAndroid.registerWith()`.
   - Move native iOS code into `better_player_ios/ios/` and update `.podspec`.
   - Implement `BetterPlayerIOS.registerWith()`.

4. **Phase 4: App-Facing Package Refactoring**
   - Move core Dart logic to `packages/better_player`.
   - Add default package declarations in `better_player/pubspec.yaml`.
   - Add exports in `lib/better_player.dart`.
   - Move `example/` into `packages/better_player/example`.

5. **Phase 5: CI/CD, Maestro & Workflow Updates**
   - Update workflow files (`.github/workflows/*.yml`) for new paths.
   - Update Maestro test runner scripts.
   - Update `AGENTS.md`.

6. **Phase 6: Verification & Validation**
   - Run `flutter pub get` at root workspace level.
   - Run `flutter analyze .` at workspace root.
   - Run multi-package test suite.
   - Launch `packages/better_player/example` on Android and iOS simulators to verify playback.

---

## Verification Plan

### Automated Tests
- Multi-package test runner script: `flutter test` in each `packages/*` directory.
- `flutter analyze .` executed at the workspace root context.

### Manual Verification
- **Example App Execution**: Run `packages/better_player/example` on Android and iOS simulators. Verify video playback, controls, PIP, and quality switching.
- **Backward Compatibility**: Verify an external app importing `package:better_player/better_player.dart` compiles and runs without missing symbol errors.
