part of '../better_player_controller.dart';

extension PlayerCacheExtension on BetterPlayerController {
  ///Clear all cached data. Video player controller must be initialized to
  ///clear the cache.
  Future<void> clearCache() async {
    return PlayerEngineController.clearCache();
  }

  /// Broadcast stream of pre-cache progress events across active downloads.
  Stream<PreCacheProgress> get preCacheProgressStream =>
      PlayerEngineController.preCacheProgressStream;

  ///PreCache a video. On Android, the future succeeds when
  ///the requested size, specified in
  ///[CacheConfiguration.preCacheSize], is downloaded or when the
  ///complete file is downloaded if the file is smaller than the requested size.
  ///On iOS, the whole file will be downloaded, since [maxCacheFileSize] is
  ///currently not supported on iOS. On iOS, the video format must be in this
  ///list: https://github.com/sendyhalim/Swime/blob/master/Sources/MimeType.swift
  ///
  ///Optional [onProgress] callback to receive progress updates for this video.
  Future<void> preCache(
    PlayerDataSource betterPlayerDataSource, {
    void Function(PreCacheProgress progress)? onProgress,
  }) async {
    final url = betterPlayerDataSource.url.toLowerCase();
    final videoExtension =
        betterPlayerDataSource.videoExtension?.toLowerCase() ?? '';
    if (url.contains('.m3u8') ||
        url.contains('.m3u') ||
        videoExtension == 'm3u8' ||
        videoExtension == 'm3u') {
      PlayerLogger.warning(
        message: 'Pre-caching HLS streams is not supported.',
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

    StreamSubscription<PreCacheProgress>? progressSubscription;
    if (onProgress != null) {
      progressSubscription = PlayerEngineController.preCacheProgressStream
          .listen((event) {
            final matchesUrl = event.url == betterPlayerDataSource.url;
            final matchesKey =
                cacheConfig.key != null &&
                cacheConfig.key!.isNotEmpty &&
                event.cacheKey == cacheConfig.key;
            if (matchesUrl || matchesKey) {
              onProgress(event);
            }
          });
    }

    try {
      await PlayerEngineController.preCache(
        dataSource,
        cacheConfig.preCacheSize,
        onProgress: onProgress,
      );
    } finally {
      await progressSubscription?.cancel();
    }
  }

  ///Stop pre cache for given [betterPlayerDataSource]. If there was no pre
  ///cache started for given [betterPlayerDataSource] then it will be ignored.
  Future<void> stopPreCache(PlayerDataSource betterPlayerDataSource) async {
    return PlayerEngineController.stopPreCache(
      betterPlayerDataSource.url,
      betterPlayerDataSource.cacheConfiguration?.key,
    );
  }
}
