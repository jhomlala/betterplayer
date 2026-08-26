---
id: migration_to_federated
title: Migrating to v1.0.0 (Federated Architecture)
---

# Migrating to Better Player 1.0.0

Better Player 1.0.0 introduces a **federated plugin architecture** similar to how the official ideo_player plugin is structured. This splits the single etter_player package into smaller, specialized packages:
- etter_player (App-facing interface)
- etter_player_platform_interface (Common abstractions and interfaces)
- etter_player_android (Android implementation)
- etter_player_ios (iOS implementation)

This architectural shift improves performance, enables easier platform-specific optimizations, and lays the groundwork for web and desktop support in the future!

For most users, **migration requires very few changes**, as the core API surfaces (BetterPlayer, BetterPlayerController, etc.) remain intact. However, because some underlying models were deduplicated and shifted to the etter_player_platform_interface, there are a few minor breaking changes to be aware of.

## 1. Update Dependencies

Update your pubspec.yaml to use version 1.0.0:

`yaml
dependencies:
  better_player: ^1.0.0
`

Because of the federated architecture, you **do not** need to explicitly include etter_player_android, etter_player_ios, or etter_player_platform_interface in your pubspec.yaml. The main etter_player package will transitively pull in everything you need!

## 2. API Name Changes

To avoid duplicating types between the core player and the new platform interface, some types that started with BetterPlayer... have been renamed to match their standardized platform-interface equivalents:

| Old Name | New Name |
| :--- | :--- |
| `BetterPlayerDataSourceType` | `DataSourceType` |
| `BetterPlayerVideoFormat` | `VideoFormat` |
| `BetterPlayerCacheConfiguration` | `CacheConfiguration` |
| `BetterPlayerNotificationConfiguration` | `NotificationConfiguration` |
| `BetterPlayerDrmConfiguration` | `DrmConfiguration` |
| `BetterPlayerBufferingConfiguration` | `BufferingConfiguration` |
| `BetterPlayerUtils` | `BetterPlayerUiUtils` |

### Example Fix:
**Before (0.8.x):**
`dart
BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "https://example.com/video.mp4",
)
`

**After (1.0.0):**
`dart
BetterPlayerDataSource(
    DataSourceType.network,
    "https://example.com/video.mp4",
)
`

## 3. Parameter Renames

- isPictureInPictureEnabled in BetterPlayerController has been renamed to isPictureInPictureSupported to better reflect its function (it checks if the hardware/OS supports PiP, not if it's currently turned on).

## Next Steps

Once you update your enums and run lutter pub get, your project should compile and run seamlessly.
