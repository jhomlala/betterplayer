class BetterPlayerCacheConfiguration {
  ///Enable cache for network data source
  final bool useCache;

  /// The maximum cache size to keep on disk in bytes.
  final int maxCacheSize;

  /// The maximum size of each individual file in bytes.
  final int maxCacheFileSize;

  const BetterPlayerCacheConfiguration({
    this.useCache = true,
    this.maxCacheSize = 10 * 1024 * 1024,
    this.maxCacheFileSize = 10 * 1024 * 1024,
  });
}
