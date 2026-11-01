enum DownloadState { notStarted, inProgress, completed, failed }

class DownloadRequest {
  const DownloadRequest({required this.url, this.drmUrl, this.key});
  final String url;
  final String? drmUrl;
  final String? key;
}

class DownloadInfo {
  const DownloadInfo({
    required this.url,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.state,
  });
  final String url;
  final int bytesDownloaded;
  final int totalBytes;
  final DownloadState state;
}

class DownloadProgress {
  const DownloadProgress({
    required this.state,
    required this.percent,
    required this.bytesDownloaded,
    required this.totalBytes,
  });
  final DownloadState state;
  final int percent;
  final int bytesDownloaded;
  final int totalBytes;

  factory DownloadProgress.fromMap(Map<Object?, Object?> map) {
    final raw = map['state']?.toString() ?? '';
    return DownloadProgress(
      state: DownloadState.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => DownloadState.notStarted,
      ),
      percent: (map['percent'] as num?)?.toInt() ?? 0,
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

sealed class DownloadResult {}

class DownloadOk implements DownloadResult {
  const DownloadOk(this.info);
  final DownloadInfo info;
}

class DownloadRequiresNativeService implements DownloadResult {
  const DownloadRequiresNativeService(this.url);
  final String url;
}

class DownloadErr implements DownloadResult {
  const DownloadErr(this.message);
  final String message;
}
