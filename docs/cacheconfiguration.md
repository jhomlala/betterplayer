# Cache Configuration

Better Player provides a powerful caching system for network-based data sources to improve playback performance and reduce bandwidth usage. Caching is configured using the `BetterPlayerCacheConfiguration` class within the `BetterPlayerDataSource`.

## Basic Configuration

```dart
BetterPlayerDataSource _betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
      cacheConfiguration: BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,
        maxCacheSize: 10 * 1024 * 1024,
        maxCacheFileSize: 10 * 1024 * 1024,
        /// (Android only) Key to persist cache between application sessions
        key: "uniqueCacheKey",
      ),
    );
```

## Configuration Parameters

*   **`useCache`**: Enables or disables caching for the data source.
*   **`maxCacheSize`**: (Android only) The maximum total size of the cache on disk in bytes.
*   **`maxCacheFileSize`**: (Android only) The maximum size allowed for an individual cached file in bytes.
*   **`key`**: A unique identifier used to persist and reuse cached data across application sessions.

## Cache Management

### Clear All Cache
To remove all cached data from the device:
```dart
betterPlayerController.clearCache();
```

### Pre-Caching
You can start downloading a video into the cache before playback begins:
```dart
betterPlayerController.preCache(_betterPlayerDataSource);
```

### Stop Pre-Caching
To cancel an ongoing pre-caching operation:
```dart
betterPlayerController.stopPreCache(_betterPlayerDataSource);
```

## Platform Support

The underlying implementation varies by platform. Android uses ExoPlayer's internal caching mechanism. On iOS, [HLSCachingReverseProxyServer](https://github.com/StyleShare/HLSCachingReverseProxyServer) is used for HLS streams, and [CachingPlayerItem](https://github.com/neekeetab/CachingPlayerItem) is used for other formats.

| Feature | Android HLS | Android non-HLS | iOS HLS | iOS non-HLS |
| :--- | :---: | :---: | :---: | :---: |
| **Normal Caching** | ✓ | ✓ | ✓ | ✓ |
| **Pre-Caching** | ✓ | ✓ | x | ✓ |
| **Stop Caching** | ✓ | ✓ | x | ✓ |
