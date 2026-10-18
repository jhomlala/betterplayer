/// Represents the progress of an ongoing pre-cache operation.
class PreCacheProgress {
  const PreCacheProgress({
    required this.url,
    required this.progress,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.cacheKey,
  });

  /// The URL of the media being pre-cached.
  final String url;

  /// Optional cache key associated with the media.
  final String? cacheKey;

  /// Progress fraction between 0.0 and 1.0.
  final double progress;

  /// Number of bytes downloaded so far.
  final int bytesDownloaded;

  /// Total number of bytes expected to be downloaded.
  final int totalBytes;

  /// The progress as a percentage between 0.0 and 100.0.
  double get percent => progress * 100;

  /// Whether the pre-cache operation has completed.
  bool get isCompleted => progress >= 1.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreCacheProgress &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          cacheKey == other.cacheKey &&
          progress == other.progress &&
          bytesDownloaded == other.bytesDownloaded &&
          totalBytes == other.totalBytes;

  @override
  int get hashCode => Object.hash(
    url,
    cacheKey,
    progress,
    bytesDownloaded,
    totalBytes,
  );

  @override
  String toString() =>
      'PreCacheProgress(url: $url, cacheKey: $cacheKey, progress: $progress, '
      'bytesDownloaded: $bytesDownloaded, totalBytes: $totalBytes)';
}
