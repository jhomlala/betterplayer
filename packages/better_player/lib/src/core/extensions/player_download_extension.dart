part of '../better_player_controller.dart';

extension PlayerDownloadExtension on BetterPlayerController {
  /// Broadcast stream of the state of the media downloads.
  Stream<DownloadProgress> get downloadProgressStream =>
      PlayerEngineController.downloadProgressStream;

  /// Sets [callback] as the receiver of the download state changes.
  ///
  /// Pass `null` to stop the calls. [downloadProgressStream] keeps its
  /// subscribers.
  void setDownloadCallback(BetterPlayerDownloadCallback? callback) =>
      PlayerEngineController.setDownloadCallback(callback);

  /// Starts an offline download of [betterPlayerDataSource].
  ///
  /// The download stores one video track, so the size stays usable. Use
  /// [maxVideoHeight] to limit the resolution. The highest resolution that the
  /// device supports is the default.
  ///
  /// Only network sources are supported.
  Future<void> startDownload(
    PlayerDataSource betterPlayerDataSource, {
    int? maxVideoHeight,
  }) async {
    final url = betterPlayerDataSource.url;
    if (url.isEmpty) {
      PlayerLogger.warning(
        message: 'A download needs a network URL.',
      );
      return;
    }
    await PlayerEngineController.startDownload(
      DataSource(
        sourceType: DataSourceType.network,
        uri: url,
        headers: betterPlayerDataSource.headers,
      ),
      maxVideoHeight: maxVideoHeight,
    );
  }

  /// Stops the download of [url] and keeps the downloaded data.
  Future<void> stopDownload(String url) =>
      PlayerEngineController.stopDownload(url);

  /// Deletes the download of [url] and its stored data.
  Future<void> deleteDownload(String url) =>
      PlayerEngineController.deleteDownload(url);
}
