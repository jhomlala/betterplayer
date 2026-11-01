import 'package:better_player_downloader/src/downloader_core.dart';
import 'package:better_player_downloader/src/models/download_state.dart';
import 'package:flutter/services.dart';

export 'package:better_player_downloader/src/downloader_core.dart';
export 'package:better_player_downloader/src/models/download_state.dart';

class BetterPlayerDownloader {
  static const MethodChannel _channel = MethodChannel(
    'better_player_downloader',
  );

  static Future<DownloadResult> startDownload(DownloadRequest req) async {
    final validated = validateRequest(req);
    if (validated is DownloadErr) return validated;
    final requiresNative = validated is DownloadRequiresNativeService;
    try {
      await _channel.invokeMethod<bool>(
        requiresNative ? 'startDownloadNative' : 'startDownload',
        {'id': idOf(req), 'url': req.url},
      );
    } on MissingPluginException {
      return DownloadRequiresNativeService(req.url);
    } on PlatformException catch (error) {
      return DownloadErr(error.message ?? error.code);
    }
    return DownloadOk(
      DownloadInfo(
        url: req.url,
        bytesDownloaded: 0,
        totalBytes: 0,
        state: DownloadState.inProgress,
      ),
    );
  }

  static Future<DownloadProgress?> downloadProgress(DownloadRequest req) async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'downloadProgress',
        {'id': idOf(req)},
      );
      return map == null ? null : DownloadProgress.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> deleteDownload(DownloadRequest req) async {
    try {
      final deleted = await _channel.invokeMethod<bool>('deleteDownload', {
        'id': idOf(req),
      });
      return deleted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static String idOf(DownloadRequest req) =>
      'bp_${req.url.hashCode.toUnsigned(32).toRadixString(16)}';
}
