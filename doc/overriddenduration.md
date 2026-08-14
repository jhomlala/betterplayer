## Overridden duration
If `overriddenDuration` is set then video player will play video until this duration. This feature can be used to cut long videos into smaller one.

```dart
BetterPlayerDataSource dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    Constants.elephantDreamVideoUrl,
    ///Play only 10 seconds of this video.
    overriddenDuration: const Duration(seconds: 10),
);
```