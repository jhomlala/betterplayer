---
id: migration_to_1.x.x
title: Migrating to v1.x.x
---

# Migrating to Better Player 1.x.x

Better Player 1.x.x introduces a **federated plugin architecture** and a significantly cleaner public API. 
The package was split into smaller specialized packages, and redundant BetterPlayer prefixes were removed from model names.

## 1. Automated Migration (Recommended)

The easiest way to migrate your codebase is to use the automated Dart fix tool. We have provided a ix_data.yaml that will handle all the class renames for you.

Just run this in your terminal:
``bash
dart fix --apply
``

## 2. API Name Changes

To make the API cleaner and more idiomatic, almost all configuration and data models have dropped the BetterPlayer prefix.

### Side-by-Side Code Comparison

Here is how a typical player setup looks before and after the 1.x.x migration:

<table>
<tr>
<th width="50%">Before (0.8.x)</th>
<th width="50%">After (1.x.x)</th>
</tr>
<tr>
<td>

``dart
BetterPlayerController(
  BetterPlayerConfiguration(
    autoPlay: true,
  ),
  betterPlayerDataSource: BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "https://example.com/video.mp4",
    cacheConfiguration: BetterPlayerCacheConfiguration(
      useCache: true,
    ),
  ),
)
``

</td>
<td>

``dart
BetterPlayerController(
  PlayerConfiguration( // [!code focus]
    autoPlay: true,
  ),
  betterPlayerDataSource: PlayerDataSource( // [!code focus]
    DataSourceType.network, // [!code focus]
    "https://example.com/video.mp4",
    cacheConfiguration: CacheConfiguration( // [!code focus]
      useCache: true,
    ),
  ),
)
``

</td>
</tr>
</table>

### Full List of Renamed Classes

| Old Name (0.8.x) | New Name (1.x.x) |
| :--- | :--- |
| BetterPlayerConfiguration | PlayerConfiguration |
| BetterPlayerControlsConfiguration | PlayerControlsConfiguration |
| BetterPlayerDataSource | PlayerDataSource |
| BetterPlayerDataSourceType / PlayerDataSourceType | DataSourceType |
| BetterPlayerVideoFormat | VideoFormat |
| BetterPlayerCacheConfiguration | CacheConfiguration |
| BetterPlayerNotificationConfiguration | NotificationConfiguration |
| BetterPlayerDrmConfiguration | DrmConfiguration |
| BetterPlayerBufferingConfiguration | BufferingConfiguration |
| BetterPlayerPlaylistConfiguration | PlayerPlaylistConfiguration |
| BetterPlayerSubtitle | PlayerSubtitle |
| BetterPlayerSubtitlesConfiguration | PlayerSubtitlesConfiguration |
| BetterPlayerSubtitlesSource | PlayerSubtitlesSource |
| BetterPlayerAsmsTrack | PlayerAsmsTrack |
| BetterPlayerAsmsAudioTrack | PlayerAsmsAudioTrack |
| BetterPlayerAsmsSubtitle | PlayerAsmsSubtitle |
| BetterPlayerProgressColors | PlayerProgressColors |
| BetterPlayerOverflowMenuItem | PlayerOverflowMenuItem |
| BetterPlayerEvent | PlayerEvent |
| BetterPlayerEventType | PlayerEventType |
| BetterPlayerTheme | PlayerTheme |
| BetterPlayerUtils | BetterPlayerUiUtils |

## 3. Parameter Renames

- isPictureInPictureEnabled in BetterPlayerController has been renamed to isPictureInPictureSupported to better reflect its function (it checks if the hardware/OS supports PiP, not if it's currently turned on).
