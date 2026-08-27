---
id: playlist_configuration
title: Playlist Configuration
---

# Playlist Configuration

You can customize the behavior of the `BetterPlayerPlaylist` widget using the `PlayerPlaylistConfiguration` class.

## Implementation Example

```dart
var betterPlayerPlaylistConfiguration = PlayerPlaylistConfiguration(
    loopVideos: false,
    nextVideoDelay: Duration(milliseconds: 5000),
    initialStartIndex: 0,
);
```

## Configuration Parameters

*   **`nextVideoDelay`**: The duration the user must wait before the next video in the playlist starts automatically.
*   **`loopVideos`**: Determines if the playlist should restart from the beginning after the last video finishes.
*   **`initialStartIndex`**: The index of the video that should start playing when the playlist is initialized.
