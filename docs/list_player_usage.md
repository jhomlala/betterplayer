---
id: list_player_usage
title: List and Feed Video Playback
---

# Video Playback in Lists and Feeds

Playing multiple videos in scrolling feeds requires strict memory and decoder management. Native video engines (ExoPlayer on Android, AVPlayer on iOS) consume hardware decoders and graphics memory. Allocating a new controller per list item quickly hits OS hardware decoder limits, triggering dropped frames, UI freezes, or Out-of-Memory crashes.

Better Player solves this with two bounded patterns:
- **`BetterPlayerFeed`**: Turnkey full-screen swipe feed (short-form vertical video style) with built-in controller pooling, lookahead preloading, audio overlap prevention, and first-frame gating.
- **`BetterPlayerPool`**: Standalone controller recycling engine for custom `ListView` or `GridView` feeds.

> [!NOTE]
> The legacy `BetterPlayerListVideoPlayer` is deprecated. See the [migration section](#legacy-lists-betterplayerlistvideoplayer-deprecated) below.

---

## High-Performance Feeds: `BetterPlayerFeed`

`BetterPlayerFeed` pairs a `PageView` with an internal `BetterPlayerPool`. It bounds the maximum number of active player controllers to a fixed ceiling (defaults to 3), preloads adjacent media in the background, gates playback behind first-frame rendering to prevent black flashes, and pauses previous controllers on swipe to avoid audio overlap.

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
      placeholderBuilder: (context, index, dataSource) => const Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}
```

### How It Works

1. **Active Item Leased**: When the user lands on an item, the controller acquires an exclusive lease from the pool for that index.
2. **Audio Overlap Prevention**: Swiping to an adjacent item immediately pauses the previous controller before starting playback on the new item.
3. **First-Frame Gating**: The feed displays your placeholder until the native texture emits `PlayerEventType.initialized`. This eliminates black flashes and UI stutter during cold setup.
4. **Distance Eviction**: When all pool slots are filled, the pool evicts the controller furthest from the current active index.
5. **Background Safe**: Automatically pauses playback when the host application goes to background.

---

## Configuration & Parameters

### `PlayerPoolConfiguration`

Controls the bounded recycling engine and lookahead preloader:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `poolSize` | `int` | `3` | Maximum number of `BetterPlayerController` instances kept in memory (minimum 2). |
| `preloadMode` | `PlayerPreloadMode` | `prepared` | Preload strategy for lookahead/lookbehind media items (`prepared` or `muted`). |
| `preloadForward` | `int` | `1` | Number of items ahead of the active index to keep preloaded in memory. |
| `preloadBackward` | `int` | `1` | Number of items behind the active index to keep preloaded in memory. |
| `playerConfiguration` | `PlayerConfiguration` | `PlayerConfiguration(...)` | Base player configuration applied to all pooled controllers. Note: `autoDispose` and `handleLifecycle` are forced to `false` by the pool to prevent premature teardown. |

#### Preload Modes

- **`PlayerPreloadMode.prepared`** (Recommended): Sets up the media source and native texture, then pauses immediately on initialization. Consumes minimal CPU and battery while eliminating cold-start spinup lag.
- **`PlayerPreloadMode.muted`**: Plays preloaded media at volume 0.0 to keep native network buffers and decoders hot. Best for rapid continuous swiping.

### `PlayerFeedConfiguration`

Customizes the `BetterPlayerFeed` widget UI and behavior:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `scrollDirection` | `Axis` | `Axis.vertical` | Axis along which the feed scrolls (`Axis.vertical` for vertical swipe feeds, `Axis.horizontal` for carousels). |
| `autoPlay` | `bool` | `true` | Whether the focused item automatically begins playback once initialized. |
| `placeholderBuilder` | `Widget Function(...)` | `null` | Builds the placeholder widget displayed behind the video and before the first frame renders. |
| `errorBuilder` | `Widget Function(...)` | `null` | Builds the fallback widget displayed if a video fails to load or play. |

### `BetterPlayerFeedController`

Coordinates data sources and leases for the feed widget:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `dataSources` | `List<PlayerDataSource>` | *(required)* | Initial list of video media sources to display in the feed. |
| `pool` | `BetterPlayerPool?` | `null` | Optional external pool instance. If omitted, the controller instantiates and owns its internal pool. |
| `poolConfiguration` | `PlayerPoolConfiguration?` | `null` | Configuration passed to the internal pool when `pool` is not provided. |
| `pageController` | `PageController?` | `null` | Optional custom `PageController` for page snapping and initial page index. |
| `idGetter` | `String Function(int index)?` | `'item_$index'` | Custom unique identifier generator for feed items. |
| `autoPlay` | `bool` | `true` | Whether active items should start playback automatically. |

#### Methods

- **`appendDataSources(List<PlayerDataSource> newSources)`**: Appends more media sources to the feed for infinite pagination.
- **`onIndexChanged(int index)`**: Triggers leasing, preloading, and distance-based recycling for a newly focused index.
- **`getLeaseNotifier(int index)`**: Returns a `ValueNotifier<PlayerPoolLease?>` for a specific index to observe lease bindings.
- **`dispose()`**: Releases all leases and disposes owned pool controllers and `PageController`.

---

## Standalone Controller Pooling: `BetterPlayerPool`

If you are building a custom `ListView`, `GridView`, or social card feed rather than a `PageView`, use `BetterPlayerPool` directly.

The pool evicts the slot furthest from the current active index whenever capacity is exceeded:

```dart
final pool = BetterPlayerPool(
  configuration: const PlayerPoolConfiguration(
    poolSize: 3,
    preloadForward: 1,
    preloadBackward: 1,
  ),
);

// 1. Inform the pool of current viewport focus to guide distance eviction
pool.setActiveIndex(42);

// 2. Acquire a lease for the visible row
final lease = await pool.acquire(
  itemId: 'video_row_42',
  index: 42,
  dataSource: PlayerDataSource.network('https://example.com/video42.mp4'),
);

// 3. Render using the leased controller
BetterPlayer(controller: lease.controller);

// 4. Release lease when scrolled out of viewport
lease.release();
```

### `BetterPlayerPool` API Reference

- **`acquire({required String itemId, required int index, required PlayerDataSource dataSource})`**: Acquires a leased controller. If all slots are occupied, evicts the slot furthest from `activeIndex`.
- **`release(PlayerPoolLease lease)`**: Returns a lease to the pool and makes the slot available.
- **`setActiveIndex(int index)`**: Sets the current focal index to guide distance-based eviction.
- **`updatePreloads({required int currentIndex, required List<PlayerDataSource> dataSources, required String Function(int index) idGetter})`**: Preloads lookahead and lookbehind items into idle slots.
- **`onAppBackground()`**: Pauses all active pooled playback safely when app enters background.
- **`onAppForeground()`**: Signals foreground return.
- **`dispose()`**: Evicts all leases and executes forced disposal (`forceDispose: true`) on all pooled controllers.

---

## Legacy Lists: `BetterPlayerListVideoPlayer` (Deprecated)

> [!WARNING]
> `BetterPlayerListVideoPlayer` and `BetterPlayerListVideoPlayerController` are deprecated. They do not pool or recycle controllers. Using them in scrollable `ListView` or `GridView` builders retains native controller textures via `AutomaticKeepAliveClientMixin`, exhausting hardware decoders and leading to Out-of-Memory crashes. Migrate to `BetterPlayerFeed` for swipe feeds or `BetterPlayerPool` for custom list recycling.

If you have 1 or 2 static video cards in a short layout without scroll recycling, use standard `BetterPlayer` with `playerVisibilityChangedBehavior`:

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
