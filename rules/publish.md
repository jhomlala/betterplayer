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

## 1. Check for Unreleased Sections

Before starting the publish process, verify that there are no `## Unreleased` sections in any `CHANGELOG.md` file. **If there is any `## Unreleased` section, then block the process and do not proceed!**

## 2. Publish Order

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

## 3. Create GitHub Tag and Release

After all packages have been published successfully, you must create a GitHub Release using the automated script.

This script will read the most recent changelog entries for any packages published within the last hour, combine them into a single release body, and automatically create and push the Git tag and GitHub Release.

```powershell
# Make sure your user token is set
$env:GITHUB_TOKEN = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "User")

# Run the release script
dart run scripts/create_github_release.dart
```
