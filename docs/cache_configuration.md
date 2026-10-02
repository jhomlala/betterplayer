---
id: cache_configuration
title: Cache Configuration
---

# Cache Configuration

Better Player provides a powerful caching system for network-based data sources to improve playback performance and reduce bandwidth usage. Caching is configured using the `CacheConfiguration` class within the `PlayerDataSource`.

## Basic Configuration

```dart
PlayerDataSource _betterPlayerDataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
      cacheConfiguration: CacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,
        maxCacheSize: 10 * 1024 * 1024,
        maxCacheFileSize: 10 * 1024 * 1024,
        /// Key to persist cache between application sessions
        key: "uniqueCacheKey",
      ),
    );
```

## Configuration Parameters

*   **`useCache`**: Enables or disables caching for the data source.
*   **`maxCacheSize`**: (Android only) The maximum total size of the cache on disk in bytes.
*   **`maxCacheFileSize`**: (Android only) The maximum size allowed for an individual cached file in bytes.
*   **`key`**: A unique identifier used to persist and reuse cached data across application sessions on Android, iOS, and macOS.

:::important
Provide a unique `key` per video (especially in lists) so cached segments are persisted across sessions and never collide between different data sources.
:::
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

The underlying implementation varies by platform. Android uses ExoPlayer's internal caching mechanism. On iOS and macOS, [CachingPlayerItem](https://github.com/neekeetab/CachingPlayerItem) and local cache storage manage media caching. On the Web, fine-grained caching control (`preCache`, `clearCache`) is not currently supported natively by the Shaka Player wrapper.

| Feature | Android HLS | Android non-HLS | Apple (iOS/macOS) HLS | Apple (iOS/macOS) non-HLS | Web |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Normal Caching** | ✓ | ✓ | ✓ | ✓ | x |
| **Pre-Caching** | ✓ | ✓ | x | ✓ | x |
| **Stop Caching** | ✓ | ✓ | x | ✓ | x |
