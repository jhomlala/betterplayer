## Cache configuration
Define cache configuration with `BetterPlayerCacheConfiguration` for given data source. Cache works only for network data sources.

`BetterPlayerCacheConfiguration` should be used in `BetterPlayerDataSource`:

```dart
BetterPlayerDataSource _betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
      cacheConfiguration: BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,
        maxCacheSize: 10 * 1024 * 1024,
        maxCacheFileSize: 10 * 1024 * 1024,

        ///Android only option to use cached video between app sessions
        key: "testCacheKey",
      ),
    );
```

```dart
///Enable cache for network data source
final bool useCache;

/// The maximum cache size to keep on disk in bytes.
/// Android only option.
final int maxCacheSize;

/// The maximum size of each individual file in bytes.
/// Android only option.
final int maxCacheFileSize;

///Cache key to re-use same cached data between app sessions.
final String? key;
```

Clear all cached data:
```dart
betterPlayerController.clearCache();
```

Start pre cache before playing video (android only):
```dart
betterPlayerController.preCache(_betterPlayerDataSource);
```

Stop running pre cache (android only):
```dart
betterPlayerController.stopPreCache(_betterPlayerDataSource);
```
