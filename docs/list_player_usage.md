---
id: list_player_usage
title: List and Feed Video Playback
---

# Video Playback in Lists and Feeds

Playing multiple videos in scrolling lists requires strict memory management. Native video codecs consume significant RAM and hardware decoders. Instantiating a new controller per list row exhausts hardware codecs, leading to dropped frames or Out-of-Memory crashes.

Better Player provides two patterns for feeds and scrolling lists:
- **`BetterPlayerFeed`**: Turnkey swipe feed (TikTok / Reels style) with built-in controller pooling, lookahead preloading, and first-frame gating.
- **`BetterPlayerPool`**: Bounded controller recycling engine for custom `ListView` or `GridView` feeds.

> [!NOTE]
> The legacy `BetterPlayerListVideoPlayer` is deprecated. See the [migration section](#legacy-lists-betterplayerlistvideoplayer-deprecated) below.

---

## High-Performance Feeds: `BetterPlayerFeed`

`BetterPlayerFeed` pairs a `PageView` with an internal `BetterPlayerPool`. It bounds active player instances to a fixed ceiling (defaults to 3), preloads upcoming items in the background, and evicts distant controllers as the user scrolls.

```dart
final feedController = BetterPlayerFeedController(
  dataSources: [
    PlayerDataSource.network('https://example.com/video1.mp4'),
    PlayerDataSource.network('https://example.com/video2.mp4'),
    PlayerDataSource.network('https://example.com/video3.mp4'),
  ],
  poolConfiguration: const PlayerPoolConfiguration(
    poolSize: 3,
    preloadForward: 1,
    preloadBackward: 1,
    preloadMode: PlayerPreloadMode.prepared,
  ),
);

@override
Widget build(BuildContext context) {
  return BetterPlayerFeed(
    controller: feedController,
    configuration: PlayerFeedConfiguration(
      placeholderBuilder: (context, index, dataSource) =>
          Center(child: CircularProgressIndicator()),
    ),
  );
}
```

### Preload Modes

Configure preloading behavior via `PlayerPoolConfiguration`:
- **`PlayerPreloadMode.prepared`** (default): Prepares the source and native texture, then pauses immediately on initialization. Consumes minimal battery while eliminating cold-start spinup lag.
- **`PlayerPreloadMode.muted`**: Plays preloaded media at zero volume to keep network buffers and hardware decoders warm.

### Infinite Feeds

To append new pages dynamically as the user nears the end:

```dart
feedController.appendDataSources(newSources);
```

---

## Standalone Controller Pooling: `BetterPlayerPool`

If you are building a custom `ListView` or grid rather than a `PageView`, use `BetterPlayerPool` directly. The pool evicts the slot furthest from the current active index whenever capacity is exceeded:

```dart
final pool = BetterPlayerPool(
  configuration: const PlayerPoolConfiguration(poolSize: 3),
);

// Acquire slot for item
final lease = await pool.acquire(
  itemId: 'video_42',
  index: 42,
  dataSource: dataSource,
);

// Use controller in widget
BetterPlayer(controller: lease.controller);

// Release lease when scrolled out of view
lease.release();
```

---

## Legacy Lists: `BetterPlayerListVideoPlayer` (Deprecated)

> [!WARNING]
> `BetterPlayerListVideoPlayer` and `BetterPlayerListVideoPlayerController` are deprecated. They do not pool or recycle controllers. Using them in scrollable `ListView` or `GridView` builders retains native controller textures via `AutomaticKeepAliveClientMixin`, exhausting hardware decoders and leading to Out-of-Memory crashes. Migrate to `BetterPlayerFeed` for swipe feeds or `BetterPlayerPool` for custom list recycling.

If you only have 2 static video cards in a short layout, use standard `BetterPlayer` with `playerVisibilityChangedBehavior`:

```dart
BetterPlayer(
  controller: BetterPlayerController(
    PlayerConfiguration(
      playerVisibilityChangedBehavior: (fraction) {
        if (fraction >= 0.8) {
          controller.play();
        } else {
          controller.pause();
        }
      },
    ),
    betterPlayerDataSource: dataSource,
  ),
);
```
