/// Represents the progress of an ongoing pre-cache operation.
class PreCacheProgress {
  const PreCacheProgress({
    required this.url,
    required this.progress,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.cacheKey,
    this.error,
  });

  /// The URL of the media being pre-cached.
  final String url;

  /// Optional cache key associated with the media.
  final String? cacheKey;

  /// Progress fraction between 0.0 and 1.0 (or negative on error/unknown).
  final double progress;

  /// Number of bytes downloaded so far.
  final int bytesDownloaded;

  /// Total number of bytes expected to be downloaded (-1 if unknown).
  final int totalBytes;

  /// Optional error message when pre-caching fails.
  final String? error;

  /// The progress as a percentage between 0.0 and 100.0.
  double get percent => progress >= 0 ? progress * 100 : 0.0;

  /// Whether the pre-cache operation has completed successfully.
  bool get isCompleted => progress >= 1.0 && error == null;

  /// Whether the pre-cache operation encountered an error.
  bool get hasError => error != null || progress < -1.5;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreCacheProgress &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          cacheKey == other.cacheKey &&
          progress == other.progress &&
          bytesDownloaded == other.bytesDownloaded &&
          totalBytes == other.totalBytes &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
    url,
    cacheKey,
    progress,
    bytesDownloaded,
    totalBytes,
    error,
  );

  @override
  String toString() =>
      'PreCacheProgress(url: $url, cacheKey: $cacheKey, progress: $progress, '
      'bytesDownloaded: $bytesDownloaded, totalBytes: $totalBytes, error: $error)';
}
