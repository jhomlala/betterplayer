# Caching, Playlists & Lists Reference

## 1. Video Caching (`CacheConfiguration`)

Enable disk caching on network data sources via `CacheConfiguration`:

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mp4',
  cacheConfiguration: const CacheConfiguration(
    useCache: true,
    preCacheSize: 10 * 1024 * 1024, // 10 MB
    maxCacheSize: 100 * 1024 * 1024, // 100 MB
    maxCacheFileSize: 50 * 1024 * 1024, // 50 MB
    key: 'video_unique_cache_key', // Required on Android to persist across app restarts
  ),
);
```

### Pre-caching & cache management

* **Pre-cache before playback** (supported for non-HLS network streams on Android, iOS, and macOS, plus HLS on Android playback cache; note that `preCache()` is a no-op for HLS streams because HLS manifests reference dynamic segments):
  ```dart
  await _controller.preCache(dataSource);
  ```
* **Stop active pre-cache**:
  ```dart
  await _controller.stopPreCache(dataSource);
  ```
* **Clear all cached files**:
  ```dart
  await _controller.clearCache();
  ```

## 2. Sequential Playlists (`BetterPlayerPlaylist`)

Use `BetterPlayerPlaylist` to play a sequence of `PlayerDataSource` items with automatic transitions:

```dart
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final GlobalKey<BetterPlayerPlaylistState> _playlistKey = GlobalKey();

  late final List<PlayerDataSource> _dataSources = [
    PlayerDataSource(DataSourceType.network, 'https://example.com/video1.mp4'),
    PlayerDataSource(DataSourceType.network, 'https://example.com/video2.mp4'),
  ];

  BetterPlayerPlaylistController? get _playlistController =>
      _playlistKey.currentState?.betterPlayerPlaylistController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayerPlaylist(
            key: _playlistKey,
            betterPlayerConfiguration: const PlayerConfiguration(
              aspectRatio: 16 / 9,
              autoPlay: true,
            ),
            betterPlayerPlaylistConfiguration: const PlayerPlaylistConfiguration(
              loopVideos: true,
              nextVideoDelay: Duration(seconds: 3),
            ),
            betterPlayerDataSourceList: _dataSources,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () => _playlistController?.playPreviousVideo(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () => _playlistController?.playNextVideo(),
            ),
          ],
        ),
      ],
    );
  }
}
```

## 3. Video Playback in Scrollable Lists (`BetterPlayerListVideoPlayer`)

For short lists where videos auto-play based on viewport visibility, use `BetterPlayerListVideoPlayer`:

```dart
AspectRatio(
  aspectRatio: 16 / 9,
  child: BetterPlayerListVideoPlayer(
    PlayerDataSource(DataSourceType.network, videoUrl),
    key: ValueKey(videoUrl),
    playFraction: 0.8, // Plays when at least 80% of the widget is visible
    autoPlay: true,
  ),
)
```

> **Performance rule for long feeds**: Do not instantiate dozens of `BetterPlayerController` instances simultaneously in a long `ListView.builder`; native media decoders will exhaust device memory (OOM). Maintain a small pool of 2 to 3 reusable `BetterPlayerController` instances with `autoDispose: false` and attach them to visible items as the user scrolls.
