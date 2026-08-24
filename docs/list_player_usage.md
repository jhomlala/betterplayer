---
id: list_player_usage
title: List Player Usage
---

# Video Playback in Lists

The `BetterPlayerListVideoPlayer` is a specialized component designed for seamless video integration within scrollable lists. It provides automatic playback management based on the visibility of the video on the screen.

## Automatic Playback with `playFraction`

The `BetterPlayerListVideoPlayer` automatically toggles between play and pause states based on its visibility threshold, defined by the `playFraction` parameter. 

The `playFraction` value (ranging from 0.0 to 1.0) represents the percentage of the video height that must be visible within the viewport to trigger playback. For example, a `playFraction` of `0.8` requires 80% of the video to be visible before it starts playing.

### Basic Implementation

```dart
@override
Widget build(BuildContext context) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: BetterPlayerListVideoPlayer(
      BetterPlayerDataSource(
          BetterPlayerDataSourceType.network, videoListData.videoUrl),
      key: Key(videoListData.hashCode.toString()),
      playFraction: 0.8,
    ),
  );
}
```

## Advanced List Management

For more granular control, you can utilize the `BetterPlayerListViewPlayerController`. Refer to the [Example App](https://github.com/jhomlala/betterplayer/tree/master/example) for a comprehensive demonstration.

### Performance Optimization: Controller Recycling

While the standard `BetterPlayerListVideoPlayer` is suitable for shorter lists, we recommend implementing a **recycling** or **reusable** strategy for long lists.

Creating multiple instances of `BetterPlayerController` is resource-intensive. On devices with limited hardware specifications, creating more than 2-3 instances simultaneously can lead to performance degradation or Out-of-Memory (OOM) errors.

#### Recommendation:
Implement a pattern where a small pool of `BetterPlayerController` instances (e.g., 2-3) is reused across list items as they scroll into view.

*   **Reusable Video List Example**: [View Code](https://github.com/jhomlala/betterplayer/tree/master/example/lib/pages/reusable_video_list)
*   **Buffer Tuning**: If you encounter random OOM issues, consider reducing the values within the `bufferingConfiguration` of your `BetterPlayerDataSource`.
