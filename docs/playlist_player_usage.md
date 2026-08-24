---
id: playlist_player_usage
title: Playlist Player Usage
---

# Playlist Support

Better Player includes a specialized `BetterPlayerPlaylist` widget designed to play a sequence of videos one after another.

## Key Features
*   **Automatic Transition**: Seamlessly switches to the next video when the current one finishes.
*   **Skippable Intervals**: A customizable delay between videos, displayed in the player UI and skippable by the user.

## Implementation Workflow

### 1. Create a Data Set
Prepare a list of `BetterPlayerDataSource` objects:

```dart
List<BetterPlayerDataSource> createDataSet() {
  return [
    BetterPlayerDataSource(BetterPlayerDataSourceType.network, "url1"),
    BetterPlayerDataSource(BetterPlayerDataSourceType.network, "url2"),
    BetterPlayerDataSource(BetterPlayerDataSourceType.network, "url3"),
  ];
}
```

### 2. Integrate the Playlist Widget
Pass the data set and configuration objects to the `BetterPlayerPlaylist` widget:

```dart
@override
Widget build(BuildContext context) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: BetterPlayerPlaylist(
        betterPlayerConfiguration: BetterPlayerConfiguration(),
        betterPlayerPlaylistConfiguration: const BetterPlayerPlaylistConfiguration(),
        betterPlayerDataSourceList: dataSourceList),
  );
}
```
