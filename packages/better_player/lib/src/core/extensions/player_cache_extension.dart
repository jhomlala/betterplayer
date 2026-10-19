part of '../better_player_controller.dart';

extension PlayerCacheExtension on BetterPlayerController {
  ///Clear all cached data. Video player controller must be initialized to
  ///clear the cache.
  Future<void> clearCache() async {
    for (final subscription in _preCacheSubscriptions.values) {
      await subscription.cancel();
    }
    _preCacheSubscriptions.clear();
    return PlayerEngineController.clearCache();
  }

  /// Broadcast stream of pre-cache progress events across active downloads.
  Stream<PreCacheProgress> get preCacheProgressStream =>
      PlayerEngineController.preCacheProgressStream;

  /// Pre-cache a video before playback begins.
  ///
  /// - On Android, the operation downloads up to [CacheConfiguration.preCacheSize]
  ///   bytes (or the complete file if smaller).
  /// - On iOS and macOS, the full file is downloaded. The video format must be
  ///   supported by Swime (e.g. MP4, MOV).
  /// - On Windows and Web, pre-caching is not supported.
  /// - Pre-caching chunked streaming protocols (HLS and DASH) is not supported.
  ///
  /// Optional [onProgress] callback to receive progress updates for this video.
  Future<void> preCache(
    PlayerDataSource betterPlayerDataSource, {
    void Function(PreCacheProgress progress)? onProgress,
  }) async {
    final url = betterPlayerDataSource.url.toLowerCase();
    final videoExtension =
        betterPlayerDataSource.videoExtension?.toLowerCase() ?? '';
    if (url.contains('.m3u8') ||
        url.contains('.m3u') ||
        url.contains('.mpd') ||
        videoExtension == 'm3u8' ||
        videoExtension == 'm3u' ||
        videoExtension == 'mpd') {
      PlayerLogger.warning(
        message: 'Pre-caching HLS and DASH streams is not supported.',
      );
      return;
    }

    final cacheConfig =
        betterPlayerDataSource.cacheConfiguration ??
        const CacheConfiguration(useCache: true);

    final dataSource = DataSource(
      sourceType: DataSourceType.network,
      uri: betterPlayerDataSource.url,
      headers: betterPlayerDataSource.headers,
      cacheConfiguration: CacheConfiguration(
        useCache: true,
        maxCacheSize: cacheConfig.maxCacheSize,
        maxCacheFileSize: cacheConfig.maxCacheFileSize,
        key: cacheConfig.key,
      ),
      videoExtension: betterPlayerDataSource.videoExtension,
    );

    final key = cacheConfig.key;
    final trackingKey = (key != null && key.isNotEmpty)
        ? key
        : betterPlayerDataSource.url;
    await _preCacheSubscriptions.remove(trackingKey)?.cancel();

    if (onProgress != null) {
      late final StreamSubscription<PreCacheProgress> subscription;
      subscription = PlayerEngineController.preCacheProgressStream.listen(
        (event) {
          final matchesUrl = event.url == betterPlayerDataSource.url;
          final matchesKey =
              cacheConfig.key != null &&
              cacheConfig.key!.isNotEmpty &&
              event.cacheKey == cacheConfig.key;
          if (matchesUrl || matchesKey) {
            onProgress(event);
            if (event.isCompleted || event.hasError) {
              unawaited(subscription.cancel());
              _preCacheSubscriptions.remove(trackingKey);
            }
          }
        },
      );
      _preCacheSubscriptions[trackingKey] = subscription;
    }

    try {
      await PlayerEngineController.preCache(
        dataSource,
        cacheConfig.preCacheSize,
        onProgress: onProgress,
      );
    } catch (error) {
      await _preCacheSubscriptions.remove(trackingKey)?.cancel();
      rethrow;
    }
  }

  static final Map<String, StreamSubscription<PreCacheProgress>>
  _preCacheSubscriptions = {};

  ///Stop pre cache for given [betterPlayerDataSource]. If there was no pre
  ///cache started for given [betterPlayerDataSource] then it will be ignored.
  Future<void> stopPreCache(PlayerDataSource betterPlayerDataSource) async {
    final key = betterPlayerDataSource.cacheConfiguration?.key;
    final trackingKey = (key != null && key.isNotEmpty)
        ? key
        : betterPlayerDataSource.url;
    await _preCacheSubscriptions.remove(trackingKey)?.cancel();
    return PlayerEngineController.stopPreCache(
      betterPlayerDataSource.url,
      betterPlayerDataSource.cacheConfiguration?.key,
    );
  }
}
