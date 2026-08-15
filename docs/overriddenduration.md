# Overridden Duration

The `overriddenDuration` parameter allows you to define a custom end point for video playback. This is particularly useful for scenarios where you want to present only a specific segment of a longer video.

## Implementation Example

```dart
BetterPlayerDataSource dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    Constants.elephantDreamVideoUrl,
    /// Play only the first 10 seconds of this video.
    overriddenDuration: const Duration(seconds: 10),
);
```
