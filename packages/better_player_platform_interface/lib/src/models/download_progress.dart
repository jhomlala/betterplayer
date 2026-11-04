import 'package:better_player_platform_interface/src/models/download_state.dart';
import 'package:meta/meta.dart';

/// Represents the state and the progress of one media download.
///
/// The values come from the download engine. [totalBytes] is `0` while the
/// engine does not know the size of the media, which is the normal case for
/// DASH until the download finishes.
@immutable
@immutable
class DownloadProgress {
  const DownloadProgress({
    required this.url,
    required this.state,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.error,
  });

  /// The URL of the media being downloaded.
  final String url;

  /// The lifecycle state of the download.
  final DownloadState state;

  /// Number of bytes stored so far.
  final int bytesDownloaded;

  /// Total number of bytes expected, or `0` when the size is unknown.
  final int totalBytes;

  /// Error message when [state] is [DownloadState.failed], `null` otherwise.
  final String? error;

  /// Whether the engine knows the total size of the media.
  bool get hasTotalBytes => totalBytes > 0;

  /// The progress as a fraction between 0.0 and 1.0.
  ///
  /// Returns `0.0` when [hasTotalBytes] is false, because a fraction of an
  /// unknown total does not mean anything. The caller shows
  /// [bytesDownloaded] instead.
  double get fraction {
    if (!hasTotalBytes) {
      return 0;
    }
    final value = bytesDownloaded / totalBytes;
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  /// The progress as a percentage between 0.0 and 100.0.
  double get percent => fraction * 100;

  /// Whether the download is still queued or running.
  bool get isActive =>
      state == DownloadState.queued || state == DownloadState.downloading;

  /// Whether the media is stored and plays without network access.
  bool get isCompleted => state == DownloadState.completed;

  /// Whether the download stopped because of an error.
  bool get hasError => state == DownloadState.failed || error != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadProgress &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          state == other.state &&
          bytesDownloaded == other.bytesDownloaded &&
          totalBytes == other.totalBytes &&
          error == other.error;

  @override
  int get hashCode =>
      Object.hash(url, state, bytesDownloaded, totalBytes, error);

  @override
  String toString() =>
      'DownloadProgress(url: $url, state: $state, '
      'bytesDownloaded: $bytesDownloaded, totalBytes: $totalBytes, '
      'error: $error)';
}
