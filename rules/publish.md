---
name: Publish BetterPlayer Packages
description: Workflow and instructions for publishing better_player packages and creating a GitHub tag release.
---

# Publish BetterPlayer Packages

When instructed to publish the `betterplayer` packages, you must follow this workflow carefully to ensure dependencies are published in the correct order and the release is properly documented.

## Prerequisites
- Ensure `GITHUB_TOKEN` is set in your environment (required for creating the GitHub release):
  ```powershell
  $env:GITHUB_TOKEN="your_token_here"
  ```
- All packages must be versioned and their `CHANGELOG.md` files must be up-to-date before publishing.

## 1. Publish Order

Packages must be published from least dependent to most complicated. Run `flutter pub publish --force` inside each package directory in this **strict order**:

### Step 1 — Platform Interface
```powershell
cd packages/better_player_platform_interface
flutter pub publish --force
```
Wait for this to complete successfully before proceeding.

### Step 2 — Platform Implementations (can be done in sequence)
```powershell
cd packages/better_player_android
flutter pub publish --force

cd packages/better_player_ios
flutter pub publish --force

cd packages/better_player_web
flutter pub publish --force
```
These three packages only depend on the platform interface, not on each other.  
Wait for each to complete successfully before moving on.

### Step 3 — Main Package
```powershell
cd packages/better_player
flutter pub publish --force
```

If any package fails to publish, **stop immediately** and do not proceed to the next step.

## 2. Prepare Combined Changelog

After all packages have been published successfully:
- Read the most recent changelog entry from the `CHANGELOG.md` of each published package:
  - `packages/better_player_platform_interface/CHANGELOG.md`
  - `packages/better_player_android/CHANGELOG.md`
  - `packages/better_player_ios/CHANGELOG.md`
  - `packages/better_player_web/CHANGELOG.md`
  - `packages/better_player/CHANGELOG.md`
- Combine all entries into a single release changelog, grouped by package name.
- The release version is taken from `packages/better_player/pubspec.yaml`.

## 3. Create GitHub Tag and Release

- The tag name must exactly match the `better_player` package version **without a `v` prefix** (e.g., `1.8.0`).
- Create and push the tag:
  ```powershell
  git tag <VERSION>
  git push origin <VERSION>
  ```
- Create a GitHub Release on the tag using the combined changelog as the release body.
  - Repository: `jhomlala/betterplayer`
  - Release title: `<VERSION>`
  - Body: the combined changelog prepared in Step 2.
