# Migrating from Better Player 0.0.84 to 1.x.x

Better Player 1.x removed redundant `BetterPlayer` prefixes from configuration and data model classes and encapsulated the internal video engine.

## 1. Automated Migration

Run Dart Fix in the project root to apply the bundled `fix_data.yaml` renames automatically:

```bash
dart fix --apply
```

## 2. Class & Enum Rename Reference

| Legacy (0.0.84) | Current (1.x.x) |
| :--- | :--- |
| `BetterPlayerConfiguration` | `PlayerConfiguration` |
| `BetterPlayerDataSource` | `PlayerDataSource` |
| `BetterPlayerDataSourceType` | `DataSourceType` |
| `BetterPlayerVideoFormat` | `VideoFormat` |
| `BetterPlayerControlsConfiguration` | `PlayerControlsConfiguration` |
| `BetterPlayerTheme` | `PlayerTheme` |
| `BetterPlayerOverflowMenuItem` | `PlayerOverflowMenuItem` |
| `BetterPlayerProgressColors` | `PlayerProgressColors` |
| `BetterPlayerSubtitlesSource` | `PlayerSubtitlesSource` |
| `BetterPlayerSubtitlesSourceType` | `PlayerSubtitlesSourceType` |
| `BetterPlayerSubtitlesConfiguration` | `PlayerSubtitlesConfiguration` |
| `BetterPlayerPlaylistConfiguration` | `PlayerPlaylistConfiguration` |
| `BetterPlayerCacheConfiguration` | `CacheConfiguration` |
| `BetterPlayerBufferingConfiguration` | `BufferingConfiguration` |
| `BetterPlayerNotificationConfiguration` | `NotificationConfiguration` |
| `BetterPlayerDrmConfiguration` | `DrmConfiguration` |
| `BetterPlayerDrmType` | `DrmType` |
| `BetterPlayerEvent` | `PlayerEvent` |
| `BetterPlayerEventType` | `PlayerEventType` |
| `BetterPlayerTranslations` | `PlayerTranslations` |
| `BetterPlayerAsmsTrack` | `PlayerAsmsTrack` |
| `BetterPlayerAsmsAudioTrack` | `PlayerAsmsAudioTrack` |
| `BetterPlayerAsmsSubtitle` | `PlayerAsmsSubtitle` |

> **Unchanged classes**: `BetterPlayer`, `BetterPlayerController`, `BetterPlayerControllerProvider`, `BetterPlayerPlaylist`, `BetterPlayerPlaylistController`, `BetterPlayerListVideoPlayer`, `BetterPlayerListVideoPlayerController`, `BetterPlayerClearKeyUtils`, `BetterPlayerControlsState`, and `BetterPlayerMultipleGestureDetector` keep the `BetterPlayer` prefix.

## 3. Removed `videoPlayerController` Getter

Direct access to `controller.videoPlayerController` was removed in 1.4.0. Use methods and getters directly on `BetterPlayerController`:

| Legacy (0.0.84) | Current (1.x.x) |
| :--- | :--- |
| `controller.videoPlayerController!.play()` | `await controller.play()` |
| `controller.videoPlayerController!.pause()` | `await controller.pause()` |
| `controller.videoPlayerController!.seekTo(pos)` | `await controller.seekTo(pos)` |
| `controller.videoPlayerController!.value` | `controller.videoPlayerValue` |
| `controller.videoPlayerController!.addListener(fn)` | `controller.addVideoListener(fn)` |
| `controller.videoPlayerController!.removeListener(fn)` | `controller.removeVideoListener(fn)` |
| `controller.isPictureInPictureEnabled()` | `await controller.isPictureInPictureSupported()` |
