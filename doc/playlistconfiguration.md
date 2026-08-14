## Playlist configuration

Customize `BetterPlayerPlaylist` widget behavior with `BetterPlayerPlaylistConfiguration`. Instance of `BetterPlayerPlaylistConfiguration` should be passed to `BetterPlayerPlaylist`.


```dart
var betterPlayerPlaylistConfiguration = BetterPlayerPlaylistConfiguration(
    loopVideos: false,
    nextVideoDelay: Duration(milliseconds: 5000),
);
```

Possible configuration options:
```dart
///How long user should wait for next video
final Duration nextVideoDelay;

///Should videos be looped
final bool loopVideos;

///Index of video that will start on playlist start. Id must be less than
///elements in data source list. Default is 0.
final int initialStartIndex;
```