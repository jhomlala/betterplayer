///Cache configuration for Better Player.
///To enable cache, useCache must be true. On iOS maxCacheFileSize and preCacheSize take no effect,
///so useCache is used only.
class BetterPlayerCacheConfiguration {
  ///Enable cache for network data source
  final bool useCache;

  /// The maximum cache size to keep on disk in bytes. This value is used only
  /// when first video access. cache. This value is used for all players within
  /// your app. It can't be changed during app work.
  final int maxCacheSize;

  /// The maximum size of each individual file in bytes.
  /// Android only option.
  final int maxCacheFileSize;

  /// The size to download.
  /// Android only option.
  final int preCacheSize;

  ///Cache key to re-use same cached data between app sessions.
  final String? key;

  const BetterPlayerCacheConfiguration(
      {this.useCache = false,
      this.maxCacheSize = 10 * 1024 * 1024,
      this.maxCacheFileSize = 10 * 1024 * 1024,
      this.preCacheSize = 3 * 1024 * 1024,
      this.key});
}
